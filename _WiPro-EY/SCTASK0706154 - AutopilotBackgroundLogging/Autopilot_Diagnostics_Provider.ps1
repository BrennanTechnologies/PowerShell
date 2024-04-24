<#
Revision History
Version   Date        Developer               Description
1.0       2019.05.09  Jan Gutjahr             Initial version

<TODO: Update the Revision History table above>
<TODO: Generate a uniqe $EYScriptGUID value by running '[guid]::NewGuid()'>
<TODO: Set your own $EYFriendlyName value. This is usually the same as the name of the script itself>
<TODO: Add detailed information about the script and its purpose in this header section>
<TODO: Add your own logic by invoking it inside Invoke-EYMain() at the designated position>
<TODO: Use the function Write-EYTemplate as a simple example of how to create functions>
<TODO: Remove the Write-EYTemplate function when it's no longer required>
<TODO: Use 4 spaces as the default indentation :-) >
<TODO: Remove all the <TODO> lines :-) >

To rerun an Intune targeted PowerShell script on the client, the following options exist:
- uploading an updated version (file hash must be different) of this script in Intune will cause it to rerun on all targeted machines/users.
- delete the 'Result' key under HKLM\Software\Microsoft\IntuneManagementExtension\Policies\{GUID}\{GUID} on the client PC.
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
$EYFriendlyName = 'EYTemplate' #this value should ideally match the name of this PowerShell script file
$EYScriptGUID = 'e4176bb5-c5e4-4a1b-bb8f-4e05486a59f7' #[guid]::NewGuid() - GUID used to stamp the registry
$EYMarkerPath = "HKLM:\SOFTWARE\WOW6432Node\Ernst & Young\GlobalPackageID\{$EYScriptGUID}"

$EYScriptLogFile = "$EYScriptLogFolder\$EYFriendlyName-x64Is$EYBitness.log"

#################################################################################
#.SYNOPSIS
# Main entry point function
#
#.DESCRIPTION
# Serves as the main entry point in every .ps1 script. It is usually invoked
# at the bottom of a .ps1 script, wrapped inside a try/catch block.
#################################################################################
function Invoke-EYBase {
    [CmdletBinding()]
    param ()

    try {

        #create the log folder if it does not already exist. this is required because the start-transcript cmdlet will not create the folder.
        if (!(Test-Path $EYScriptLogFolder)) {
            New-Item -Path $EYScriptLogFolder -ItemType Directory -Force -Confirm:$false | Out-Null
        }

        Start-Transcript -Path "$EYScriptLogFile" -IncludeInvocationHeader -Append -Force | Out-Null

        $EYScriptExitCode = Invoke-EYMain

        #catch instances where no exit code was received. most likely points to a bug in the code
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
# This is the function that contains the main logic of the script
#
# All codepaths of this function should always Return or Write-Output an [Int] value.
# This value is what will be used as an exit code by the script.
#################################################################################
function Invoke-EYMain {
    [CmdletBinding()]
    param ()

    try {

        $EYFunctionExitCode = [Int]

        Write-Host ('*' * $EYSeparatorCharCount)
        Write-Host "Starting Script"
        Write-Host "Friendly Script Name: $EYFriendlyName"
        Write-Host "Script Name: $($MyInvocation.ScriptName)"
        Write-Host "Version: $EYScriptVersion"
        Write-Host "Is x64 process: $([System.Environment]::Is64BitProcess)"
        Write-Host ('*' * $EYSeparatorCharCount)

        if (Test-Path $EYMarkerPath) {
            Write-Host "This script has already been executed on this machine. Will rerun it anyway. Details: $EYMarkerPath"
        }
        else {
            Write-Host "This script has not yet been executed on this machine. Will now run it for the first time."
        }

        Write-Host ('-' * $EYSeparatorCharCount)

        #CODE GOES HERE (START)
        ##################################################

        #<TODO: replace the following line with your own code and logic>
        Write-EYTemplate -MyTestValue "my test value"

        ##################################################
        #CODE GOES HERE (END)

        Write-Host ('-' * $EYSeparatorCharCount)

        $EYFunctionExitCode = 18181
    }
    catch {
        Write-Host "An error occurred in $($MyInvocation.MyCommand.Name). $nl$_"
        Write-Error "Exception Details: $nl$_"
        $EYFunctionExitCode = 17171
    }
    finally {
        #create the reg marker to indicate that this script already ran on this pc. this has no real use in this sript, just doing it for additional information
        #we are in essence creating a legacy GlobalPackageID entry. Using the legacy format will have the benefit that SCCM will automatically include it in its inventory.
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
            if ($Key.GetValue($Name, $null) -ne $null) {
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
#.SYNOPSIS
# Sample function
#
#.DESCRIPTION
# Sample description of sample function
#################################################################################
function Write-EYTemplate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [String] $MyTestValue
    )

    Write-Host "Value passed into template function is: $MyTestValue"

}

#################################################################################
# Main
#################################################################################
Invoke-EYBase