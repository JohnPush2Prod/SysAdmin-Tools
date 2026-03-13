# Ensure running as admin
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host " ERROR: Please run this script as Administrator!" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Exit 1
}

# Set TLS 1.2 for secure downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set Execution Policy for session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# Function to ensure PowerShellGet supports -AcceptLicense
function Ensure-PowerShellGetSupportsAcceptLicense {
    Write-Host "[INFO] Checking PowerShellGet version..." -ForegroundColor Green

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    $psGetVersion = (Get-Module -Name PowerShellGet -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version

    if ($psGetVersion -lt [version]"2.0.0") {
        Write-Host "[INFO] PowerShellGet is older than 2.0.0. Updating..." -ForegroundColor Yellow
        try {
            Install-Module -Name PowerShellGet -MinimumVersion 2.0.0 -Force -AllowClobber
            Write-Host "[INFO] PowerShellGet updated successfully." -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Failed to update PowerShellGet: $($_.Exception.Message)" -ForegroundColor Red
            Exit 1
        }

        # Reload latest version into current session
        Remove-Module PowerShellGet -Force -ErrorAction SilentlyContinue
        Import-Module PowerShellGet -Force
    } else {
        Write-Host "[INFO] PowerShellGet version $psGetVersion is up-to-date." -ForegroundColor Green
        Import-Module PowerShellGet -Force
    }
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   Windows Autopilot Enrollment Script Starting..." -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure PowerShellGet supports -AcceptLicense
Ensure-PowerShellGetSupportsAcceptLicense

# Check if -AcceptLicense is supported
$acceptLicenseSupported = (Get-Command Install-Script).Parameters.ContainsKey("AcceptLicense")

# Install the script if not already installed
$scriptInstalled = Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue

if (-not $scriptInstalled) {
    Write-Host "[INFO] Installing Get-WindowsAutopilotInfo script..." -ForegroundColor Green
    if ($acceptLicenseSupported) {
        Install-Script -Name Get-WindowsAutopilotInfo -Force -AcceptLicense
    } else {
        Install-Script -Name Get-WindowsAutopilotInfo -Force
        Write-Host "[WARNING] 'AcceptLicense' not supported. You may be prompted interactively." -ForegroundColor Yellow
    }
    Write-Host "[INFO] Installation complete." -ForegroundColor Green
} else {
    Write-Host "[INFO] Get-WindowsAutopilotInfo script already installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   Collecting hardware hash and uploading to Intune" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "A Microsoft sign-in window will appear. Please authenticate with your Intune tenant credentials." -ForegroundColor Yellow
Write-Host ""

# Run the script even if it's not in PATH
$EnrollmentSuccess = $false
Try {
    if (Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue) {
        Get-WindowsAutopilotInfo -Online -ErrorAction Stop
    } else {
        $scriptPath = (Get-InstalledScript -Name Get-WindowsAutopilotInfo).InstalledLocation + "\Get-WindowsAutopilotInfo.ps1"
        & $scriptPath -Online
    }
    $EnrollmentSuccess = $true
}
Catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host " ERROR: Autopilot enrollment failed!" -ForegroundColor Red
    Write-Host " Details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
}

# Check result and act accordingly
if ($EnrollmentSuccess) {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host " Enrollment and upload complete. Restarting device" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""

    for ($i = 10; $i -ge 1; $i--) {
        Write-Host "Restarting in $i seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }

    shutdown /r /t 0 /f
} else {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host " Enrollment failed or was not completed." -ForegroundColor Red
    Write-Host " Please re-run the script and check your connection." -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
}
