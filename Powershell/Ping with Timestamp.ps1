ping.exe -t COMPUTERNAME|Foreach{"{0} - {1}" -f (Get-Date),$_}
