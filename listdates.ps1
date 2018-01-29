param ( 
  [string]$path,
  [switch]$mismatchedDateInName = $false,
  [switch]$useCreate = $false
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
  $bn = $fsei.FileName
  $pathlen = $fn.length
  if($mismatchedDateInName) {
    if ($bn -match '(?<year>[0-9]{4})\.(?<month>[0-9]{2})\.(?<day>[0-9]{2})\.(?<dow>[MTWRFSU]) (?<hour>[0-9]{2})\.(?<minute>[0-9]{2})') {
       if ($useCreate) {
         $compare = $create
       } else {
         $compare = $mod
       }
       $year = $compare.ToString("yyyy")
       $month = $compare.ToString("MM")
       $day = $compare.ToString("dd")
       $hour = $compare.ToString("HH")
       $minute = $compare.ToString("mm")
       $dow = $compare.ToString("ddd")
       switch ($dow) {
         "Mon" { $dow = "M" }
         "Tue" { $dow = "T" }
         "Wed" { $dow = "W" }
         "Thu" { $dow = "R" }
         "Fri" { $dow = "F" }
         "Sat" { $dow = "S" }
         "Sun" { $dow = "U" }
       }
       $matchwith = "{0}.{1}.{2}.{3} {4}" -f $matches.year,$matches.month,$matches.day,$matches.dow,$matches.hour
       if ("$year.$month.$day.$dow $hour" -ne $matchwith) {
              "$create $mod $access $pathlen $fn"
       }
    }
  } else {
    "$create $mod $access $pathlen $fn"
  }
}
