<#
Revision History
Version   Date          Developer            Description
1.0       2023.02.7    Arun Prabakaran      Initial version to set the Language for Non-unicode programs.

This script will set the Language for Non-unicode programs of countries identified and agreed by EY.
All the remaining region/country will have default as per Windows Operating System settings.
It will only be deployed to autopilot machines.
The script will check for registry entry & will not rerun if there is an existing registry entry for this script under GlobalPackage ID.

Steps to update the script for additional location identified and agreed by EY.
1. Update the revision history
2. To update the script for additional country add elseif in "function Config-Region" with country GeoID.
Switch($GeoInfo.GeoId) 
        {
        {$_ -eq 39} {Write-host "The selected Non-Unicode Language is en-CA";Set-WinSystemLocale en-CA}
        {$_ -eq 84} {Write-host "The selected Non-Unicode Language is fr-FR";Set-WinSystemLocale fr-FR}
        {$_ -eq 94} {Write-host "The selected Non-Unicode Language is de-DE";Set-WinSystemLocale de-DE}
        {$_ -eq 122} {Write-host "The selected Non-Unicode Language is ja-JP";Set-WinSystemLocale ja-JP}
        {$_ -eq 241} {Write-host "The selected Non-Unicode Language is uk-UA";Set-WinSystemLocale uk-UA}
        {$_ -eq 11} {Write-host "The selected Non-Unicode Language is es-AR";Set-WinSystemLocale es-AR}
        {$_ -eq 12} {Write-host "The selected Non-Unicode Language is en-AU";Set-WinSystemLocale en-AU}
        {$_ -eq 67} {Write-host "The selected Non-Unicode Language is ar-EG";Set-WinSystemLocale ar-EG}
        {$_ -eq 56} {Write-host "The selected Non-Unicode Language is es-MX";Set-WinSystemLocale es-MX}
        {$_ -eq 32} {Write-host "The selected Non-Unicode Language is pt-BR";Set-WinSystemLocale pt-BR}
}
3. Below documents can be used to find the country specific Geo ID & paired regional locale:
   Geo ID - https://docs.microsoft.com/en-us/windows/win32/intl/table-of-geographical-locations?redirectedfrom=MSDN
   In the above MS document check for "Geographical location identifier (decimal)" to get the Geo ID of the selected region/country
   You can also select the desired location from settings & use "Get-WinHomeLocation" command to get the Geo ID of the selected location.
   eg: GeoId HomeLocation 
       ----- ------------ 
         244 United States

While configuring in Intune select below setting & should be targeted to the device group:
Run this script using the logged-on credentials - No
Enforce script signature check                  - No
Run script in 64 bit PowerShell Host            - Yes

To rerun an Intune targeted PowerShell script on the client, the following options exist:
- uploading an updated version (file hash must be different) of this script in Intune will cause it to rerun on all targeted machines/users.
- delete the 'Result' key under HKLM\SOFTWARE\WOW6432Node\Ernst & Young\GlobalPackageID\{GUID} on the client PC.
  the {GUID} values should be visible in the script log file under c:\Maintenance\Logs\MDM
Then either reboot the machine or simply restart the 'Microsoft Intune Management Extension' service.
#>

#Common script level variables
$EYScriptVersion = '1.0'
$EYSeparatorCharCount = 60
$nl = [Environment]::NewLine
$EYScriptExitCode = [Int]
$EYBitness = [System.Environment]::Is64BitProcess
$EYScriptLogFolder = "c:\Maintenance\Logs\MDM"
$EYMarkerAppNamePrefix = "MDM-" #this value will be prefixed to the GlobalPackageID ApplicationName value. This may then be used to easily identify these entries for reporting purposes.

#Common script level variables that must be set to unique values if this script is to be used multiple times to set settings for let's say OneDrive,Office,EYKeys etc.
$EYFriendlyName = 'EYRegionConfiguration' #this value should ideally match the name of this PowerShell script file
$EYScriptGUID = '95dfa176-669e-4b11-a2c0-ff746e248b45' #[guid]::NewGuid() - GUID used to stamp the registry
$EYMarkerPath = "HKLM:\SOFTWARE\WOW6432Node\Ernst & Young\GlobalPackageID\{$EYScriptGUID}"
$EYScriptLogFile = "$EYScriptLogFolder\$EYFriendlyName-x64Is$EYBitness.log"

