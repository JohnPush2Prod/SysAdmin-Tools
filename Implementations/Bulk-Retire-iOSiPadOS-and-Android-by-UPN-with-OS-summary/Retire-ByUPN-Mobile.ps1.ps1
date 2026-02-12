#=============================================================================================================================
#
# Script Name:     Retire_Mobile_Devices_ByUPN.ps1
#
# Description:     Reads a list of user principal names (UPNs) from a CSV and retires Intune-managed **mobile** devices
#                  (iOS, iPadOS, Android/Android Enterprise) for those users via Microsoft Graph. The script ensures a
#                  Graph connection, queries managed devices per UPN with pagination and resilient retries, applies an
#                  optional “last sync” guardrail, supports a -DryRun preview mode, and writes a detailed results CSV
#                  plus a per‑UPN summary CSV.
#   
#     
#------------------------BEFORE YOU RUN------------------------
# 
#Navegate to the folder with the Retire-ByUPN-Mobile.ps1 script 
#cd "Your.folder.path.here"
#
# End any current Graph session (ignore errors)
#Disconnect-MgGraph 2>$null
#
# Remove cached tokens/context so we get a *fresh* consent + token
#Remove-Item "$env:USERPROFILE\.graph" -Recurse -Force -ErrorAction SilentlyContinue
#Remove-Item "$env:LOCALAPPDATA\Microsoft\TokenBroker" -Recurse -Force -ErrorAction SilentlyContinue
#
#Sign-In and Connect to Graph
#Connect-MgGraph -TenantId "" -NoWelcome -Scopes #"DeviceManagementManagedDevices.PrivilegedOperations.All","DeviceManagementManagedDevices.ReadWrite.All","Directory.Read.All"
#
#------------------------RUN OPTIONS------------------------
#
# Dry-run (preview only) including iOS, iPadOS, and Android (-DryRun can be used with any of the following run options)
#.\Retire-ByUPN-Mobile.ps1 -InputCsvPath .\upns.csv -DryRun
#
# Execute retire and write both logs
#.\Retire-ByUPN-Mobile.ps1 -InputCsvPath .\upns.csv -OutputLogPath .\retire-mobile-log.csv -OutputSummaryPath .\retire-mobile-summary.csv
#
# Optional: exclude Android
#.\Retire-ByUPN-Mobile.ps1 -InputCsvPath .\upns.csv -IncludeAndroid:$false
#
# Optional guardrail: skip devices that checked in within the last 7 days
#.\Retire-ByUPN-Mobile.ps1 -InputCsvPath .\upns.csv -MinDaysSinceLastSync 7 -DryRun
#
#=============================================================================================================================


# Requires: Microsoft.Graph PowerShell SDK
# Sign in first (example):
# Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All","Directory.Read.All" -NoWelcome

param(
    [Parameter(Mandatory=$true)]
    [string]$InputCsvPath,

    [Parameter(Mandatory=$false)]
    [string]$OutputLogPath = ".\Retire-ByUPN-Mobile-Results.csv",

    [Parameter(Mandatory=$false)]
    [string]$OutputSummaryPath = ".\Retire-ByUPN-Mobile-Summary.csv",

    [switch]$DryRun,

    [switch]$IncludeIPadOS = $true,   # include iPadOS by default
    [switch]$IncludeAndroid = $true,  # include Android by default

    [int]$MinDaysSinceLastSync = 0    # optional guardrail: skip recent check-ins; 0 disables
)

function Ensure-GraphConnection {
    try {
        $ctx = Get-MgContext
        if (-not $ctx) {
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All","Directory.Read.All" -NoWelcome
        }
        # Using explicit v1.0 endpoints => no Select-MgProfile required
    } catch {
        throw "Failed to connect to Microsoft Graph. $_"
    }
}

