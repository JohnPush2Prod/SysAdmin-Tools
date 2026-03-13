# Cisco Secure Client product code
$ProductCode = "#enter client product code"

# Check if MSI is still installed
$Installed = Get-ItemProperty `
    HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -eq $ProductCode }

# Check for leftovers
$ProgramDataExists = Test-Path "C:\ProgramData\Cisco\Cisco Secure Client"
$PublicShortcutExists = Test-Path "C:\Users\Public\Desktop\Cisco Secure Client VPN.lnk"
$StartMenuExists = Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cisco*"

# Logic:
# MSI is gone
# BUT leftovers still exist
if (-not $Installed -and ($ProgramDataExists -or $PublicShortcutExists -or $StartMenuExists)) {
    exit 1   
}

exit 0     