#################################################################################
#.SYNOPSIS
# Main entry point function
#
#.DESCRIPTION
# Serves as the main entry point in every .ps1 script. It is usually invoked
# At the bottom of a .ps1 script, wrapped inside a try/catch block.
#################################################################################
function Invoke-EYBase {
    [CmdletBinding()]
    param ()

    try {

        #Create the log folder if it does not already exist. This is required because the start-transcript cmdlet will not create the folder.
        if (!(Test-Path $EYScriptLogFolder)) {
            New-Item -Path $EYScriptLogFolder -ItemType Directory -Force -Confirm:$false | Out-Null
        }

        Start-Transcript -Path "$EYScriptLogFile" -IncludeInvocationHeader -Append -Force | Out-Null

        $EYScriptExitCode = Invoke-EYMain
        $EYScriptExitCode
        #Catch instances where no exit code was received. Most likely points to a bug in the code.
        if ($EYScriptExitCode -isnot [Int]) {
            throw '$EYScriptExitCode' + " variable was not set to a number. Value was '$($EYScriptExitCode)'"
        }
        elseif ($EYScriptExitCode -eq 18181) {
            Write-Host "The Script finished with the special 18181 success return code."
        }

    }
    catch {
        Write-Error "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        $EYScriptExitCode = 16161 #unhandled, unexpected error
    }
    finally {
        Write-Host "About to exit the script with exit code $($EYScriptExitCode)"
        Stop-Transcript -ErrorAction Continue | Out-Null
        Exit $EYScriptExitCode
    }
}

#################################################################################
#.SYNOPSIS
# Main logic for this script
#
#.DESCRIPTION
# This is the function that contains the main logic of the script.
# All code paths of this function should always Return or Write-Output an [Int] value.
# This value is what will be used as an exit code by the script.
#################################################################################
function Invoke-EYMain {
    [CmdletBinding()]
    param ()

    try {
        $EYFunctionExitCode = [Int]
        $EYCreateMarker = $true
        $defaultUser0Name = 'defaultuser0'
        $currentlyLoggedInUser = Get-LoggedInUser #Get the logged in username.

        Write-Host ('*' * $EYSeparatorCharCount)
        Write-Host "Starting Script"
        Write-Host "Friendly Script Name: $EYFriendlyName"
        Write-Host "Script Name: $($MyInvocation.ScriptName)"
        Write-Host "Version: $EYScriptVersion"
        Write-Host "Is x64 process: $([System.Environment]::Is64BitProcess)"
        Write-Host ('*' * $EYSeparatorCharCount)
        Write-Host "The current logged in user is '$currentlyLoggedInUser'."
             
        if (Test-Path $EYMarkerPath) {
            Write-Host "This script has already been executed on this machine. The script will not do anything and exit now. Details: $EYMarkerPath"
        }
        else {
            Write-Host "This script has not yet been executed on this machine, will now run it for the first time."
            Write-Host "The script will now validate if this is an Autopilot computer."

            #Allow to run only on autopilot computer.
            if (-not ($env:COMPUTERNAME -like 'XW*')) {
                Write-Host "This computer is not an autopilot enrolled device. The script will not do anything and exit now."
                return 18181
            }
            
            Write-Host "This computer is an autopilot enrolled device, hence the script will now check the region selected."
            Write-Host ('-' * $EYSeparatorCharCount)
            
            #make sure we only run this script if the logged in user is 'defaultuser0'
            if ($currentlyLoggedInUser -ieq $defaultUser0Name) {
                Write-Host "The currently logged in user is '$currentlyLoggedInUser'. The script will try to set the Regional Format and Language for non-Unicode Programs selected Region."
                Write-Host ('-' * $EYSeparatorCharCount)

                #CODE GOES HERE (START)
                ##################################################

                Config-Region | out-null

                ##################################################
                #CODE GOES HERE (END)
                Write-Host ('-' * $EYSeparatorCharCount)
            }
            else {
                Write-Host "The currently logged in user is not '$defaultUser0Name'. The script will not do anything and exit now."
            }
        }
        $EYFunctionExitCode = 18181
    }
    catch {
        Write-Host "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        Write-Error "Exception Details: $nl$_"
        $EYFunctionExitCode = 17171
    }
    finally {
        #Create the reg marker to indicate that this script already ran on this pc. This has no real use in this script, just doing it for additional information
        #We are in essence creating a legacy GlobalPackageID entry. Using the legacy format will have the benefit that SCCM will automatically include it in its inventory.
        Write-Host "Creating the marker entry in $EYMarkerPath"
        $Now = Get-Date
        New-Item -Path $EYMarkerPath -Force | Out-Null #NOTE: This command will completely purge any existing values and subkeys in the specified key
        New-ItemProperty -Path $EYMarkerPath -Name "ApplicationName" -Value "$EYMarkerAppNamePrefix$EYFriendlyName" -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "ApplicationVersion" -Value $EYScriptVersion -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "GlobPackIDVal1" -Value $EYFunctionExitCode -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "InstallDate" -Value (Get-Date $Now -Format "yyyyMMdd") -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "InstallTimeLocal" -Value (Get-Date $Now -Format "HHmmss") -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "InstallTimeUTC" -Value $Now.ToUniversalTime().ToString("HHmmss") -PropertyType STRING -Force | Out-Null
        New-ItemProperty -Path $EYMarkerPath -Name "ScriptVersion" -Value $EYScriptVersion -PropertyType STRING -Force | Out-Null
        Write-Host "Exiting Invoke-EYMain with exit code $EYFunctionExitCode"
        Write-Host ('*' * $EYSeparatorCharCount)
    }
    Return $EYFunctionExitCode
}

