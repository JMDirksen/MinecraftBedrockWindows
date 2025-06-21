$ErrorActionPreference = "Stop"

function Main {

    # Check for update
    Output "Start update"
    Output "Checking running version..."
    $currentversion = Get-Content ".\version.txt" -ErrorAction SilentlyContinue
    if (-not $currentversion) { $currentversion = "0" }
    Output "Running version: $currentversion"
    Output "Requesting Minecraft API for current version..."
    $ApiDownloadLinks = Invoke-RestMethod -Uri "https://net.web.minecraft-services.net/api/v1.0/download/links" -UseBasicParsing
    $DownloadUrl = ($ApiDownloadLinks.result.links | Where-Object {$_.downloadType -eq "serverBedrockWindows"}).downloadUrl
    $filename = $DownloadUrl.Split("/")[-1]
    $version = $filename.Substring(15).Replace(".zip", "")
    Output "Current version: $version"
    if ( -not (isHigherVersion $version $currentversion) ) {
        Output "Done."
        exit
    }

    # Download update
    if (-not (Test-Path $filename)) {
        Output "Downloading $filename..."
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $filename
    }

    # Extract / exclude
    Output "Extracting..."
    Expand-Archive $filename -DestinationPath "tmp"
    Output "Excluding files..."
    $exclude = "worlds", "server.properties", "allowlist.json", "permissions.json"
    $exclude | ForEach-Object { if (Test-Path ".\server\$_") { Remove-Item ".\tmp\$_" -ErrorAction SilentlyContinue } }

    # Stop process
    Output "Stopping process..."
    Stop-Process -Name "bedrock_server" -Force -ErrorAction SilentlyContinue
    
    # Create directory
    if (-not (Test-Path ".\server")) {
        Output "Creating server directory..."
        New-Item -Path "." -Name "server" -ItemType Directory
    }

    # Removing / copying / cleaning up
    Output "Removing files..."
    Get-ChildItem -Path ".\server" -Exclude $exclude | Remove-Item -Recurse -Force
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
