cls

function Install-Features($FeatureName)
{
    <#
        ### This function installs windows features
        ### Processes
            1. Check Feature Availability
            2. Check if Frature is installed
            3. Install Feature
            4. Verify Feature Install
    #>



    function Pause-Script ($message)
    {
        # Check if running Powershell ISE
        if ($psISE)
        {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show("$message")
        }
        else
        {
            Write-Host "$message" -ForegroundColor Yellow
            $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }

    function Check-FeatureState()
    {
        ### Check Feature Install State"
        ### States - Available
        ###        - Installed
        ###        - UnAvailable $Null

        if ($Feature.InstallState -eq "Available") 
        {
            write-host "Feature is Available. Proceeding to Install: " $Feature.name
            Pause-Script "Proceeding to Install Feature. `n 
            Press any key to continue"
            Add-WindowsFeature -name $Feature.name
        }
        elseif ($Feature.InstallState -eq "Installed")
        {
            write-host "The Feature is already Installed. Do you want to uninstall?"
    
            ### Prompt user to Pause the Script

            $ReadHost = Read-Host "Continue? [y/n]"
            $ReadHost = $ReadHost.ToUpper()

            while($ReadHost -ne "y")
            {
                if ($ReadHost -eq 'n') 
                {
                    write-host "No"
                    exit
                }
                $ReadHost = Read-Host "Continue? [y/n]"
            }
            Uninstall-WindowsFeature -Name GPMC
        
        }
    }

    ### Check Feature Avaiablility"
    function Check-FeatureAvailability()
    {
        $Feature = Get-WindowsFeature -name $Parameters.FeatureName

        if ($Feature -eq $Null)
        {
            write-host "This Feature does not Exits: " 
            $Parameters.FeatureName
        }
        elseif ($Feature -ne $Null)
        {
            write-host "Feature is Available. Proceeding to Check Installation State"
            Check-FeatureState
        }
    }

    function Verify-FeatureStatus()
    {
        $Feature = Get-WindowsFeature -name $Parameters.FeatureName
    
        if($Feature.Installed -eq "Installed")
        {
            write-host "Feature is Installed: "  -ForegroundColor Cyan
            $Feature.name 
            $Feature.Installed 
        }
        elseif($Feature.Installed -ne "Installed")
        {
            write-host "Feature not Installed: " -ForegroundColor Cyan
            $Feature.name 
            $Feature.Installed
        }
    }

    Check-FeatureAvailability
    Verify-FeatureStatus

}


$FeatureName = "GPMC"
Install-Features $FeatureName