#################################################################################
#.Synopsis  
#This function will check for the region selected and configure Language for Non-unicode programs.
#
#.DESCRIPTION
#Config-Region will help you identify the current selected country (Get-WinHomeLocation).
#This function will set the  Language for Non-unicode programs.
#################################################################################
function Config-Region {
    [CmdletBinding()]
    param ()
    Try {

        ### Get the current Windows location
        $GeoInfo = Get-WinHomeLocation

        Write-Host "The current Windows location is '$($GeoInfo.HomeLocation)' & the Geo ID is '$($GeoInfo.GeoId)'."
        Write-Host "Going to set respective System Locale and Culture"
        
        ### Set the System Locale and Culture
        Switch ($GeoInfo.GeoId) {
            { $_ -eq 39 } {
                Write-host "The selected Non-Unicode Language is en-CA";
                Set-WinSystemLocale en-CA
            }
            { $_ -eq 84 } {
                Write-host "The selected Non-Unicode Language is fr-FR";
                Set-WinSystemLocale fr-FR
            }
            
            { $_ -eq 94 } {
                Write-host "The selected Non-Unicode Language is de-DE"; 
                Set-WinSystemLocale de-DE 
            }

            { $_ -eq 122 } 
            { Write-host "The selected Non-Unicode Language is ja-JP"; Set-WinSystemLocale ja-JP }
            
            { $_ -eq 241 } { Write-host "The selected Non-Unicode Language is uk-UA"; Set-WinSystemLocale uk-UA }
            { $_ -eq 11 } { Write-host "The selected Non-Unicode Language is es-AR"; Set-WinSystemLocale es-AR }
            { $_ -eq 12 } { Write-host "The selected Non-Unicode Language is en-AU"; Set-WinSystemLocale en-AU }
            { $_ -eq 67 } { Write-host "The selected Non-Unicode Language is ar-EG"; Set-WinSystemLocale ar-EG }
            { $_ -eq 56 } { Write-host "The selected Non-Unicode Language is es-MX"; Set-WinSystemLocale es-MX }
            { $_ -eq 32 } { Write-host "The selected Non-Unicode Language is pt-BR"; Set-WinSystemLocale pt-BR }
        }
    }
    catch {
        Write-Error "Something went wrong while executing Config-Registry function. Exception caught."
        Write-Error "Exception Details: $nl$_"
        Write-Host "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        throw
    }
}


#################################################################################
#.SYNOPSIS
# Return the name of the currently logged in user
#
#.DESCRIPTION
# During the ESP device phase, this will return 'defaultuser0'
# When a user is logged in, for 'CH\guj' it would return 'guj'
# If no user is currently logged in it will return an empty string ''
#################################################################################
function Get-LoggedInUser {
    [CmdletBinding()]
    param ()

    try {
        $loggedInUser = Get-WmiObject Win32_ComputerSystem | Select-Object username
        Write-Host "User value detected is '$loggedInUser'"
        if (($null -eq $loggedInUser) -or ($loggedInUser -eq '')) {
            Write-Host "No currently logged in user could be detected."
            $loggedInUser = [string]''
        }
        else {
            $loggedInUser = [string]$loggedInUser
            $loggedInUser = $loggedInUser.split("=")
            $loggedInUser = $loggedInUser[1]
            $loggedInUser = $loggedInUser.split("}")
            $LoggedInUser = $LoggedInUser[0]
            $loggedInUser = $loggedInUser.split("\")
            $loggedInUser = $loggedInUser[1]
        }
        Write-Host "Currently logged in user is '$loggedInUser'."
    }
    catch {
        Write-Error "Something went wrong. Exception caught."
        Write-Error "Exception Details: $nl$_"
        Write-Host "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        throw
    }
    Return $loggedInUser
}

#################################################################################
#.SYNOPSIS
# Checks if a registry value exists and return boolean to indicate result.
# Will also return true if the value exists but is empty.
#
#.DESCRIPTION
# https://stackoverflow.com/questions/5648931/test-if-registry-value-exists
#################################################################################
Function Test-RegistryValue {
    param(
        [Alias("PSPath")]
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String]$Path,
        [Parameter(Position = 1, Mandatory = $true)]
        [String]$Name
    )
    process {
        if (Test-Path $Path) {
            $Key = Get-Item -LiteralPath $Path
            if ($null -ne $Key.GetValue($Name, $null)) {
                Write-Host "Key '$Path\$Name' with value '$($Key.GetValue($Name, $null))' was detected"
                $true
            }
            else {
                Write-Host "Path '$Path' exists, but Key '$Name' does not exist"
                $false
            }
        }
        else {
            Write-Host "Path '$Path' does not exist"
            $false
        }
    }
}

#################################################################################
# Main
#################################################################################
Invoke-EYBase