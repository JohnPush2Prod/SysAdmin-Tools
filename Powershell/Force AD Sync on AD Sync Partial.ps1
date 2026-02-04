Import-Module ADSync 
Get-ADSyncScheduler
Start-ADSyncSyncCycle -PolicyType Delta