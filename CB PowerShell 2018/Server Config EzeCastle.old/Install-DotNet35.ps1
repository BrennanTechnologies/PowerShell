
### Install .NET Frmework 3.5 Features 
$Features = "Add-WindowsFeature NET-Framework-Core"
write-host "Installing NET Framework 3.5 Features"
#Invoke-Expression -command $Features

### Checking Status of Feature Installation 
$Features  = @()
$Features += "NET-Framework-Features"
$Features += "NET-Framework-Core"

write-host "`n"
Write-Host "Checking Status of Feature Installation" 
foreach ($Feature in $Features)
{
    $FeatureStatus = Get-WindowsFeature -name $Feature
    $FeatureStatus = $FeatureStatus.Installed
    write-host "$Feature is installed? $FeatureStatus" 
}



