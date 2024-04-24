### FUNCTION to Detect OS Version
function Get-OSVersion
{
    BEGIN
    {
        $script:FunctionName = $MyInvocation.MyCommand.name #Get the name of the currently executing function
    
    $Parameters = @{
        ExpectedOSVersion = $ExpectedOSVersion
    }

    }

    PROCESS
    {
        $script:CustomErrMsg = "Custom Error Msg: Error Getting OS Version"
    
        # Setup the ScriptBlock to execute with the Try/Catch function.
        $ScriptBlock = 
        {
            write-log "Checking OS Version" Green
            write-log "Expected OS Version $Parameters.ExpectedOSVersion" -ForegroundColor Blue 
            exit

            ### Option 1: Using WMI to get OS Version
            [string]$CurrentOSVersion = (Get-CimInstance Win32_OperatingSystem).version

            ### Option 2: Using Environment to get OS Version
            #$OSVersion = [environment]::OSVersion.Version 

            ### Compare Current OS Version
            if ($CurrentOSVersion -eq $ExpectedOSVersion)
            {
                Write-Host "The Current OS Version & The Expected OS Version are the same."
                Write-host "The Current OS Version is: $CurrentOSVersion " 
                Write-host "The Expected OS Version is: $ExpectedOSVersion" 
            }
            else
            {
                Write-host "The current OS Version is not the expected OS Version."
                Write-host "The Current OS Version is: $CurrentOSVersion " 
                Write-host "The Expected OS Version is: $ExpectedOSVersion" 
                Ask-ContinueScript
            }
        }
    
        Try-Catch $ScriptBlock
    }        
    END
    {
        #Remove-Variable -scope local #clear function varables w/ local scope
    }
}
### END FUNCTION -  Get-OSVersion

Start-LogFiles
Get-OSVersion