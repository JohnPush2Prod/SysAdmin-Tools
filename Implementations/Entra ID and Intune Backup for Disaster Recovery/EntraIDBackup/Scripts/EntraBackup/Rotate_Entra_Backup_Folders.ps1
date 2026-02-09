#=============================================================================================================================
#
# Script Name:     Rotate_Entra_Backup_Folders.ps1
#
# Description:     Maintains a rolling set of dated Entra backup folders under C:\Backup\EntraBackup by automatically
#                  deleting the oldest folder once the total number of subfolders reaches 7 or more. Folder names are
#                  expected to follow a date-based format (e.g., yyyy-MM-dd). Dashes are removed and compared numerically
#                  to determine the oldest backup.
#
# Notes:           • Update $rootFolder if your Entra backup directory is stored elsewhere.
#                  • Only folders whose names convert to valid integers (after removing "-") are considered. Invalid folder
#                    names are skipped with a warning and do not affect deletion logic.
#                  • When 7+ folders exist, the script deletes exactly one folder—the lowest numeric value interpreted as
#                    the oldest backup.
#                  • Deletion is permanent via Remove-Item -Recurse -Force. Add -WhatIf during testing to avoid accidental
#                    removal.
#                  • Ensure script runs with permissions to enumerate and delete subfolders under $rootFolder.
#                  • Ideal for scheduled maintenance (Task Scheduler, automation accounts, server cleanup).
#
#=============================================================================================================================

# Specify the folder path you want to scan (modify this path as needed)
$rootFolder = "C:\Backup\EntraBackup"

# Get all the subfolders in the root folder
$folders = Get-ChildItem -Path $rootFolder -Directory

# Check if there are 7 or more subfolders
if ($folders.Count -ge 7) {
    # Initialize variables to store the lowest folder and its number
    $lowestFolder = $null
    $lowestNumber = [Int32]::MaxValue

    # Loop through each folder and check its name (assuming all names are valid integers)
    foreach ($folder in $folders) {
        try {
            # Remove any dashes from the folder name
            $cleanedName = $folder.Name -replace '-', ''

            # Convert cleaned folder name to an integer
            $folderNumber = [int]$cleanedName

            # Compare the current folder number with the lowest
            if ($folderNumber -lt $lowestNumber) {
                $lowestNumber = $folderNumber
                $lowestFolder = $folder
            }
        } catch {
            Write-Warning "Skipping folder '$($folder.Name)': Not a valid number."
        }
    }

    # If a lowest folder is found, delete it
    if ($lowestFolder -ne $null) {
        Write-Host "Deleting folder with the lowest number: $($lowestFolder.FullName)"
        Remove-Item -Path $lowestFolder.FullName -Recurse -Force
        Write-Host "Folder deleted."
    } else {
        Write-Host "No valid folder found to delete."
    }
} else {
    Write-Host "There are less than 7 subfolders. No action taken."
}
