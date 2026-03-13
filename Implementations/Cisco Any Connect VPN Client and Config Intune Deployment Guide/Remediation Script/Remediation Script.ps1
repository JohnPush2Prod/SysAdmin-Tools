# Stop Cisco services if present
$Services = @("vpnagent", "csc_vpnagent")

foreach ($Service in $Services) {
    Get-Service -Name $Service -ErrorAction SilentlyContinue |
        Where-Object { $_.Status -ne "Stopped" } |
        Stop-Service -Force
}

Start-Sleep -Seconds 10

# Remove ProgramData leftovers
Remove-Item "C:\ProgramData\Cisco\Cisco Secure Client" `
    -Recurse -Force -ErrorAction SilentlyContinue

# Remove Public Desktop shortcut
Remove-Item "C:\Users\Public\Desktop\Cisco Secure Client VPN.lnk" `
    -Force -ErrorAction SilentlyContinue

# Remove Start Menu shortcuts (commonly missed)
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Cisco*" `
    -Recurse -Force -ErrorAction SilentlyContinue