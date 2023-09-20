function Main {
    Output "Start update"
    Output "Loading current version..."
    $currentversion = Get-Content ".\version.txt" -ErrorAction SilentlyContinue
    Output "Running: $currentversion"
    Output "Reading Minecraft download page..."
    $request = @{
        "Uri"     = "https://www.minecraft.net/en-us/download/server/bedrock"
        "Headers" = @{ "Accept-Language" = "*" }
    }
    try { $page = Invoke-WebRequest @request -TimeoutSec 5 }
    catch { $_.Exception.Message; exit }
    $downloadlink = $page.Links.href | Where-Object { $_ -like "*/bin-win/bedrock-server-*.zip" }
    $filename = $downloadlink.Split("/")[-1]
    $version = $filename.Substring(15).Replace(".zip", "")
    Output "Online: $version"
    if ( -not (isHigherVersion $version $currentversion) ) {
        Output "Done."
        exit
    }
    if (-not (Test-Path $filename)) {
        Output "Downloading $filename..."
        Invoke-WebRequest -Uri $downloadlink -OutFile $filename
    }
    Output "Extracting..."
    Expand-Archive $filename -DestinationPath "tmp"
    Output "Removing unwanted files..."
    if (Test-Path ".\server\allowlit.json") { Remove-Item ".\tmp\allowlist.json" }
    if (Test-Path ".\server\permissions.json") { Remove-Item ".\tmp\permissions.json" }
    if (Test-Path ".\server\server.properties") { Remove-Item ".\tmp\server.properties" }
    Output "Stopping process..."
    Stop-Process -Name "bedrock_server" -Force
    if (-not (Test-Path ".\server")) {
        Output "Creating server directory..."
        New-Item -Path "." -Name "server" -ItemType Directory
    }
    Output "Copying files..."
    Copy-Item -Path ".\tmp\*" -Destination ".\server" -Recurse -Force
    Output "Cleaning up..."
    Remove-Item ".\tmp" -Recurse -Force
    Output "Updating current version..."
    $version | Set-Content ".\version.txt"
    Output "Done."
}

function isHigherVersion ($ThisVersion, $ReferenceVersion) {
    $ver = $ThisVersion.Split(".")
    $ref = $ReferenceVersion.Split(".")
    for ($i = 0; $i -lt $ver.Count; $i++) {
        if ([int]$ver[$i] -gt [int]$ref[$i]) { return $true }
        if ([int]$ver[$i] -lt [int]$ref[$i]) { return $false }
    }
    return $false
}

function Output ($message) {
    Write-Host $message
    $(Get-Date -Format "yyyy-MM-dd HH:mm:ss ") + $message | Out-File ".\update.log" -Append
}

Main
