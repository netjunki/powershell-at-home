param ( 
  [string]$path,
  [switch]$mismatchedDateInName = $false
)

if(-not($path)) { Throw "You must supply a value for -path" }

$libPath = Resolve-Path -Path "$PSScriptRoot\alpha\Lib\Net40\AlphaFS.dll"
Import-Module -Name $libPath
$folderPath = Resolve-Path -Path "$path"

[Alphaleonis.Win32.Filesystem.Directory]::EnumerateFileSystemEntries($folderPath, '*', [System.IO.SearchOption]::AllDirectories) |
Foreach-Object {
  Try {
    $fsei = [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo("$_")
  } Catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    "$FailedItem : $ErrorMessage"
    return
  }
  $create = $fsei.CreationTime
  $mod = $fsei.LastWriteTime
  $access = $fsei.LastAccessTime
  $fn = $fsei.FullPath
  $pathlen = $fn.length
  if($mismatchedDateInName) {
    if ($fn -match '(?<year>[0-9]{4})\.(?<month>[0-9]{2})\.(?<day>[0-9]{2})\.(?<dow>[MTWRFSU]) (?<hour>[0-9]{2})\.(?<minute>[0-9]{2})') {
       $year = $mod.ToString("yyyy")
       $month = $mod.ToString("MM")
       $day = $mod.ToString("dd")
       $hour = $mod.ToString("HH")
       $minute = $mod.ToString("mm")
       $dow = $mod.ToString("ddd")
       switch ($dow) {
         "Mon" { $dow = "M" }
         "Tue" { $dow = "T" }
         "Wed" { $dow = "W" }
         "Thu" { $dow = "R" }
         "Fri" { $dow = "F" }
         "Sat" { $dow = "S" }
         "Sun" { $dow = "U" }
       }
       if ("$year.$month.$day.$dow $hour" -ne $matches[0]) {
              "$create $mod $access $pathlen $fn"
       }
    }
  } else {
    "$create $mod $access $pathlen $fn"
  }
}
