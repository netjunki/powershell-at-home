param ( 
  [string]$path
)

if(-not($path)) { Throw "You must supply a value for -path" }

Get-ChildItem "$path" -Recurse |
Foreach-Object {
  $fn = $_.FullName
  $isdir = $_ -is [System.IO.DirectoryInfo]
  $create = $_.CreationTime
  $mod = $_.LastWriteTime
  "$create $mod $fn"
}
