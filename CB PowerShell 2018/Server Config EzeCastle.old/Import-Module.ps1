cls
#Import-Module

$Parameters = @{
    FeatureName = "GPMC"
    ModuleName  = "GroupPolicy"
}

#Get-WindowsFeature -name $Parameters.FeatureName

#sGet-WindowsFeature | Get-Member

### Check if Feature is Installed

$Feature = Get-WindowsFeature -name $Parameters.FeatureName
$Feature | get-member
$Feature.name
$Feature.displayname
$Feature.InstallState

if ($Feature.InstallState -eq "Available") 
{
    write-host "Feature is Avaiable. Installing $Feature.name"

    Add-WindowsFeature -name $Feature.name

    ### fcn Check Feature
    # Check Module
    #Import Module
}
else
{
    $Status = $Parameters.FeatureName + "Feature not Avaiable" 
    Ask-ExitScript
}    

exit
    ### Import Module
    Import-Module -name $Parameters.ModuleName


## Verify Feature is installed
write-host "`n`nVerifying Feature"
$Verify = Get-WindowsFeature -name $Parameters.FeatureName
write-host "Name: " $Verify.Name 
write-host "Installed: " $Verify.Installed

if($Verify.Installed -eq $false)
 {
    write-host "Feature Install Failed Verifictions"
 }
else
{
    write-host "Feature Install Verified Successfully"    
}
exit

Get-Module -ListAvailable | where {$_.name -like '*Active*'}

        
Get-Module -ListAvailable -Name GroupPolicy
Get-Module -ListAvailable -Name $Parameters.ModuleName

## Check for Module
if (Get-Module -ListAvailable -Name $Parameters.ModuleName)
{
}



## Test Module
Get-Command -Module$Parameters.ModuleName

