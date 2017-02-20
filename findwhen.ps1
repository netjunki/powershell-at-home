param ( 
  [string]$path,
  [datetime]$firstwrite = [datetime]'1/1/1970',
  [datetime]$lastwrite = [System.DateTime]::Now
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
    Write-Warning "$FailedItem : $ErrorMessage"
    return
  }
  if ($fsei.LastWriteTime -gt $firstwrite -AND $fsei.LastWriteTime -lt $lastwrite) {
    $create = $fsei.CreationTime
    $mod = $fsei.LastWriteTime
    $fn = $fsei.FullPath
    "$create $mod $fn"
  }
}