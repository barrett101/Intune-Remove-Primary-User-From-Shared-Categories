#Command Line Passed Variables
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string]$SharedCategoriesCSVFileName,
	[Parameter(Mandatory = $true)]
	[string]$WorkingFolder
)
Start-Transcript -Path "$WorkingFolder\PowerShellScript.log"
#
##
###
#START - Variables

#Generate a date for logs
$date = $(Get-Date -uformat "%Y/%m/%d %R")
$ChangeLog = "$WorkingFolder\ChangeLog.log"

#Shared Categories CSV Path 
$SharedDeviceCategoriesPath = "$WorkingFolder\$SharedCategoriesCSVFileName"

#END - Variables
###
##
#
Import-Module Microsoft.Graph.DeviceManagement
Connect-Mggraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
#
##
###
#START - Check For Shared Category and if so Remove Primary User
#Retrieving Shared Categories List from CSV
$SharedDeviceCategories = Import-Csv -Path $SharedDeviceCategoriesPath
#Retrieving Windows Devices Only from Intune
$listIntuneDevices = Get-MgDeviceManagementManagedDevice -All | Where-Object { ($_.OperatingSystem -match "Windows") }

#Goes through each of the Intune devices
foreach ($d in $listIntuneDevices)
{
	$DeviceID = $d.id
	$DeviceName = $d.DeviceName
	$deviceCategoryIntune = $d.DeviceCategoryDisplayName
	#Will only process the device if it has an Unknown category assigned
	If ($deviceCategoryIntune -ne "Unknown")
	{
		#Go through each of the categories mentioned in the CSV.
		foreach ($category in $SharedDeviceCategories)
		{
			If ($category.name -eq $deviceCategoryIntune)
			{
				$categoryMatched = $category.name
				Write-Host "$DeviceName - MATCH - Shared category $($category.name) matches the device $DeviceName category of $deviceCategoryIntune"
			}			
		}
		
		If ($CategoryMatched -ne $null)
		{
			#Retrieve the Primary user from the device
			$CheckPrimaryApiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID/users"
			$CheckPrimaryUser = Invoke-MgGraphRequest -Uri $CheckPrimaryApiUrl -Method GET -ContentType 'application/json'
			
			If ($CheckPrimaryUser.value.userPrincipalName -ne $null)
			{
				Write-Host "$DeviceName - CHANGED - $($CheckPrimaryUser.value.userPrincipalName) is assigned to device, will proceed to delete user from device."
				"$date - $DeviceName - $($CheckPrimaryUser.value.userPrincipalName) is assigned to device in shared category $categoryMatched, will proceed to delete user from device." | Out-File -FilePath $ChangeLog -Append
				#Proceed to delete the user in question
				Try
				{
					$DeletePrimaryUserApiUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices/$DeviceID/users/`$ref"
					Invoke-MgGraphRequest -Uri $DeletePrimaryUserApiUrl -Method Delete
				}
				Catch
				{
					Write-Host "$DeviceName - FAILED - $($CheckPrimaryUser.value.userPrincipalName) FAILED in removing the associated user."
					"$date - $DeviceName - $($CheckPrimaryUser.value.userPrincipalName) FAILED in removing the associated user from device" | Out-File -FilePath $ChangeLog -Append
				}
			}
		}		
	}
	#Ensures Variables are cleared
	$DeviceID = $null
	$DeviceName = $null
	$deviceCategoryIntune = $null
	$CheckPrimaryApiUrl = $null
	$CheckPrimaryUser = $null
	$DeletePrimaryUserApiUrl = $null
	$CategoryMatched = $null
}
#END - Check For Shared Category and if so Remove Primary User
###
##
#
Disconnect-MgGraph
Stop-Transcript
