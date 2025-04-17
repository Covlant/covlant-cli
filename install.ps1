# Covlant CLI Installer for Windows
# This script installs the Covlant CLI to your system

# Configuration
$GitHubRepo = "covlant/covlant-cli"
$BinaryName = "covlant.exe"
$InstallDir = "$env:LOCALAPPDATA\Covlant\bin"
$TempDir = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
$UserAgent = "Covlant-CLI-Installer/1.0"
$Version = "1.2.9" # This will be replaced by the release script

# Color output
function Write-ColorOutput {
    param (
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [string]$ForegroundColor = "White"
    )

    $previousColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $previousColor
}

# Print banner
Write-ColorOutput @"

   ______            __            __     ___    ____
  / ____/___  _   __/ /___ _____  / /_   /   |  /  _/
 / /   / __ \| | / / / __ ``/ __ \/ __/  / /| | _/ /
/ /___/ /_/ /| |/ / / /_/ / / / / /_   / ___ |/  _/
\____/\____/ |___/_/\__,_/_/ /_/\__/  /_/  |_/_/

"@ -ForegroundColor Cyan

Write-ColorOutput "Covlant AI CLI Installer" -ForegroundColor Green
Write-Output "This script will install the Covlant CLI to your system.`n"

# Check if running with admin privileges
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-Not (Test-Administrator)) {
    Write-ColorOutput "Warning: You are not running as Administrator. Installation may fail if writing to system directories." -ForegroundColor Yellow
    Write-Output "The script will continue and install to user directory instead.`n"
}

# Detect system architecture
function Get-SystemArchitecture {
    $arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")

    if ($arch -eq "AMD64" -or $arch -eq "IA64") {
        return "x64"
    } elseif ($arch -eq "ARM64") {
        return "arm64"
    } else {
        Write-ColorOutput "Error: Unsupported architecture: $arch" -ForegroundColor Red
        Write-Output "The Covlant CLI is available for x64  architecture."
        exit 1
    }
}

$Architecture = Get-SystemArchitecture
Write-ColorOutput "Detected architecture: $Architecture" -ForegroundColor Cyan

# Get the latest version from GitHub if not specified
function Get-LatestVersion {
    if ($Version -ne "0.0.0") {
        Write-ColorOutput "Using version: v$Version" -ForegroundColor Green
        return $Version
    }

    Write-ColorOutput "Fetching the latest version of Covlant CLI..." -ForegroundColor Cyan

    try {
        $headers = @{
            "User-Agent" = $UserAgent
        }

        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/releases/latest" -Headers $headers
        $latestVersion = $latestRelease.tag_name.TrimStart('v')

        Write-ColorOutput "Latest version: v$latestVersion" -ForegroundColor Green
        return $latestVersion
    }
    catch {
        Write-ColorOutput "Error: Could not determine the latest version." -ForegroundColor Red
        Write-Output "Please check your internet connection or try again later."
        exit 1
    }
}

$LatestVersion = Get-LatestVersion

# Create temporary directory
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

