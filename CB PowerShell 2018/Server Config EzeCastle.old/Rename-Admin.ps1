cls

$OldAdminName = "Administrator"
$NewAdminName = "AdminLocal"

### Check if Old Name exists

$User= Get-WmiObject -Class Win32_UserAccount -Filter  "LocalAccount='True'" | Where {$_.Name -eq $OldAdminName}

if ($User -eq $Null)
{
    write-host "User Does Not Exist"
    #Pause-Script
}
elseif ($User -ne $Null)
{
    write-host "User Does Exist"
    $user.Rename($NewAdminName) | Out-Null
    
    ### Check New User Name
    $User= Get-WmiObject -Class Win32_UserAccount -Filter  "LocalAccount='True'" | Where {$_.Name -eq $NewAdminName}
    $User.Name
}


<#
### Use PowerShell 5.1 Command
#Rename-LocalUser -Name $OldAdminName -NewName $NewAdminName

### Use WMI Command
$user = Get-WMIObject Win32_UserAccount -Filter "Name='$OldAdminName'"
$result = $user.Rename($NewAdminName)

if ($result.ReturnValue -eq 0) {
return $user
# you may just print a message here
}

#>