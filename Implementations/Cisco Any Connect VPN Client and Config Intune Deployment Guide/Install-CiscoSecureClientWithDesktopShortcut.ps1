# Install-CiscoSecureClient.ps1
$ErrorActionPreference = 'Stop'

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MsiPath     = Join-Path $PackageRoot 'cisco-secure-client-win-5.1.12.146-core-vpn-predeploy-k9.msi'
$XmlSource   = Join-Path $PackageRoot 'AnyConnectConfig.xml'

$DestDir     = 'C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile'
$DestXml     = Join-Path $DestDir 'AnyConnectConfig.xml'

$LogDir = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
$MsiLog = Join-Path $LogDir 'CiscoSecureClientInstall.log'

# Desktop shortcut settings (Public Desktop / All Users)
$ExePath      = 'C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe'
$PublicDesktop = 'C:\Users\Public\Desktop'
$ShortcutPath = Join-Path $PublicDesktop 'Cisco Secure Client VPN.lnk'

$msiExit = $null

try {
    Write-Output "Starting Cisco Secure Client install..."

    if (!(Test-Path $MsiPath)) { throw "MSI not found at: $MsiPath" }
    if (!(Test-Path $XmlSource)) { throw "AnyConnectConfig.xml not found at: $XmlSource" }

    # Install MSI silently
    $msiArgs = "/i `"$MsiPath`" /qn /norestart /l*v `"$MsiLog`""
    $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
    $msiExit = $proc.ExitCode

    Write-Output "MSI completed with exit code: $msiExit"

    # Treat 3010 (reboot required) as success
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

    # Create Public Desktop shortcut (All Users)
    if (!(Test-Path $ExePath)) {
        throw "Cisco Secure Client UI EXE not found at: $ExePath"
    }

    if (!(Test-Path $PublicDesktop)) {
        New-Item -Path $PublicDesktop -ItemType Directory -Force | Out-Null
    }

    $wsh = New-Object -ComObject WScript.Shell
    $lnk = $wsh.CreateShortcut($ShortcutPath)
    $lnk.TargetPath = $ExePath
    $lnk.WorkingDirectory = Split-Path $ExePath -Parent
    $lnk.IconLocation = "$ExePath,0"
    $lnk.Description = "Cisco Secure Client VPN"
    $lnk.Save()

    if (!(Test-Path $ShortcutPath)) {
        throw "Shortcut creation failed; not found after save: $ShortcutPath"
    }

    Write-Output "Public Desktop shortcut created: $ShortcutPath"

    # Return success (or reboot-required success)
    if ($msiExit -eq 3010) {
        Write-Output "Install succeeded but reboot is required (3010)."
        exit 3010
    }
exit 0
}
catch {
    Write-Error "Install failed: $($_.Exception.Message)"
    if ($null -eq $msiExit) { exit 1 }
    exit $msiExit
}