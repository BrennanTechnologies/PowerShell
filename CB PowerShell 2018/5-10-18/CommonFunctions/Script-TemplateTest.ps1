function Import-CommonFunctions 
{
    ### Reload Module at RunTime
    if(Get-Module -Name "CommonFunctions"){Remove-Module -Name "CommonFunctions"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\CommonFunctions\CommonFunctions.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CommonFunctions")){Write-Host "Loading Custom Module: CommonFunctions" -ForegroundColor Green}
    if(!(Get-Module -Name "CommonFunctions")){Write-Host "The Custom Module CommonFunctions WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Throw-Errors 
{
    $CMDs = @()
    #$CMDs += "Bad-Command"
    #$CMDs += "Test-Command"
    #$CMDs += "Get-ChildItem -Path 'z:\BadDir' # -ErrorAction SilentlyContinue"
    $CMDs += Write-Log "Date: `t" (Get-Date) -ForegroundColor cyan #-Quiet

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

function Test-TryCatch
{
    PROCESS
    {
        $ErrorActionPreference = "Stop"
        ##### Setup the scriptblock to execute with the Try/Catch function.
        $ScriptBlock = 
        {
            Throw "Terminating Error"
            #Write-Error "Declare a non-terminating error"


        }

        Try-Catch $ScriptBlock
    }
}

function Do-Something1
{
    ### Create Report Array
    $Report = @()

    ### Create Report Name
    $script:ReportName = ($MyInvocation.MyCommand).Name

    ### Custom Function
    $SearchBase = "OU=Users,OU=Hong Kong,DC=eci,DC=corp"
    #$SearchBase = "OU=Users,OU=edlcap,OU=Clients,DC=ecicloud,DC=com"
    $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""

    foreach ($User in $Users)
    {

        # Build-Report
        #------------------------------
        $Hash = [ordered]@{            
            User       = $User.Name
            Department = $User.Department
        }                           
        $PSObject      = New-Object PSObject -Property $Hash
        $Report       += $PSObject 
        $global:Report = $Report # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
    }
}

function Do-Something2
{
    ### Create Report Array
    $Report = @()

    ### Create Report Name
    $script:ReportName = ($MyInvocation.MyCommand).Name

    $Services = Get-Service | Where-Object {$_.Name -like "A*"}

    foreach ($Service in $Services)
    {

        # Build Report
        #------------------------------
        $Hash = [ordered]@{            
            User        = $Service.Name
            DisplayName = $Service.DisplayName
            Status      = $Service.Status
        }                           
        
        # Build-Report
        $PSObject      = New-Object PSObject -Property $Hash
        $Report       += $PSObject 
        $global:Report = $Report # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
    }

        Export-Report-Console -ReportName $ReportName -Report $Report

        ### Export Report:
        ### Example Usage: Export-Report -ReportName $ReportName -Report $Report -Console -CSV -HTML -Email
        ### ----------------------------------------------------------------------------------------
        #Export-Report -ReportName "Chris" -Report $Report -Console #-CSV #-HTML #-Email
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
        #Start-Transcribing 
        Start-LogFiles
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        #Throw-Errors
        #Do-Something1
        #Do-Something2
        Test-TryCatch
    }
    END
    {
        # Export Reports
        #--------------------------
        #Export-Report-Console -ReportName $ReportName -Report $Report
        #Export-Report-CSV -ReportName $ReportName -Report $Report
        #Export-Report-HTML -ReportName $ReportName -Report $Report
        #Export-Report-EMAIL -ReportName $ReportName -Report $Report -From "cbrennan@eci.com" -To "cbrennan@eci.com"  

        # Close Script
        #--------------------------
        Close-LogFile -Quiet
        Measure-Script
        #Stop-Transcribing
    }
}
Execute-Script