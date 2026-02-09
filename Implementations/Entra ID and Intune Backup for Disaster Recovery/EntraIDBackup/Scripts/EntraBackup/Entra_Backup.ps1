#=============================================================================================================================
#
# Script Name:     Entra_Backup.ps1
#
# Description:     Creates a dated backup directory and performs a full Entra ID (Azure AD) export using the EntraExporter
#                  module and Service Principal (client credentials) authentication. The script installs required modules,
#                  authenticates with MSAL to acquire an access token, connects to Microsoft Graph, and runs Export-Entra
#                  to output the backup into C:\Backup\EntraBackup\<yyyy-MM-dd>.
#
# Notes:           • Replace $tenantID, $clientID, and $clientSecret with your App Registration values.
#                  • Ensure the Service Principal has the necessary Graph **Application** permissions (Directory.Read.All,
#                    Policy.Read.All, Device.Read.All, etc.) and that admin consent has been granted.
#                  • Requires modules: MSAL.PS, Microsoft.Graph.Authentication, EntraExporter (auto-installed in script).
#                  • Access token is acquired via MSAL and passed into Connect-MgGraph; if token acquisition fails, the
#                    script exits safely without performing an export.
#                  • Backup directory is created automatically under the specified path with the current date. Confirm that
#                    the host has permissions to create/modify folders under C:\Backup.
#                  • Keep client secrets secure—avoid logging or exposing values. Consider Azure Key Vault or Managed
#                    Identity alternatives if you later migrate this process to an automation account or VM.
#                  • Export-Entra -All performs a full directory export; adjust scope as needed for partial exports.
#
#=============================================================================================================================

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
