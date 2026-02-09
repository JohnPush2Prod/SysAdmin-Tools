Microsoft Recovery and capabilities

1.0 Disaster Recovery for Intune 


1.1 Recovery guide 

IMPORTANT: Restoring configurations will not overwrite existing configurations. Instead, it creates new ones. Restoring assignments may overwrite existing assignments.

IMPORTANT: Does not support backing up Intune configuration items with duplicate Display Names. Files may be overwritten.
In the event of a disaster affecting the whole of the Intune tenant you can restore the Intune configuration from a backup by using the scripts found under Full Intune Restore in this document. 
In the event of a disaster affecting sections or specific parts of the Intune tenant you can restore the specific Intune configurations from a backup by using the scripts found in the Recovery Guide. 
If you are unsure what has changed in the event of a disaster or need to find what backup to pull from you can use the scripts under Compare two Backup Files for changes and compare all files in two Backup Directories. 

Full Intune Restore 
Start-IntuneRestoreConfig -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’
Start-IntuneRestoreAssignments -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’

Restore Intune Assignments
Start-IntuneRestoreAssignments -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’
Note: If reassigning assignments to existing (non-restored) configurations. In this case the assignments match the configuration id to restore to.

The below script allows for restoring if display names have changed.
Start-IntuneRestoreAssignments -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’ -RestoreById $true

Restore only Intune Compliance Policies
Invoke-IntuneRestoreDeviceCompliancePolicy -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’
Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path ‘C:\Backup\\IntuneBackup\YYYY-MM-DD’

Restore Only Intune Device Configurations
Invoke-IntuneRestoreDeviceConfiguration -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’
Invoke-IntuneRestoreDeviceConfigurationAssignment -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’

Backup Only Intune Endpoint Security Configurations
Invoke-IntuneBackupDeviceManagementIntent -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’

Restore Only Intune Endpoint Security Configurations
Invoke-IntuneRestoreDeviceManagementIntent -Path ‘C:\Backup\IntuneBackup\YYYY-MM-DD’

Compare two Backup Files for changes
# The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
Compare-IntuneBackupFile -ReferenceFilePath ‘C:\Backup\IntuneBackup\YYYY-MM-DD\Device Configurations\Windows - Endpoint Protection.json' -DifferenceFilePath 'C:\Backup\IntuneBackup\YYYY-MM-DD\Device Configurations\Windows - Endpoint Protection.json'

Compare all files in two Backup Directories for changes
# The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
Compare-IntuneBackupDirectories -ReferenceDirectory ‘C:\Backup\IntuneBackup\YYYY-MM-DD’ -DifferenceDirectory ‘C:\Backup\IntuneBackup\YYYY-MM-DD’


1.2 Recovery Capabilities 

      Backup actions
* Administrative Templates (Device Configurations)
* Administrative Template Assignments
* App Protection Policies
* App Protection Policy Assignments
* Client Apps
* Client App Assignments
* Device Compliance Policies
* Device Compliance Policy Assignments
* Device Configurations
* Device Configuration Assignments
* Device Management Scripts (Device Configuration -> PowerShell Scripts)
* Device Management Script Assignments
* Settings Catalog Policies
* Settings Catalog Policy Assignments
* Software Update Rings
* Software Update Ring Assignments
* Endpoint Security Configurations
o Security Baselines
* Windows 10 Security Baselines
* Microsoft Defender ATP Baselines
* Microsoft Edge Baseline
o Antivirus
o Disk encryption
o Firewall
o Endpoint detection and response
o Attack surface reduction
o Account protection
o Device compliance

      Restore actions
* Administrative Templates (Device Configurations)
* Administrative Template Assignments
* App Protection Policies
* App Protection Policy Assignments
* Client App Assignments
* Device Compliance Policies
* Device Compliance Policy Assignments
* Device Configurations
* Device Configuration Assignments
* Device Management Scripts (Device Configuration -> PowerShell Scripts)
* Device Management Script Assignments
* Settings Catalog Policies
* Settings Catalog Policy Assignments
* Software Update Rings
* Software Update Ring Assignments
* Endpoint Security Configurations
o Security Baselines
* Windows 10 Security Baselines
* Microsoft Defender ATP Baselines
* Microsoft Edge Baseline
o Antivirus
o Disk encryption
o Firewall
o Endpoint detection and response
o Attack surface reduction
o Account protection
o Device compliance



