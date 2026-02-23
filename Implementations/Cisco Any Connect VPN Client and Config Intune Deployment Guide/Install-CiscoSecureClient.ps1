# Install-CiscoSecureClient.ps1
$ErrorActionPreference = 'Stop'

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MsiPath     = Join-Path $PackageRoot 'cisco-secure-client-win-5.1.12.146-core-vpn-predeploy-k9.msi'
$XmlSource   = Join-Path $PackageRoot 'Example.xml' # Change Example.xml to the name of your .xml config file.

$DestDir     = 'C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile'
$DestXml     = Join-Path $DestDir 'AnyConnectConfig.xml'

$LogDir = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$MsiLog = Join-Path $LogDir 'CiscoSecureClientInstall.log'

try {
    Write-Output "Starting Cisco Secure Client install..."

    if (!(Test-Path $MsiPath)) { throw "MSI not found at: $MsiPath" }
    if (!(Test-Path $XmlSource)) { throw "AnyConnectConfig.xml not found at: $XmlSource" }

    # Install MSI silently
    $msiArgs = "/i `"$MsiPath`" /qn /norestart /l*v `"$MsiLog`""
    $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    $msiExit = $proc.ExitCode

    Write-Output "MSI completed with exit code: $msiExit"

    # If you want to treat 3010 (reboot required) as success, handle it here
    if ($msiExit -ne 0 -and $msiExit -ne 3010) {
        throw "MSI install failed with exit code: $msiExit. See: $MsiLog"
    }

    # Ensure destination exists
    if (!(Test-Path $DestDir)) {
        New-Item -Path $DestDir -ItemType Directory -Force | Out-Null
    }

    # Copy profile XML
    Copy-Item -Path $XmlSource -Destination $DestXml -Force
    if (!(Test-Path $DestXml)) { throw "XML copy failed; file not found after copy: $DestXml" }

    Write-Output "Profile deployed to: $DestXml"

    # Return success (or reboot-required success)
    if ($msiExit -eq 3010) {
        Write-Output "Install succeeded but reboot is required (3010)."
        exit 3010
    }

    exit 0
}
catch {
    Write-Error "Install failed: $($_.Exception.Message)"
    exit $msiExit
}