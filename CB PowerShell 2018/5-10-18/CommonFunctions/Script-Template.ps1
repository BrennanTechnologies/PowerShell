function Import-CommonFunction 
    {
    ### Reload Module at RunTime
    if(Get-Module -Name "CommonFunctions"){Remove-Module -Name "CommonFunctions"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking -Force
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CommonFunctions")){Write-Host "Loaded Custom Module: CommonFunctions" -ForegroundColor Green;Write-Host "Type Get-CBCommands (gcbc) to see commands`n" -ForegroundColor DarkGreen}
    if(!(Get-Module -Name "CommonFunctions")){Write-Host "The Custom Module CommonFunctions WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Do-Somthing
{

    Write-Host "Do Something"

}

function Execute-Script 
{
   
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-CommonFunctions 
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        Do-Something
    }

    END 
    {
        # Close Script
        #--------------------------
        Write-Log "`nRunning: END Block"  -ForegroundColor Blue
        Close-LogFile
        Measure-Script
        Stop-Transcribing
    }
}
Execute-Script