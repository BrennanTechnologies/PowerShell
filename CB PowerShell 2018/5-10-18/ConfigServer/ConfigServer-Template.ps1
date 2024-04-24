function Import-Modules 
{
    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$ModulePath = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$ModulePath = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$ModulePath = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\"}
    if($env:COMPUTERNAME  -eq "W2K16V2")      {$ModulePath = "\\tsclient\Z\CBrennanScripts\Modules\"}
    if($env:COMPUTERNAME  -eq "BLU-SRVTEST01")      {$ModulePath = "\\tsclient\Z\CBrennanScripts\Modules\"}

    $Modules = @()
    $Modules += "CommonFunctions"
    $Modules += "ConfigServer"

    foreach ($Module in $Modules)
    {
        ### Reload Module at RunTime
        if(Get-Module -Name $Module){Remove-Module -Name $Module}

        ### Import the Module
        $ModuleFilePath = $ModulePath + $Module + "\" + $Module + ".psm1"
        Import-Module -Name $ModuleFilePath -DisableNameChecking #-Verbose

        ### Test the Module - Exit Script on Failure
        if( (Get-Module -Name $Module)){Write-Host "Loaded Custom Module: $Module" -ForegroundColor Green}
        if(!(Get-Module -Name $Module)){Write-Host "The Custom Module $Module WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
    }
}

function Set-ServerBuildParameters
{
    ### Server Specific Parameters
    $global:ServerBuildType    = "2016_Std"
    $global:NewComputerName    = "BLU-SRVTEST01"
    $global:NewIPv4Address     = "10.61.1.111"
    $global:NewDefaultGateway  = "10.61.1.250"
    $global:NewPrefixLength    = "24"
    $global:NewPrimaryDNS      = "10.61.1.1"
    $global:NewSecondaryDNS    = "10.61.1.2"
    $global:NewDomainv         = "ECILAB"
}

function Get-TargetInfo
{

    $VMName = (Get-CIMInstance CIM_ComputerSystem).Name
    
    $VMIPv4Address = ""



}
function Execute-Script 
{
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-Modules 
        #Start-Transcribing 
        Start-LogFiles
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        
        Set-ServerBuildParameters
        Set-ServerBuildType $ServerBuildType
        Build-Server

    }

    END 
    {
        # Close Script
        #--------------------------
        Write-Log "`nRunning: END Block"  -ForegroundColor Blue
        #Close-LogFile -Quiet
        Measure-Script
        #Stop-Transcribing
    }
}
Execute-Script