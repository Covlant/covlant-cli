# Covlant CLI Installer for Windows
# This script installs the Covlant CLI to your system

# Configuration
$GitHubRepo = "covlant/covlant-cli"
$BinaryName = "covlant.exe"
$InstallDir = "$env:LOCALAPPDATA\Covlant\bin"
$TempDir = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
$UserAgent = "Covlant-CLI-Installer/1.0"
$Version = "1.2.10" # This will be replaced by the release script

# Create temporary directory
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

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
    } else {
        Write-ColorOutput "Error: Unsupported architecture: $arch" -ForegroundColor Red
        Write-Output "The Covlant CLI is currently only available for x64 architecture."
        exit 1
    }
}

$Architecture = Get-SystemArchitecture
Write-ColorOutput "Detected architecture: $Architecture" -ForegroundColor Cyan
Write-ColorOutput "Using version: $Version" -ForegroundColor Green

# Get the latest version from GitHub if not specified
function Get-LatestVersion {
    if ($Version -ne "0.0.0") {
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
        Write-Output "Error details: $_"
        exit 1
    }
}

$LatestVersion = Get-LatestVersion

# Download the binary - with fallback methods
$zipFileName = "covlant-windows-$Architecture-v$LatestVersion.zip"
$downloadUrl = "https://github.com/$GitHubRepo/releases/download/v$LatestVersion/$zipFileName"
$zipFilePath = Join-Path -Path $TempDir -ChildPath $zipFileName

Write-ColorOutput "Downloading Covlant CLI from: $downloadUrl" -ForegroundColor Cyan

try {
    # Use TLS 1.2 for compatibility with GitHub
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Try Invoke-WebRequest first
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -UseBasicParsing -Headers @{"User-Agent"=$UserAgent}

    if (Test-Path $zipFilePath) {
        $fileSize = (Get-Item $zipFilePath).Length
        Write-ColorOutput "Download complete. File size: $fileSize bytes" -ForegroundColor Green
    } else {
        throw "File download failed - file not found after download"
    }
}
catch {
    Write-ColorOutput "First download method failed: $_" -ForegroundColor Yellow
    Write-ColorOutput "Trying alternative download method..." -ForegroundColor Yellow

    try {
        # Try wget syntax as fallback
        wget $downloadUrl -OutFile $zipFilePath

        if (Test-Path $zipFilePath) {
            $fileSize = (Get-Item $zipFilePath).Length
            Write-ColorOutput "Download complete with alternative method. File size: $fileSize bytes" -ForegroundColor Green
        } else {
            throw "File still not found after alternative download method"
        }
    }
    catch {
        Write-ColorOutput "All download methods failed." -ForegroundColor Red
        Write-Output "Error details: $_"
        Write-Output "Please try downloading manually from: $downloadUrl"

        $manualDownload = Read-Host "Do you have the file downloaded already? (y/n)"
        if ($manualDownload -eq "y") {
            $manualPath = Read-Host "Please enter the full path to the downloaded file"
            if (Test-Path $manualPath) {
                $zipFilePath = $manualPath
                Write-ColorOutput "Using manually provided file at: $zipFilePath" -ForegroundColor Green
            } else {
                Write-ColorOutput "Error: The specified file at '$manualPath' does not exist." -ForegroundColor Red
                Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
                exit 1
            }
        } else {
            Write-ColorOutput "Installation canceled." -ForegroundColor Red
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }
    }
}

# Verify the checksum
function Verify-Checksum {
    param (
        [string]$PackagePath
    )

    Write-ColorOutput "Verifying checksum..." -ForegroundColor Cyan

    $checksumUrl = "$downloadUrl.sha256"
    $checksumPath = "$PackagePath.sha256"

    try {
        # Use TLS 1.2 for compatibility with GitHub
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Try to download the checksum file
        Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumPath -UseBasicParsing -Headers @{"User-Agent"=$UserAgent}

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
        Write-Output "Error details: $_"
    }
}

Verify-Checksum -PackagePath $zipFilePath

# Extract the package
$extractPath = Join-Path -Path $TempDir -ChildPath "extract"
Write-ColorOutput "Extracting package to: $extractPath" -ForegroundColor Cyan

try {
    New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
    Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
}
catch {
    Write-ColorOutput "Error with standard extraction: $_" -ForegroundColor Yellow
    Write-ColorOutput "Trying alternative extraction method..." -ForegroundColor Yellow

    try {
        # Alternative extraction method
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $extractPath)
    }
    catch {
        Write-ColorOutput "All extraction methods failed." -ForegroundColor Red
        Write-Output "Error details: $_"
        Write-Output "The zip file at $zipFilePath may be corrupt or invalid."
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# List the extracted contents
Write-ColorOutput "Extracted files:" -ForegroundColor Cyan
Get-ChildItem -Path $extractPath -Recurse | ForEach-Object { Write-Output "  $_" }

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
    try {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        Write-ColorOutput "Created installation directory: $InstallDir" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Error creating installation directory: $_" -ForegroundColor Red
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# Install the binary
$installPath = Join-Path -Path $InstallDir -ChildPath $BinaryName
try {
    Copy-Item -Path $binaryPath -Destination $installPath -Force
    Write-ColorOutput "Copied binary to: $installPath" -ForegroundColor Green
}
catch {
    Write-ColorOutput "Error copying binary: $_" -ForegroundColor Red
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

if (-not (Test-Path -Path $installPath)) {
    Write-ColorOutput "Error: Failed to install the Covlant CLI binary." -ForegroundColor Red
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($currentPath -notlike "*$InstallDir*") {
    Write-ColorOutput "Adding Covlant CLI to your PATH..." -ForegroundColor Cyan

    try {
        $newPath = "$currentPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        $env:PATH = "$env:PATH;$InstallDir"
        Write-ColorOutput "Successfully added to PATH." -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "Warning: Failed to add Covlant CLI to your PATH." -ForegroundColor Yellow
        Write-Output "You may need to manually add $InstallDir to your PATH."
        Write-Output "Error details: $_"
    }
}
else {
    Write-ColorOutput "Covlant CLI is already in your PATH." -ForegroundColor Green
}

# Clean up
try {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "Cleaned up temporary files." -ForegroundColor Green
}
catch {
    Write-ColorOutput "Warning: Could not clean up temporary files at $TempDir." -ForegroundColor Yellow
}

# Verify installation
$testPath = Join-Path -Path $InstallDir -ChildPath $BinaryName
if (Test-Path $testPath) {
    Write-ColorOutput "`nCovlant CLI installation complete!" -ForegroundColor Green
    Write-Output "You may need to restart your terminal or PowerShell session for the PATH changes to take effect."
    Write-Output "Run '$BinaryName --help' to get started."
} else {
    Write-ColorOutput "`nCovlant CLI installation failed - binary not found at expected location." -ForegroundColor Red
    Write-Output "Please check the logs above for any errors."
}