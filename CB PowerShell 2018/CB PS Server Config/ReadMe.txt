ABOUT THIS SCRIPT

I wrote this script from scratch on a new install of 2012 R2 Server in an Active Directory 2012 R2 Forest.

The script includes error checking, rror-checking/logging features, conditional logic functions, etc.

On a new Windows Server 2012 R2 Server this script performs all requested configuration seting without any errors.

No "red" custom eroor checking messages or PS Error console messages should appear.


Note:

I wrote this script using some Powershell 4.0  commands where available for 2012 R2.

In most of my scripts I also perform OS Detection and then do conditional logic to run specific commands appropriate for each OS.

i.e  	- PSCommandlets versions v2.0 vs vs 3.0 vs 4.0 vs 5.0
	- WMI  
	- NetSH and other commnd line utils 
	- etc.

For brevity & time, I did not do this in this script.



RUNNING THE SCRIPT:

The script can be run using the batch file "Run-Script.bat"

I wrote the script to accept a parameter file as a varaible, shown below.

However, in this demo I commented out the parameter and hard coded the parameterfile to make it easier to run.

For the demo, you can just run the script or the batch file.


WORKFLOWS:

This script optionally allows the use of PS WorkFlows.

This workflow process allows the script to perform the functions that require a reboot, such as (Rename-Computer, Windows Updates, etc) to run the function, then reboot and continue the workflow process and the rest of the script.


PARAMETER FILE:

This script requires one parameter and one file to be in the root file of the script:

For this demo, I also hard coded the parameter file into the script in order to make it easier to run.

Example:

<scriptName> <parameterFile>

C:\Scripts\Server_Configuration_Script3.ps1 Parameters.csv