function Invoke-GraphWithRetry {
    param(
        [ValidateSet('GET','POST')]
        [string]$Method,
        [string]$Uri,
        [string]$ContentType = "application/json",
        [string]$Body = $null,
        [int]$MaxRetries = 5
    )
    $attempt = 0
    $delay = 2
    while ($true) {
        try {
            if ($Method -eq 'GET') {
                return Invoke-MgGraphRequest -Method GET -Uri $Uri
            } else {
                return Invoke-MgGraphRequest -Method POST -Uri $Uri -ContentType $ContentType -Body $Body
            }
        } catch {
            $attempt++
            $msg = $_.Exception.Message
            # Backoff only on likely transient/throttle/server errors
            if ($attempt -ge $MaxRetries -or ($msg -notmatch '429|503|500|gateway|throttle|temporarily unavailable')) {
                throw $_
            }
            Start-Sleep -Seconds $delay
            $delay = [Math]::Min($delay * 2, 30)
        }
    }
}

function Get-AllManagedDevicesByUPN {
    param([Parameter(Mandatory=$true)][string]$Upn)

    $devices = @()
    # Use & (ampersand) and escape $ with backtick
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$filter=userPrincipalName eq '$Upn'&`$top=100"
    while ($true) {
        $resp = Invoke-GraphWithRetry -Method GET -Uri $uri
        if ($resp.value) { $devices += $resp.value }
        if ($resp.'@odata.nextLink') { $uri = $resp.'@odata.nextLink' } else { break }
    }
    return $devices
}

function Retire-ManagedDevice {
    param([Parameter(Mandatory=$true)][string]$ManagedDeviceId)
    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$ManagedDeviceId/retire"
    Invoke-GraphWithRetry -Method POST -Uri $uri -Body (@{} | ConvertTo-Json) | Out-Null
    return $true
}

# ---------------- Main ----------------
Ensure-GraphConnection

if (-not (Test-Path $InputCsvPath)) { throw "CSV not found: $InputCsvPath" }

# Load and normalize CSV to be tolerant of header spacing/case and blank lines
$raw = Import-Csv -Path $InputCsvPath
$rows = New-Object System.Collections.Generic.List[object]
foreach ($r in $raw) {
    # Build a trimmed-key hashtable of the row
    $h = @{}
    foreach ($p in $r.PSObject.Properties) {
        $key = ("{0}" -f $p.Name).Trim()
        $val = if ($null -ne $p.Value) { ("{0}" -f $p.Value).Trim() } else { "" }
        $h[$key] = $val
    }
    # Prefer 'UPN' but accept minor variants like 'Upn' or 'UPN '
    $upn =
        $(if     ($h.ContainsKey('UPN'))  { $h['UPN'] }
          elseif ($h.ContainsKey('Upn'))  { $h['Upn'] }
          elseif ($h.ContainsKey('UPN ')) { $h['UPN '] }
          else                             { $null })

    if ($upn -and $upn.Trim().Length -gt 0) {
        $rows.Add([pscustomobject]@{ UPN = $upn.Trim() })
    }
}

if ($rows.Count -eq 0) {
    Write-Warning "No valid UPNs found in $InputCsvPath after normalization. Ensure the header is exactly 'UPN' and rows are populated."
}

# Target OS allow list
$allowedOS = New-Object System.Collections.Generic.List[string]
$allowedOS.Add('iOS')
if ($IncludeIPadOS) { $allowedOS.Add('iPadOS') }
if ($IncludeAndroid) {
    $allowedOS.Add('Android')
    # Some tenants expose Android Enterprise as a distinct label; include for safety
    $allowedOS.Add('AndroidEnterprise')
}

# Optional guardrail cutoff date
$cutoffDate = $null
if ($MinDaysSinceLastSync -gt 0) {
    $cutoffDate = (Get-Date).AddDays(-$MinDaysSinceLastSync)
    Write-Host "Guardrail: skipping devices with last sync >= $cutoffDate (MinDaysSinceLastSync=$MinDaysSinceLastSync)" -ForegroundColor Yellow
}

# Collect results
$results = New-Object System.Collections.Generic.List[object]
$overallPreview = 0; $overallRetired = 0; $overallFailed = 0; $overallNone = 0; $overallSkipped = 0

foreach ($row in $rows) {
    $upn = $row.UPN
    if (-not $upn) {
        $results.Add([pscustomobject]@{
            UPN = $null; DeviceName = $null; OperatingSystem = $null; ManagedDeviceId = $null;
            Action = $(if ($DryRun) { 'Preview' } else { 'Retire' }); Status = 'Skipped'; Message = 'Missing UPN in row'
        })
        $overallSkipped++
        continue
    }

    # Fetch devices for this UPN
    try {
        $devices = Get-AllManagedDevicesByUPN -Upn $upn
    } catch {
        $results.Add([pscustomobject]@{
            UPN = $upn; DeviceName = $null; OperatingSystem = $null; ManagedDeviceId = $null;
            Action = $(if ($DryRun) { 'Preview' } else { 'Retire' }); Status = 'Failed'; Message = "Lookup failed: $($_.Exception.Message)"
        })
        $overallFailed++
        continue
    }

    # Filter by OS
    $targetDevices = $devices | Where-Object {
        $_.operatingSystem -and ($allowedOS -contains $_.operatingSystem)
    }

    # Apply optional last-sync guardrail
    if ($cutoffDate) {
        $targetDevices = $targetDevices | Where-Object {
            if ($_.lastSyncDateTime) {
                ([datetime]$_.lastSyncDateTime) -lt $cutoffDate
            } else {
                $true
            }
        }
    }

    if (-not $targetDevices -or $targetDevices.Count -eq 0) {
        $guardMsg = if ($cutoffDate) { " (after last-sync filter: older than $MinDaysSinceLastSync days)" } else { "" }
        $results.Add([pscustomobject]@{
            UPN = $upn; DeviceName = $null; OperatingSystem = $null; ManagedDeviceId = $null;
            Action = $(if ($DryRun) { 'Preview' } else { 'Retire' }); Status = 'NoneFound'; Message = "No target devices for UPN$guardMsg"
        })
        $overallNone++
        continue
    }

    foreach ($md in $targetDevices) {
        $action = $(if ($DryRun) { 'Preview' } else { 'Retire' })
        $status = 'Preview'
        $msg = 'Would retire'

        if (-not $DryRun) {
            try {
                $ok = Retire-ManagedDevice -ManagedDeviceId $md.id
                $status = if ($ok) { 'Retired' } else { 'Failed' }
                $msg = if ($ok) { 'Retire invoked' } else { 'Retire call failed' }
            } catch {
                $status = 'Failed'
                $msg = $_.Exception.Message
            }
        }

        switch ($status) {
            'Preview' { $overallPreview++ }
            'Retired' { $overallRetired++ }
            'Failed'  { $overallFailed++ }
        }

        $results.Add([pscustomobject]@{
            UPN              = $upn
            DeviceName       = $md.deviceName
            OperatingSystem  = $md.operatingSystem
            ManagedDeviceId  = $md.id
            SerialNumber     = $md.serialNumber
            AzureADDeviceId  = $md.azureADDeviceId
            ManagementAgent  = $md.managementAgent
            ComplianceState  = $md.complianceState
            LastSyncDateTime = $md.lastSyncDateTime
            Action           = $action
            Status           = $status
            Message          = $msg
        })
    }
}

# Write detailed results
$results | Sort-Object UPN, OperatingSystem, DeviceName | Export-Csv -Path $OutputLogPath -NoTypeInformation

# -------- Build OS + Status Summary per UPN --------

function Count-Where {
    param([array]$Items, [scriptblock]$Predicate)
    # Ensure the pipeline result is always an array, so .Count returns 0 instead of $null
    return @($Items | Where-Object $Predicate).Count
}

$summaryRows = New-Object System.Collections.Generic.List[object]

# Group by UPN
$grouped = $results | Group-Object UPN
foreach ($grp in $grouped) {
    $upn   = if ($null -ne $grp.Name -and $grp.Name -ne '') { $grp.Name } else { '<no-upn>' }
    $items = @($grp.Group)  # ensure array to avoid $null.Count

    # Normalize OS values for consistent counting
    foreach ($it in $items) {
        if ($it -and $it.PSObject.Properties.Match('OperatingSystem').Count -gt 0 -and $it.OperatingSystem) {
            $os = ([string]$it.OperatingSystem).Trim()
            switch -Regex ($os) {
                '^(?i)ios$'                { $it.OperatingSystem = 'iOS'                ; continue }
                '^(?i)ipad.?os$'           { $it.OperatingSystem = 'iPadOS'             ; continue }
                '^(?i)androidenterprise$'  { $it.OperatingSystem = 'AndroidEnterprise'  ; continue }
                '^(?i)android$'            { $it.OperatingSystem = 'Android'            ; continue }
                default { } # leave unchanged
            }
        }
    }

    $iosCount        = Count-Where -Items $items -Predicate { $_.OperatingSystem -eq 'iOS' }
    $ipadCount       = Count-Where -Items $items -Predicate { $_.OperatingSystem -eq 'iPadOS' }
    $androidCount    = Count-Where -Items $items -Predicate { $_.OperatingSystem -eq 'Android' }
    $androidEntCount = Count-Where -Items $items -Predicate { $_.OperatingSystem -eq 'AndroidEnterprise' }

    $retiredCount    = Count-Where -Items $items -Predicate { $_.Status -eq 'Retired' }
    $failedCount     = Count-Where -Items $items -Predicate { $_.Status -eq 'Failed' }
    $previewCount    = Count-Where -Items $items -Predicate { $_.Status -eq 'Preview' }
    $noneFoundCount  = Count-Where -Items $items -Predicate { $_.Status -eq 'NoneFound' }
    $skippedCount    = Count-Where -Items $items -Predicate { $_.Status -eq 'Skipped' }

    $totalDevicesRows = Count-Where -Items $items -Predicate { $_.ManagedDeviceId }

    $summaryRows.Add([pscustomobject]@{
        UPN                       = $upn
        Devices_iOS               = $iosCount
        Devices_iPadOS            = $ipadCount
        Devices_Android           = $androidCount
        Devices_AndroidEnterprise = $androidEntCount
        Total_DeviceRows          = $totalDevicesRows
        Retired                   = $retiredCount
        Failed                    = $failedCount
        Preview                   = $previewCount
        NoneFound                 = $noneFoundCount
        Skipped                   = $skippedCount
        MinDaysSinceLastSync      = $MinDaysSinceLastSync
    })
}

if ($summaryRows.Count -gt 0) {
    $overall = [pscustomobject]@{
        UPN                        = '***TOTALS***'
        Devices_iOS                = ($summaryRows | Measure-Object -Property Devices_iOS -Sum).Sum
        Devices_iPadOS             = ($summaryRows | Measure-Object -Property Devices_iPadOS -Sum).Sum
        Devices_Android            = ($summaryRows | Measure-Object -Property Devices_Android -Sum).Sum
        Devices_AndroidEnterprise  = ($summaryRows | Measure-Object -Property Devices_AndroidEnterprise -Sum).Sum
        Total_DeviceRows           = ($summaryRows | Measure-Object -Property Total_DeviceRows -Sum).Sum
        Retired                    = ($summaryRows | Measure-Object -Property Retired -Sum).Sum
        Failed                     = ($summaryRows | Measure-Object -Property Failed -Sum).Sum
        Preview                    = ($summaryRows | Measure-Object -Property Preview -Sum).Sum
        NoneFound                  = ($summaryRows | Measure-Object -Property NoneFound -Sum).Sum
        Skipped                    = ($summaryRows | Measure-Object -Property Skipped -Sum).Sum
        MinDaysSinceLastSync       = $MinDaysSinceLastSync
    }
    $summaryRows.Add($overall)
}

$summaryRows | Export-Csv -Path $OutputSummaryPath -NoTypeInformation

# Useful console summary
$upnCount = ($rows | Select-Object -ExpandProperty UPN -Unique).Count
Write-Host "Done." -ForegroundColor Green
Write-Host "UPNs processed: $upnCount"
Write-Host ("Preview rows:   {0}" -f (@($results | Where-Object Status -eq 'Preview')).Count)
Write-Host ("Retired:        {0}" -f (@($results | Where-Object Status -eq 'Retired')).Count)
Write-Host ("Failed:         {0}" -f (@($results | Where-Object Status -eq 'Failed')).Count)
Write-Host ("NoneFound:      {0}" -f (@($results | Where-Object Status -eq 'NoneFound')).Count)
Write-Host ("Skipped:        {0}" -f (@($results | Where-Object Status -eq 'Skipped')).Count)
Write-Host "Detailed log:   $OutputLogPath"
Write-Host "Summary log:    $OutputSummaryPath"
