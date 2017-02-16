param ( 
  [string]$path,
  [datetime]$firstwrite = [datetime]'1/1/1970',
  [datetime]$lastwrite = [System.DateTime]::Now
)

if(-not($path)) { Throw "You must supply a value for -path" }

Get-ChildItem "$path" -Recurse |
Where-Object {$_.lastwritetime -gt $firstwrite -AND $_.lastwritetime -lt $lastwrite} |
Foreach-Object {
  $fn = $_.FullName
  $isdir = $_ -is [System.IO.DirectoryInfo]
  $create = $_.CreationTime
  $mod = $_.LastWriteTime
  "$isdir $fn $create $mod"
}
