cls
$NewDriveLetter = "F:"

#$drive = Get-WmiObject -Class win32_volume -Filter "DriveLetter = 'e:'"
#Set-WmiInstance -input $drive -Arguments @{DriveLetter="Q:"; Label="Label"}

### Get the Current CD-ROM Letter & Volume
$CurrentCDLetter = (Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:computername).Drive

write-host "The current CD-ROM Drive Letter is: $CurrentCDLetter"
$CDVolume = Get-WmiObject -Class Win32_Volume -ComputerName $env:computername -Filter "DriveLetter='$CurrentCDLetter'" -ErrorAction Stop            
    

### Change the CD-ROM Letter
Set-WmiInstance -InputObject $CDVolume -Arguments @{DriveLetter=$NewDriveLetter}

    
### Display New CD-ROM Letter
$CurrentCDLetter = (Get-WMIObject -Class Win32_CDROMDrive -ComputerName $env:computername).Drive
write-host "The new CD-ROM Drive Letter is: $CurrentCDLetter"
            
     