
cls

function Import-CBrennanModule 
{
    ### Reload Module at RunTime
    if(Get-Module -Name "CommonFunctions"){Remove-Module -Name "CommonFunctions"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking -force
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CommonFunctions")){Write-Host "Loading Custom Module: CommonFunctions" -ForegroundColor Green}
    if(!(Get-Module -Name "CommonFunctions")){Write-Host "The Custom Module CommonFunctions WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

Import-CBrennanModule 

$Version = (Get-Module -Name CommonFunctions).Version
write-host "Module Version: " $Version

$CompanyName = (Get-Module -Name CommonFunctions).CompanyName
write-host "CompanyName: " $CompanyName

get-module -list Microsoft.PowerShell.Management

$module = Get-Module -Name CommonFunctions
$module.Version