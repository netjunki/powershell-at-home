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
Function Invoke-GenericMethod {
    Param(
        $Instance,
        [String]$MethodName,
        [Type[]]$TypeParameters,
        [Object[]]$MethodParameters
    )

    [Collections.ArrayList]$Private:parameterTypes = @{}
    ForEach ($Private:paramType In $MethodParameters) { [Void]$parameterTypes.Add($paramType.GetType()) }

    $Private:method = $Instance.GetMethod($methodName, "Instance,Static,Public", $Null, $parameterTypes, $Null)

    If ($Null -eq $method) { Throw ('Method: [{0}] not found.' -f ($Instance.ToString() + '.' + $methodName)) }
    Else {
        $method = $method.MakeGenericMethod($TypeParameters)
        $method.Invoke($Instance, $MethodParameters)
    }
}

$loop = 1
Do {
$changes = $false
$directories = @()
$Id = 1
$indicator = @(".","o","O","o")
ForEach ($Private:fsei In (Invoke-GenericMethod `
    -Instance           ([Alphaleonis.Win32.Filesystem.Directory]) `
    -MethodName         EnumerateFileSystemEntryInfos `
    -TypeParameters     Alphaleonis.Win32.Filesystem.FileSystemEntryInfo `
    -MethodParameters   "$folderPath", '*',
                        ([Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]'Folders, SkipReparsePoints, Recursive, ContinueOnException'),
                        ([Alphaleonis.Win32.Filesystem.PathFormat]::FullPath))) {
    $directories += $fsei
    Write-Progress -Activity "Finding directories..." `
		         -CurrentOperation "$($indicator[$Id % 4])"
    $Id += 1
}
$directories += [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo($folderPath)
$sorted_directories = $directories | Sort-Object -Descending -Property @{Expression={[int]([regex]::Matches($_.FullPath, "\\" )).count}}
$Id = 1
$indicator = @("-","/","|","\")
$sorted_directories | Foreach-Object {
  Write-Progress -Activity "Processing directories..." `
		         -CurrentOperation "$($indicator[$Id % 4])"
  $Id += 1
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
	$newcre = $null
        $newest_file = $null
        $newest_folder = $null
        $oldest_file = $null
        $oldest_folder = $null
        $nfi = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($fn)
	if ($nfi -ne $null) {
	  $sorted_create_nfi = $nfi | Sort-Object -Property @{Expression={[Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_").CreationTime}}
	  $sorted_modified_nfi = $nfi | Sort-Object -Property @{Expression={[Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_").LastWriteTime}}
	  $oldest_c_file = $sorted_create_nfi | Select-Object -first 1
	  $newest_c_file = $sorted_create_nfi | Select-Object -last 1
	  $oldest_m_file = $sorted_modified_nfi | Select-Object -first 1
	  $newest_m_file = $sorted_modified_nfi | Select-Object -last 1
          Try {
            $oldest_file = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$oldest_c_file")
          } Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Warning "$FailedItem : $ErrorMessage"
            return
          }
	  if ($newest_m_file -eq $newest_c_file) {
            Try {
              $newest_file = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$newest_c_file")
            } Catch {
              $ErrorMessage = $_.Exception.Message
              $FailedItem = $_.Exception.ItemName
              Write-Warning "$FailedItem : $ErrorMessage"
              return
            }
	  } else {
            Try {
              $newest_file = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$newest_m_file")
            } Catch {
              $ErrorMessage = $_.Exception.Message
              $FailedItem = $_.Exception.ItemName
              Write-Warning "$FailedItem : $ErrorMessage"
              return
            }
	  }
	}
        $nfo = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateDirectories($fn)
	if ($nfo -ne $null) {
	  $sorted_create_nfo = $nfo | Sort-Object -Property @{Expression={[Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_").CreationTime}}
	  $sorted_modified_nfo = $nfo | Sort-Object -Property @{Expression={[Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_").LastWriteTime}}
	  $oldest_c_folder = $sorted_create_nfo | Select-Object -first 1
	  $newest_c_folder = $sorted_create_nfo | Select-Object -last 1
	  $oldest_m_folder = $sorted_modified_nfo | Select-Object -first 1
	  $newest_m_folder = $sorted_modified_nfo | Select-Object -last 1
          Try {
            $oldest_folder = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$oldest_c_folder")
          } Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Warning "$FailedItem : $ErrorMessage"
            return
          }
	  if ($newest_m_folder -eq $newest_c_folder) {
            Try {
              $newest_folder = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$newest_c_folder")
            } Catch {
              $ErrorMessage = $_.Exception.Message
              $FailedItem = $_.Exception.ItemName
              Write-Warning "$FailedItem : $ErrorMessage"
              return
            }
	  } else {
            Try {
              $newest_folder = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$newest_m_folder")
            } Catch {
              $ErrorMessage = $_.Exception.Message
              $FailedItem = $_.Exception.ItemName
              Write-Warning "$FailedItem : $ErrorMessage"
              return
            }
	  }
	}
        if ($newest_file -ne $null -And $newest_folder -ne $null) {
          if ($newest_file.LastWriteTime -gt $newest_folder.LastWriteTime) {
	    $newest_filemod = $newest_file.LastWriteTime
            "MA $fn $create $mod $access mod date should be file $newest_filemod"
	    $newmod = $newest_filemod
	  } elseif ($newest_file.LastWriteTime -lt $newest_folder.LastWriteTime) {
	    $newest_filemod = $newest_folder.LastWriteTime
            "MA2 $fn $create $mod $access mod date should be file $newest_filemod"
	    $newmod = $newest_filemod
          } else {
	    $newest_foldercre = $newest_folder.CreationTime
            "MB $fn $create $mod $access mod date should be folder $newest_foldercre"
	    $newmod = $newest_foldercre
          }
        } elseif ($newest_file -ne $null) {
          $newest_filemod = $newest_file.LastWriteTime
          "MC $fn $create $mod $access mod date should be file $newest_filemod"
          $newmod = $newest_filemod
        } elseif ($newest_folder -ne $null) {
          $newest_foldercre = $newest_folder.CreationTime
          "MD $fn $create $mod $access mod date should be folder $newest_foldercre"
          $newmod = $newest_foldercre
        } else {
          "ME $fn $create $mod $access has no children using create date for everything"
	  $newmod = $create
        }

        if ($oldest_file -ne $null -And $oldest_folder -ne $null) {
          if ($oldest_file.CreationTime -lt $oldest_folder.CreationTime) {
	        $oldest_filecre = $oldest_file.CreationTime
                "CA $fn $create $mod $access create date should be file $oldest_filecre"
	        $newcre = $oldest_filecre
          } else {
	        $oldest_foldercre = $oldest_folder.CreationTime
                "CB $fn $create $mod $access create date should be folder $oldest_foldercre"
	        $newcre = $oldest_foldercre
          }
        } elseif ($oldest_file -ne $null) {
          $oldest_filecre = $oldest_file.CreationTime
          "CC $fn $create $mod $access create date should be file $oldest_filecre"
          $newcre = $oldest_filecre
        } elseif ($oldest_folder -ne $null) {
          $oldest_foldercre = $oldest_folder.CreationTime
          "CD $fn $create $mod $access create date should be folder $oldest_foldercre ($oldest_folder)"
          $newcre = $oldest_foldercre
        } else {
          "CE $fn $create $mod $access has no children using create date for everything"
	  $newcre = $create
        }

	Try {
        if ($mod -ne $newmod) {
          if ($doit) {
            [Alphaleonis.Win32.Filesystem.Directory]::SetLastWriteTime("$fn",$newmod)
            "MODCHANGE $isdir $fn $fn $create $access $mod -> $newmod"
            $changes = $true
          } else {
            "MODNOCHANGE $isdir $fn $fn $create $access $mod -> $newmod"
          }
        }

        if ($create -ne $newcre) {
          if ($doit) {
            [Alphaleonis.Win32.Filesystem.Directory]::SetCreationTime("$fn",$newcre)
            "CRECHANGE $isdir $fn $fn $create $access $mod -> $newcre"
            $changes = $true
          } else {
            "CRENOCHANGE $isdir $fn $fn $create $access $mod -> $newcre"
          }
        }

        if ($access -ne $newcre) {
          if ($doit) {
            [Alphaleonis.Win32.Filesystem.Directory]::SetLastAccessTime("$fn",$newcre)
            "ACCCHANGE $isdir $fn $fn $create $access $mod -> $newcre"
            $changes = $true
          } else {
            "ACCNOCHANGE $isdir $fn $fn $create $access $mod -> $newcre"
          }
        }
        } Catch {
          $ErrorMessage = $_.Exception.Message
          $FailedItem = $_.Exception.ItemName
          Write-Warning "$FailedItem : $ErrorMessage"
          exit
        }
      }
    }
  }
} # | Tee-Object -filepath out$loop.txt #debug loop operations
$loop++
} Until ($changes -eq $false)
"Completed on loop $($loop - 1)"
