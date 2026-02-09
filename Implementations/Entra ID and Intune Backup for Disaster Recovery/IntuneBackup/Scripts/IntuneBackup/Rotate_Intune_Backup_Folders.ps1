
#=============================================================================================================================
#
# Script Name:     Rotate_Intune_Backup_Folders.ps1
# Description:     Maintains a rolling set of dated backup folders under C:\Backup\IntuneBackup by deleting the oldest
#                  folder only when there are 7 or more subfolders. Folder names are expected to be date-based (e.g.,
#                  yyyy-MM-dd). The script normalizes names by removing dashes, compares numerically, and deletes the
#                  folder with the lowest resulting value.
# Notes:           • Set $rootFolder to the parent directory that contains your dated backup subfolders.
#                  • Assumes subfolder names are parseable as dates or integers once dashes are removed (e.g., "2026-02-09").
#                    Non-numeric folders are skipped with a warning and do not affect the rotation decision.
#                  • Deletion uses Remove-Item -Recurse -Force and is irreversible; test first with -WhatIf if desired.
#                  • The threshold is fixed at 7 subfolders (delete the single oldest when count >= 7). Adjust logic if you
#                    prefer to keep a different retention count or to delete until the count falls below the threshold.
#                  • Requires permissions to enumerate and delete directories within $rootFolder; run with appropriate rights.
#                  • Consider adding logging to a file if this is scheduled (e.g., via Task Scheduler) for audit/diagnostics.
#
#=============================================================================================================================

# Specify the folder path you want to scan (modify this path as needed)
$rootFolder = "C:\Backup\IntuneBackup"

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
