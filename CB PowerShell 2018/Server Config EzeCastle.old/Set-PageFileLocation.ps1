cls


### Get Current PageFile Loction
$CurrentPageFileLocation =  Get-WMIObject -Class Win32_PageFileUsage  -ComputerName $env:computername 
$CurrentPageFileLocation = $CurrentPageFileLocation.Name
Write-Host "The current PageFile is $CurrentPageFileLocation"

#$CurrentPageFileLocation | get-member

### Disable Automatic PageFile Settings

#$computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
#$computersys.AutomaticManagedPagefile = $False
#$computersys.Put()


### Delete Current PageFile
#$CurrentPageFileLocation.Delete()

#$pagefile = Get-WMIObject -Query "Select * From Win32_PageFileSetting" #Where Name = $CurrentPageFileLocation"
#$pagefile.Delete()
#$pagefile

### Create New PageFile
#Set-WMIInstance -class Win32_PageFileSetting -Arguments @{name="d:\pagefile.sys";InitialSize = 4096;MaximumSize = 4096}



$PageFile = Get-WMIObject -ComputerName $env:computername  -Class Win32_PageFileSetting
$PageFile | get-member


