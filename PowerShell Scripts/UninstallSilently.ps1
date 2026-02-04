Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name = 'SoftwareName'" | ForEach-Object { $_.Uninstall() }
