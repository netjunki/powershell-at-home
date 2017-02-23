param ( 
  [string]$path
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
  "$create $mod $access $fn"
}
