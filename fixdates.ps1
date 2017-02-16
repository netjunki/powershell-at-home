param ( 
  [string]$path,
  [switch]$doit = $false,
  [string]$exclude = "",
  [datetime]$firstwrite = [datetime]'1/1/1970',
  [datetime]$lastwrite = [System.DateTime]::Now
)

if(-not($path)) { Throw "You must supply a value for -path" }
$excludes = $exclude.split(",")

Get-ChildItem "$path" -Recurse |
Where-Object {$_.lastwritetime -gt $firstwrite -AND $_.lastwritetime -lt $lastwrite} | #Actual 2/12/2017 ~18:50 ~19:20
Foreach-Object {
  $fn = $_.FullName
  $isdir = $_ -is [System.IO.DirectoryInfo]
  $create = $_.CreationTime
  $mod = $_.LastWriteTime
  If ($_ -is [System.IO.DirectoryInfo]) {
    $excluded = $false
    $excludes | foreach {
      if ($fn.startswith($_)) {
        $excluded = $true
	return
      }
    }
    if ($excluded) {
      "$fn is in the exclusion list"
    } else {
    "$isdir $fn $create $mod"
    $newmod = $null
    $newest_file = (Get-ChildItem -file "$fn" | sort-object -property LastWriteTime | select -last 1)
    $newest_folder = (Get-ChildItem -dir "$fn" | sort-object -property LastWriteTime | select -last 1)
    if ($newest_file -ne $null -And $newest_folder -ne $null) {
      if ($newest_file.LastWriteTime -gt $newest_folder.LastWriteTime) {
        "mod date should be file $newest_filemod"
	$newest_filemod = $newest_file.LastWriteTime
	$newmod = $newest_filemod
      } else {
        "mod date should be folder $newest_foldermod"
	$newest_foldermod = $newest_folder.LastWriteTime
	$newmod = $newest_foldermod
      }
    } elseif ($newest_file -ne $null) {
      "mod date should be file $newest_filemod"
      $newest_filemod = $newest_file.LastWriteTime
      $newmod = $newest_filemod
    } elseif ($newest_folder -ne $null) {
      "mod date should be folder $newest_foldermod"
      $newest_foldermod = $newest_folder.LastWriteTime
      $newmod = $newest_foldermod
    } else {
      "has no children not modifying"
      return
    }
    if ($doit) {
      $_.LastWriteTime = $newmod
      $_.LastAccessTime = $newmod
    }
    }
  }
}

#      $newest_fn = $newest.FullName
#      $newest_isdir = $newest -is [System.IO.DirectoryInfo]
#      $newest_create = $newest.CreationTime
#      $newest_mod = $newest.LastWriteTime
#      "N: $newest_isdir $newest_fn $newest_create $newest_mod"
#      if ($newest_isdir) {
#        "mod date should be $newest_create"
#     } else {
#        "mod date should be $newest_mod"
#	if ($doit) {
#  	  $_.LastWriteTime = $newest_mod
#	  $_.LastAccessTime = $newest_mod
#	}
#      }
