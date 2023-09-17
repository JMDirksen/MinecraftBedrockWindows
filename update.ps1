try { $db = Import-Clixml "update.db" }
catch { $db = @{} }
$request = @{
    "Uri"       = "https://www.minecraft.net/en-us/download/server/bedrock"
    "Headers"   = @{ "Accept-Language" = "*" }
}
try { $page = Invoke-WebRequest @request -TimeoutSec 5 }
catch { $_.Exception.Message; exit }
$downloadlink = $page.Links.href | Where-Object { $_ -like "*/bin-win/bedrock-server-*.zip" }
$filename = $downloadlink.Split("/")[-1]
$version = $filename.Substring(15).Replace(".zip", "")
if ($version -eq $db.version) { exit }
if (-not (Test-Path $filename)) { Invoke-WebRequest -Uri $downloadlink -OutFile $filename }
Expand-Archive $filename -DestinationPath "tmp"
if (Test-Path ".\server\allowlit.json") { Remove-Item ".\tmp\allowlist.json" }
if (Test-Path ".\server\permissions.json") { Remove-Item ".\tmp\permissions.json" }
if (Test-Path ".\server\server.properties") { Remove-Item ".\tmp\server.properties" }
Stop-Process -Name "bedrock_server" -Force
if (-not (Test-Path ".\server")) { New-Item -Path "." -Name "server" -ItemType Directory }
Copy-Item -Path ".\tmp\*" -Destination ".\server" -Recurse -Force
Remove-Item ".\tmp" -Recurse -Force
$db.version = $version
$db | Export-Clixml "update.db"
