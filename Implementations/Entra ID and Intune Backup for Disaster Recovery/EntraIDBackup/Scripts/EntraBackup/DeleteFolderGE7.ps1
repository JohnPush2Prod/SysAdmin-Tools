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
