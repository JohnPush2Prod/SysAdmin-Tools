#=============================================================================================================================
#
# Script Name:     Intune_Backup.ps1
#
# Description:     Creates a dated backup directory and performs a full export of Entra ID (Azure AD) / Intune configuration
#                  using Microsoft Graph with Service Principal (client credentials) authentication. The script installs/
#                  updates required modules, authenticates via MSAL to acquire a Graph access token, connects to Graph
#                  with that token, and runs Export-Entra to write the backup into C:\Backup\IntuneBackup\<yyyy-MM-dd>.
#
# Notes:           • Replace the placeholders for $tenantID, $clientID, and $clientSecret with your app registration values.
#                  • The Service Principal must have sufficient Graph app permissions (Application) granted and admin-consented
#                    for the resources being exported (e.g., Policy.Read.All, Device.Read.All, Directory.Read.All, etc.),
#                    as required by IntuneBackupAndRestore/Export-Entra scope in your environment.
#                  • The script sets the process Execution Policy to Unrestricted; adjust if your org policy requires otherwise.
#                  • Requires modules: Microsoft.Graph.Intune, MSGraphFunctions, AzureAD, IntuneBackupAndRestore (auto-install/
#                    update is included). Ensure the host has internet access and permission to install/update modules.
#                  • Backups are written to $backupPath (daily folder). Verify disk space and permissions on C:\Backup.
#                  • Do not echo secrets in logs; keep $clientSecret secured. Prefer using a secure secret store or managed
#                    identity where applicable. Review logging before sharing outputs externally.
#                  • Token is acquired via MSAL (client credentials flow) and passed to Connect-MgGraph. If token retrieval
#                    fails, the script exits safely without partial export.
#                  • Export-Entra -All performs a broad export; tailor scope or paths if you need a smaller or segmented backup.
#
#=============================================================================================================================

# Define variables
$backupPath = "C:\Backup\IntuneBackup\$((Get-Date).ToString('yyyy-MM-dd'))"
$tenantID = ''  # Replace with your actual Tenant ID
$clientID = ''  # Replace with your Application (client) ID
$clientSecret = ''  # Replace with your Application (client) secret

# Create backup folder
New-Item -ItemType Directory -Path $backupPath -Force

#Customize the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

# Scopes required for the backup operation (Microsoft Graph API)
$scopes = @('https://graph.microsoft.com/.default')

# Convert the client secret into a secure string and pass to the New-MsalClientApplication
$secureClientSecret = (ConvertTo-SecureString "$clientSecret" -AsPlainText -Force)

# Install the necessary modules if not already installed
Write-Host 'Installing modules...'
Install-Module -Name Microsoft.Graph.Intune -Verbose -Force -AllowClobber
Install-Module -Name MSGraphFunctions -Verbose -Force -AllowClobber

#Import the Module
Import-Module -Name MSGraphFunctions

# Install the necessary modules if not already installed
Install-Module -Name AzureAD -Verbose -Force -AllowClobber
Install-Module -Name IntuneBackupAndRestore -Verbose -Force -AllowClobber

#Update the Module
Write-Host 'Updating modules...'
Update-Module -Name IntuneBackupAndRestore -Verbose

#Import the Module
Write-Host 'Importing module...'
Import-Module IntuneBackupAndRestore


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
