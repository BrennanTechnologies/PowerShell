cls

# PowerShell Script to set the size of pagefile.sys

#$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges;
#$computersys

#$computersys.AutomaticManagedPagefile = $False;
#$computersys.Put();
$pagefile = 
Get-WmiObject -Query "Select * From Win32_PageFileSetting Where Name like '%pagefile.sys'";
$pagefile 

#$pagefile.InitialSize = <New_Value_For_Size_In_MB>;
#$pagefile.MaximumSize = <New_Value_For_Size_In_MB>;
#$pagefile.Put();