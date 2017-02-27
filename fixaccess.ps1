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
[Alphaleonis.Win32.Filesystem.Directory]::EnumerateFileSystemEntries($folderPath, '*') | Foreach-Object {
  Try {
    $fsei = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_")
    $directories += $fsei
  } Catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Warning "$FailedItem : $ErrorMessage"
    return
  }
  if ($fsei.LastAccessTime -ne $fsei.CreationTime) {
    if ($doit) {
      [Alphaleonis.Win32.Filesystem.Directory]::SetLastAccessTime($fsei.FullPath,$fsei.CreationTime)
      "CHANGE $isdir $($fsei.FullPath) $($fsei.CreationTime) $($fsei.LastAccessTime) -> $($fsei.CreationTime)"
      $changes = $true
    } else {
      "NOCHANGE $isdir $($fsei.FullPath) $($fsei.CreationTime) $($fsei.LastAccessTime) -> $($fsei.CreationTime)"
    }
  }
} # | Tee-Object -filepath out$loop.txt #debug loop operations
$loop++
} Until ($changes -eq $false)
"Completed on loop $($loop - 1)"
