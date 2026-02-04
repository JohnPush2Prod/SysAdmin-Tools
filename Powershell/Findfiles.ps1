$file = Read-Host 'What is the file you are looking for?'
Get-Childitem -Path C:\windows -Recurse -Filter $file -ErrorAction SilentlyContinue