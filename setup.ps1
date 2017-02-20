$url = "https://github.com/alphaleonis/AlphaFS/releases/download/v2.1.2/AlphaFS.2.1.2.0.zip"
$output = "AlphaFS.2.1.2.0.zip"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, "$pwd\$output")

$alphaZip = “$pwd\$output”
$Destination = “$pwd\alpha”
Add-Type -assembly “system.io.compression.filesystem”
[io.compression.zipfile]::ExtractToDirectory($alphaZip, $destination)