# Define variables
$backupPath = "C:\Backup\EntraBackup\$((Get-Date).ToString('yyyy-MM-dd'))"
$tenantID = ''  # Replace with your actual Tenant ID
$clientID = ''  # Replace with your Application (client) ID
$clientSecret = ''  # Replace with your Application (client) secret

# Create backup folder
New-Item -ItemType Directory -Path $backupPath -Force

# Scopes required for the backup operation (Microsoft Graph API)
$scopes = @('https://graph.microsoft.com/.default')

# Convert the client secret into a secure string and pass to the New-MsalClientApplication
$secureClientSecret = (ConvertTo-SecureString "$clientSecret" -AsPlainText -Force)

# Install the necessary modules if not already installed
Write-Host 'Installing required modules...'
Install-Module -Name MSAL.PS 
Install-Module -Name Microsoft.Graph.Authentication
Install-Module -Name EntraExporter

# Create the MSAL Confidential Client Application (Service Principal Authentication)
Write-Host 'Authenticating using Service Principal...'
$msalApp = New-MsalClientApplication -clientId $clientID -clientSecret $secureClientSecret -Authority "https://login.microsoftonline.com/$tenantID"

# Acquire the token for Microsoft Graph API
Write-Host 'Acquiring token for Microsoft Graph API...'
$tokenResponse = Get-MsalToken -clientID $clientID -clientSecret $secureClientSecret -tenantID $tenantID -Scopes $scopes

# Extract the access token from the response
$graphToken = (ConvertTo-SecureString $tokenResponse.AccessToken -AsPlainText -Force)

# Check if the token was retrieved successfully
if (-not $graphToken) {
    Write-Host "Failed to obtain access token. Exiting script."
    exit
}

Write-Host "Successfully authenticated. Access Token acquired."

# Connect to Microsoft Graph using the acquired token
Write-Host 'Connecting to Microsoft Graph...'
Connect-MgGraph -AccessToken $graphToken

# Connect to Entra ID and perform a full export
Write-Host 'Connecting to Entra ID...' 

# Start the backup process
Write-Host 'Starting backup...'
Export-Entra -Path $backupPath -All

Write-Host 'Backup complete...'
