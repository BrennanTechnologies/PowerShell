
This script requires one parameter $ParameterFile

Require Parameter File

c:\script\$ParameterFile

The example file I am using is:
Parameters.txt


About this Script
This script was built and tested it on a brand new install of 2012 R2 Server.

It performs each of the requested configurations requested without error.

I wrote this script using a custome temple I wrote that contains a library of standard function that I wrote and use regularly.

The my template includes error checking and error loggin features.

I purposelt wrote thhis script using ONLY PowerShell 3.0 commandlets with 2012 R2 server. Usually I write scripts to check the OS Version and then execute each command using the appropriate methods

i.e.
netsh
Wmi
etc.
	
Conditional logic to test if settings are currrently set

