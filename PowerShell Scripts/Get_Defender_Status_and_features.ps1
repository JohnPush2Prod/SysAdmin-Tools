# Get Defender status and features
$defenderStatus = Get-MpComputerStatus | Select-Object `
    RealTimeProtectionEnabled, `
    BehaviorMonitorEnabled, `
    OnAccessProtectionEnabled, `
    AntivirusEnabled, `
    AMRunningMode, `
    IsTamperProtected, `
    AMProductVersion
$defenderStatus2 = Get-MpPreference | Select-Object EnableNetworkProtection

   
# Get installed antivirus info from Security Center
$installedAV = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct

# Display results
Write-Host "`n--- Defender Status ---"
$defenderStatus,$defenderStatus2 | Format-List


Write-Host "`n--- Installed Antivirus ---"
$installedAV | Format-Table displayName, productState, pathToSignedProductExe -AutoSize
