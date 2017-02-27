param ( 
  [string]$path,
  [switch]$doit = $false,
  [string]$exclude = "",
  [datetime]$firstwrite = [datetime]'1/1/1970',
  [datetime]$lastwrite = [System.DateTime]::Now
)

if(-not($path)) { Throw "You must supply a value for -path" }
if ($exclude -eq "") {
  $doExclude = $false
} else {
  $doExlude = $false
  $excludes = @()
  $exclude.split(",") | foreach {
    "EXCLUDE $_ $(Resolve-Path -Path $_)"
    $excludes += ,$(Resolve-Path -Path $_)
  }
}

$libPath = Resolve-Path -Path "$PSScriptRoot\alpha\Lib\Net40\AlphaFS.dll"
Import-Module -Name $libPath
$folderPath = Resolve-Path -Path "$path"

$loop = 1
Do {
$changes = $false
$directories = @()
[Alphaleonis.Win32.Filesystem.Directory]::EnumerateFileSystemEntries($folderPath, '*', [System.IO.SearchOption]::AllDirectories) | Foreach-Object {
  Try {
    $fsei = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_")
    $directories += $fsei
  } Catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Warning "$FailedItem : $ErrorMessage"
    return
  }
}
$sorted_directories = $directories #| Sort-Object -Descending -Property @{Expression={[int]([regex]::Matches($_.FullPath, "\\" )).count}}
$sorted_directories | Foreach-Object {
  $fsei = $_
  if ($fsei.LastAccessTime -gt $firstwrite -AND $fsei.LastAccessTime -lt $lastwrite) {
    $create = $fsei.CreationTime
    $mod = $fsei.LastWriteTime
    $access = $fsei.LastAccessTime
    $fn = $fsei.FullPath
    $isdir = $fsei.IsDirectory
    If ($isdir) {
      $excluded = $false
      if ($doExlcude) {
        $excludes | foreach {
          if ($fn.startswith($_)) {
            $excluded = $true
	        return
          }
        }
      }
      if ($excluded) {
        "$fn is in the exclusion list"
      } else {
        if ($access -ne $create) {
          if ($doit) {
            [Alphaleonis.Win32.Filesystem.Directory]::SetLastAccessTime("$fn",$create)
            "CHANGE $isdir $fn $create $access $mod -> $create"
            $changes = $true
          } else {
            "NOCHANGE $isdir $fn $create $access $mod -> $create"
          }
        }
      }
    }
  }
} # | Tee-Object -filepath out$loop.txt #debug loop operations
$loop++
} Until ($changes -eq $false)
"Completed on loop $($loop - 1)"
