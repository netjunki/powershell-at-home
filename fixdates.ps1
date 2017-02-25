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
$sorted_directories = $directories | Sort-Object -Descending -Property @{Expression={[int]([regex]::Matches($_.FullPath, "\\" )).count}}
$sorted_directories | Foreach-Object {
  $fsei = $_
  if ($fsei.LastWriteTime -gt $firstwrite -AND $fsei.LastWriteTime -lt $lastwrite) {
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
        $newmod = $null
        $newest_file = $null
        $newest_folder = $null
        $nfi = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($fn) | Foreach-Object {
          Try {
            $fsei_nfi = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_")
          } Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Warning "$FailedItem : $ErrorMessage"
            return
          }
          if ($newest_file -eq $null) {
            $newest_file = $fsei_nfi
          } else {
            if ($fsei_nfi.LastWriteTime -gt $newest_file.LastWriteTime) {
              $newest_file = $fsei_nfi
            }
          }
        }
        $nfo = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateDirectories($fn) | ForEach-Object {
          Try {
            $fsei_nfo = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_")
          } Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Warning "$FailedItem : $ErrorMessage"
            return
          }
          if ($newest_folder -eq $null) {
            $newest_folder = $fsei_nfo
          } else {
            if ($fsei_nfo.LastWriteTime -gt $newest_folder.LastWriteTime) {
              $newest_folder = $fsei_nfo
            }
          }
        }

        if ($newest_file -ne $null -And $newest_folder -ne $null) {
          if ($newest_file.LastWriteTime -gt $newest_folder.LastWriteTime) {
            "$fn $create $mod $access mod date should be file $newest_filemod"
	        $newest_filemod = $newest_file.LastWriteTime
	        $newmod = $newest_filemod
          } else {
            "$fn $create $mod $access mod date should be folder $newest_foldermod"
	        $newest_foldermod = $newest_folder.LastWriteTime
	        $newmod = $newest_foldermod
          }
        } elseif ($newest_file -ne $null) {
          "$fn $create $mod $access mod date should be file $newest_filemod"
          $newest_filemod = $newest_file.LastWriteTime
          $newmod = $newest_filemod
        } elseif ($newest_folder -ne $null) {
          "$fn $create $mod $access mod date should be folder $newest_foldermod"
          $newest_foldermod = $newest_folder.LastWriteTime
          $newmod = $newest_foldermod
        } else {
          "$fn $create $mod $access  has no children not modifying"
          return
        }
        if ($mod -ne $newmod) {
          if ($doit) {
            [Alphaleonis.Win32.Filesystem.Directory]::SetLastWriteTime("$fn",$newmod)
            [Alphaleonis.Win32.Filesystem.Directory]::SetLastAccessTime("$fn",$newmod)
            "CHANGE $isdir $fn $fn $create $access $mod -> $newmod"
            $changes = $true
          } else {
            "NOCHANGE $isdir $fn $fn $create $access $mod -> $newmod"
          }
        }
      }
    }
  }
} # | Tee-Object -filepath out$loop.txt #debug loop operations
$loop++
} Until ($changes -eq $false)
"Completed on loop $($loop - 1)"