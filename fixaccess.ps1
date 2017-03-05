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

"$folderPath"

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

ForEach ($Private:fsei In (Invoke-GenericMethod `
    -Instance           ([Alphaleonis.Win32.Filesystem.Directory]) `
    -MethodName         EnumerateFileSystemEntryInfos `
    -TypeParameters     Alphaleonis.Win32.Filesystem.FileSystemEntryInfo `
    -MethodParameters   "$folderPath", '*',
                        ([Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]'FilesAndFolders, SkipReparsePoints, Recursive, ContinueOnException'),
                        ([Alphaleonis.Win32.Filesystem.PathFormat]::FullPath))) {

    "$($fsei.IsDirectory) $($fsei.FullPath) $($fsei.CreationTime) $($fsei.LastAccessTime)"
    if ($fsei.LastAccessTime -gt $firstwrite -AND $fsei.LastAccessTime -lt $lastwrite) {
      if ($fsei.LastAccessTime -ne $fsei.CreationTime) {
        if ($doit) {
          [Alphaleonis.Win32.Filesystem.Directory]::SetLastAccessTime($fsei.FullPath,$fsei.CreationTime)
          "CHANGE $($fsei.IsDirectory) $($fsei.FullPath) $($fsei.CreationTime) $($fsei.LastAccessTime) -> $($fsei.CreationTime)"
          $changes = $true
        } else {
          "NOCHANGE $($fsei.IsDirectory) $($fsei.FullPath) $($fsei.CreationTime) $($fsei.LastAccessTime) -> $($fsei.CreationTime)"
        }
      }
    }
}