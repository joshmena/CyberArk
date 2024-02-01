###########################################################################
#
# NAME: PsPAS Copy Module
#
# AUTHOR:  Josh Mena
#
# COMMENT: 
# This script will check if the required module is installed in the user profile. 
# If not installed it will copy it. 
#
# SUPPORTED VERSIONS:
# CyberArk PVWA v12.6 and above
# 
# Script Version = "2"
#
###########################################################################
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process


$spath = "L:\EUC\PAM\Scripts\Modules\"
$upath = "$env:USERPROFILE\Documents\WindowsPowerShell\"



# Define the parent folder path where you want to check for folders containing "4"
$parentFolderPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\psPAS"

# Get all folders inside the parent folder
$folders = Get-ChildItem -Path $parentFolderPath -Directory

# Loop through each folder and check if its name contains "4"
foreach ($folder in $folders) {
    if ($folder.Name -match "4") {
        # If the folder name contains "4", delete the folder
        Write-Host "Deleting folder $($folder.FullName)..."
        Remove-Item -Path $folder.FullName -Force -Recurse
    }
}

Write-Host "Folder deletion completed."


Copy-Item $spath -Destination $upath -Recurse -Force
Get-Module -ListAvailable psPAS
Import-Module psPAS

Get-ChildItem "L:\EUC\PAM\Scripts\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item  