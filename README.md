# Intune-Remove-Primary-User-From-Shared-Categories

This script was created to remove primary users from devices in Intune that are considered shared.  It requires that your shared devices be organized in specific device categories within Intune.  

**Reason for Creating Script**
The reason for creating this script is I found there was no great way to enroll Shared Hybrid Azure Joined windows devices into Intune automatically.  If you use the Group Policy setting "Enable Automatic MDM enrollment using default Azure AD credential" with "User Credential" option it will automatically enroll the device, but will assign the current logged in user (confirmed) or the next (I believe).  Once the group policy enrolls the device and the device is in the correct shared device category as defined in the CSV you can run this script to remove the primary user from the device(s).


**Description**

This script will perform the task of removing primary users from Windows based shared devices.  Shared devices shouldn't have users 
assigned to them.  This script reads from a CSV (Must be in UTF-8 format) that contains one header called "Name", and
below all the different shared device categories that you want no devices with user assigned to it.

**How to Run**

Place the script and CSV (saved as UTF-8) containing the shared categories into the same folder (ex. C:\PS\SharedCat).
When you run the script you will be asked to define the working folder (ex. C:\PS\SharedCat), and the filename of the
CSV file (ex. SharedCat.csv).

**How it Works**

1. It will take the shared categories that you defined in the CSV file and put then in a variable.
2. It will retrieve all the Intune Windows Devices Only.
3. It will then go through each device, if no category assigned it will no process any further, it
  the device is in a category it will check if it is assigned to one of the shared categories from the CSV,
  if a match is found it will then proceed to retrieve the primary user and if present it will remove the user from the device.
4. Check the log files PowerShellScript.log and ChangeLog.log in the folder to see what activity has taken place.
