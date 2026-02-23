Important Note: Cisco Secure Client Profile Editor - VPN will require a User Group to be configured when adding the Server List Entry. Add a blank space to the User Group field by pressing space bar and continue setup if you are using SSL and not setting up any User Groups in Meraki.

This deployment is using SAML for authentication. The VPN has already been fully set up and is able to connect via the FQDN or IP Address and manual client download. This guide is intended for use after this stage to help deploy the AnyConnect Client and configuration profiles through Intune to automate deployment. For overall VPN configurations See the ( VPN Config.png ) for an example.

For references please see ( Resource_Links.txt ).

---INSTRUCTIONS---
1.Navigate to the meraki portal. 
2.Access the VPN configuration via Security & SD-WAN \ Client VPN \ Cisco Secure Client Settings
3.Download the Secure Client and Secure Client Profile Editor ( See Client Download.png )
4.Navigate to the Server List section and click Add... to add a Server. 
5.Input your Display name "what the VPN connection displays as in the client"
6.Input your FQDN or IP Address 
7.Add a blank space to the User Group field by pressing space bar and continue setup if you are using SSL and not setting up any User Groups in Meraki. See (Client Profile Editor Config.png) for example.
8.Click OK , you will see the server is now listed in the server list
9.Once your done configuring any other settings you require click File at the top left of the Profile Editor.
10.Select save as and Save your .xml profile as a unique and identifiable name. 
11.Test your configuration by placing it in "C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile" and testing the connection.
12.You can choose to upload your profile to Meraki under Security & SD-WAN \ Client VPN \ Cisco Secure Client Settings \ 
Profile Update if you don't want to deploy the profile via Intune.
13.Unzip the cisco-secure-client-win-version-predeploy-k9 folder and drag the cisco-secure-client-win-5.1.12.146-core-vpn-predeploy-k9.msi to a new folder. 
14.Download the Install-CiscoSecureClient.ps1 from Github and place it in the new folder.
15.Add your .xml config file to the new empty folder. 
16.Run IntuneWinAppUtil.exe
17.specify the source folder: "path to new folder"
18.specify the setup file: "Install-CiscoSecureClient.ps1"
19.specify the output folder: Another folder of your choice for output 
20.You should now see the .intunewin file in the output folder
21.Navigate to the Intune portal and go to Apps \ Windows \ +Create
22.Select app type as Windows app (Win32)
23.Upload the .intunewin file and add a description 
24.Set the install command as powershell.exe -ExecutionPolicy Bypass -File Install-CiscoSecureClient.ps1
25.Set the uninstall command as msiexec.exe /x {0FDE8E49-56B7-411F-96C5-DAA064E59F60} /qn /norestart
26.Use Orca from Windows SDK or run the Get GUIDProductCode from the MSI Property table.ps1 script located in 27.SysAdmin-27.Tools/PowerShell Scripts to double check the GUID
28.For the Detection Rule type select file
29.Path: C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile
30.File: The name of your .xml
31.Detection method: File exists
32.This will make sure the user has the configuration and also has any connect installed since that config will not be in the profile folder if AnyConnect was not installed successfully. 
33.Deploy to a group or all users or make the app available for install through the company portal
34.Test the installation before mass deployment.

