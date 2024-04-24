function Import-CBrennanModule {
    ### Reload Module at RunTime
    if(Get-Module -Name "CBrennanModule"){Remove-Module -Name "CBrennanModule"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CBrennanModule")){write-host "Loading Custom Module: CBrennanModule" -ForegroundColor Green}
    if(!(Get-Module -Name "CBrennanModule")){write-host "The Custom Module CBrennanModule WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Throw-Errors
{
    $global:CMDs = @()
    $CMDs += "Bad-Command"
    $CMDs += "Get-ChildItem -Path 'z:\badDir' # -ErrorAction SilentlyContinue"
    $CMDs += write-log "test" "hjgh" -ForegroundColor cyan #-Quiet
    
    
    foreach ($Cmd in $Cmds)
    {
        try
        {
            #Create a failure
            Invoke-Expression $Cmd
        }
        catch
        {
            Trap-Error
        }
    }
}

function Execute-Script
{
    BEGIN {
         # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "Running BEGIN Block" -ForegroundColor Blue
        Import-CBrennanModule
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS {
        write-log "Running PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        Throw-Errors

}

    END {
        write-log "Running END Block"  -ForegroundColor Blue

        # Export Reports
        #--------------------------
        write-host $CMDs
        Export-Report-Console "Cmds" $Cmds
        #Export-Report-CSV
        #Export-Report-HTML
        #Export-Report-EMAIL 

        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing

    }
}

Execute-Script