# Download the appropriate binary
function Download-Binary {
    $packageName = "covlant-windows-$Architecture-v$LatestVersion.zip"
    $downloadUrl = "https://github.com/$GitHubRepo/releases/download/v$LatestVersion/$packageName"
    $outputPath = Join-Path -Path $TempDir -ChildPath $packageName

    Write-ColorOutput "Downloading Covlant CLI $packageName..." -ForegroundColor Cyan

    try {
        # Use TLS 1.2 for compatibility with GitHub
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", $UserAgent)
        $webClient.DownloadFile($downloadUrl, $outputPath)

        return $outputPath
    }
    catch {
        Write-ColorOutput "Error: Failed to download the Covlant CLI binary." -ForegroundColor Red
        Write-Output "Please check your internet connection or try again later."
        Write-Output "Error details: $_"
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

$packagePath = Download-Binary

# Verify the checksum
function Verify-Checksum {
    param (
        [string]$PackagePath
    )

    Write-ColorOutput "Verifying checksum..." -ForegroundColor Cyan

    $checksumUrl = "$PackagePath.sha256"
    $checksumUrl = $checksumUrl.Replace($TempDir, "https://github.com/$GitHubRepo/releases/download/v$LatestVersion")
    $checksumPath = "$PackagePath.sha256"

    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", $UserAgent)
        $webClient.DownloadFile($checksumUrl, $checksumPath)

        $expectedChecksum = Get-Content -Path $checksumPath | ForEach-Object { $_.Split(' ')[0] }
        $calculatedChecksum = (Get-FileHash -Path $PackagePath -Algorithm SHA256).Hash.ToLower()

        if ($calculatedChecksum -ne $expectedChecksum) {
            Write-ColorOutput "Error: Checksum verification failed." -ForegroundColor Red
            Write-Output "Expected: $expectedChecksum"
            Write-Output "Got: $calculatedChecksum"
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }

        Write-ColorOutput "Checksum verified successfully." -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Warning: Could not verify checksum. Proceeding anyway." -ForegroundColor Yellow
    }
}

Verify-Checksum -PackagePath $packagePath

# Install the binary
function Install-Binary {
    param (
        [string]$PackagePath
    )

    Write-ColorOutput "Installing Covlant CLI..." -ForegroundColor Cyan

    # Extract the package
    Write-ColorOutput "Extracting package..." -ForegroundColor Cyan

    $extractPath = Join-Path -Path $TempDir -ChildPath "extract"
    Expand-Archive -Path $PackagePath -DestinationPath $extractPath -Force

    # Debug: List the extracted contents
    Write-ColorOutput "Extracted package contents:" -ForegroundColor Cyan
    Get-ChildItem -Path $extractPath -Recurse | ForEach-Object { $_.FullName }

    # Find the binary
    $binaryPath = Get-ChildItem -Path $extractPath -Recurse -Filter $BinaryName | Select-Object -First 1 -ExpandProperty FullName

    if (-not $binaryPath) {
        Write-ColorOutput "Error: Could not find the covlant.exe binary in the extracted package." -ForegroundColor Red
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-ColorOutput "Found binary at: $binaryPath" -ForegroundColor Green

    # Create the installation directory if it doesn't exist
    if (-not (Test-Path -Path $InstallDir)) {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    }

    # Install the binary
    $installPath = Join-Path -Path $InstallDir -ChildPath $BinaryName
    Copy-Item -Path $binaryPath -Destination $installPath -Force

    if (-not (Test-Path -Path $installPath)) {
        Write-ColorOutput "Error: Failed to install the Covlant CLI binary." -ForegroundColor Red
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    Write-ColorOutput "Covlant CLI installed successfully to $installPath" -ForegroundColor Green

    return $installPath
}

$installedPath = Install-Binary -PackagePath $packagePath

# Add to PATH
function Add-ToPath {
    param (
        [string]$Directory
    )

    # Check if the directory is already in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

    if ($currentPath -notlike "*$Directory*") {
        Write-ColorOutput "Adding Covlant CLI to your PATH..." -ForegroundColor Cyan

        try {
            $newPath = "$currentPath;$Directory"
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

            # Also update the current session's PATH
            $env:PATH = "$env:PATH;$Directory"

            Write-ColorOutput "Successfully added to PATH." -ForegroundColor Green
        }
        catch {
            Write-ColorOutput "Warning: Failed to add Covlant CLI to your PATH." -ForegroundColor Yellow
            Write-Output "You may need to manually add $Directory to your PATH."
        }
    }
    else {
        Write-ColorOutput "Covlant CLI is already in your PATH." -ForegroundColor Green
    }
}

Add-ToPath -Directory $InstallDir

# Clean up
function Cleanup {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}

Cleanup

# Print success message
Write-ColorOutput "`nCovlant CLI installation complete!" -ForegroundColor Green
Write-Output "You may need to restart your terminal or PowerShell session for the PATH changes to take effect."
Write-Output "Run '$BinaryName --help' to get started."