2.0 Disaster Recovery for Entra 


   2.1 Recovery Guide

Recovery from Entra backup to the Tennant will be manual. A .JSON file will need to be read by an administrator and manually mirrored to the Tennant. 
You can export a backup for specific sections of Entra via the Scripts listed in the Recovery Guide.
The currently valid types are: All (all elements), Config (default configuration), AccessReviews, ConditionalAccess, Users, Groups, Applications, ServicePrincipals, B2C, B2B, PIM, PIMAzure, PIMAAD, AppProxy, Organization, Domains, EntitlementManagement, Policies, AdministrativeUnits, SKUs, Identity, Roles, Governance.

Retrieve the full list of valid type commands
(Get-Command Export-Entra | Select-Object -Expand Parameters)['Type'].Attributes.ValidValues

Export default all users as well as default objects and settings
    # export default all users as well as default objects and settings
    Export-Entra -Path ‘C:\Backup\EntraBackup\YYYY-MM-DD' -Type "Config","Users"

Export applications only
    # export applications only
    Export-Entra -Path ‘C:\Backup\EntraBackup\YYYY-MM-DD' -Type "Applications"

Export B2C specific properties only
    # export B2C specific properties only
    Export-Entra -Path ‘C:\Backup\EntraBackup\YYYY-MM-DD' -Type "B2C"

Export B2B properties along with AD properties
    # export B2B properties along with AD properties
    Export-Entra -Path ‘C:\Backup\EntraBackup\YYYY-MM-DD' -Type "B2B","Config"


2.2 Recovery Capabilities 

      Backup actions
* Users
* Groups
o Dynamic and Assigned groups (incl. Members and Owners)
o Group Settings
* Devices
* External Identities
o Authorization Policy
o API Connectors
o User Flows
* Roles and Administrators
* Administrative Units
* Applications
o Enterprise Applications
o App Registrations
o Claims Mapping Policy
o Extension Properties
o Admin Consent Request Policy
o Permission Grant Policies
o Token Issuance Policies
o Token Lifetime Policies
* Identity Governance
o Entitlement Management
* Access Packages
* Catalogs
* Connected Organizations
o Access Reviews
o Privileged Identity Management
* Entra Roles
* Azure Resources
o Terms of Use
* Application Proxy
o Connectors and Connect Groups
o Agents and Agent Groups
o Published Resources
* Licenses
* Connect sync settings
* Custom domain names
* Company branding
o Profile Card Properties
* User settings
* Tenant Properties
o Technical contacts
* Security
o Conditional Access Policies
o Named Locations
o Authentication Methods Policies
o Identity Security Defaults Enforcement Policy
o Permission Grant Policies
* Tenant Policies and Settings
o Feature Rollout Policies
o Cross-tenant Access
o Activity Based Timeout Policies
* Hybrid Authentication
o Identity Providers
o Home Realm Discovery Policies
* B2C Settings
o B2C User Flows
* Identity Providers
* User Attribute Assignments
* API Connector Configuration
* Languages

3.0 List of Reference Links
Recoverability Best Practices
https://learn.microsoft.com/en-us/entra/architecture/recoverability-overview

EntraExporter (Entra Configuration Backup)
https://github.com/microsoft/entraexporter

Intune Backup (Intune Configuration Backup)
https://techcommunity.microsoft.com/t5/microsoft-intune/how-to-create-a-backup-of-your-microsoft-endpoint-manager-intune/m-p/2990308
https://techcommunity.microsoft.com/t5/microsoft-intune/how-to-create-a-backup-of-your-microsoft-endpoint-manager-intune/m-p/2990308

Compare Intune Backups
https://techcommunity.microsoft.com/t5/microsoft-intune/compare-and-restore-a-microsoft-endpoint-manager-intune-backup/m-p/2993736

Resilience in IAM
https://learn.microsoft.com/en-us/entra/architecture/resilience-overview

Backup Authentication
https://learn.microsoft.com/en-us/entra/architecture/backup-authentication-system

Entra Deployment Guidelines
https://learn.microsoft.com/en-us/entra/architecture/deployment-plans

Migration Best Practices
https://learn.microsoft.com/en-us/entra/architecture/migration-best-practices
