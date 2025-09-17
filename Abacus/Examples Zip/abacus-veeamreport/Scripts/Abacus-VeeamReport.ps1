<#
.SYNOPSIS
Generate and email a report of Servers without Veeam Restore Points.

.DESCRIPTION
Generate and email a report of Servers without Veeam Restore Points.

.PARAMETER VMNameFilter
Filter used by Get-VM -Name $vmNameFilter.

.PARAMETER IncludeTagCategory
[array]  -- Array of Server Tag Assignments to Include.

.PARAMETER ExcludeTagName
[array] -- ### Array of Server Tag Assignments to Exclude.

.PARAMETER RequiredModule
[array] -- Required PS Modules.

.PARAMETER SnapIns
[array] -- Required SnapIn name.

.PARAMETER ServerRecordAge
# of Days until servers show up in the report.

.PARAMETER VBRServer
Veeam Backup & Restore Server to connect to.

.PARAMETER ServiceAccount
The Active Directory service account used to connect to vCenter and Veeam VBR

.PARAMETER DeveloperMode
Sets developer level settings for testing and debugging.

.EXAMPLE
Abacus-VeeamReport.ps1 -VMNameFilter @("*FS0*","*ZDB*") -IncludeTagCategory @("*") -ExcludeTagCategory @("BK_EXEMPT") -DeveloperMode $false


#>
[CmdletBinding()]
Param(

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [array]$VMNameFilter = @("*FS0*","*ZDB*","*SQL*","TXDC*DC01*","L1DC*DC01*") # <--- Default Production Report 
    ,
    [Parameter(Mandatory = $false)]
    [array]$IncludeTagCategory = @("*")
    ,
    [Parameter(Mandatory = $false)]
    [array]$ExcludeTagName = @("BK_EXEMPT")
    ,   
    [Parameter(Mandatory = $false)]
    [array]$SnapIns = @("VeeamPSSnapin")
    ,
    [Parameter(Mandatory = $false)]
    [string]$VBRServer = "nymgmt-vem01.management.corp"
    ,
    [Parameter(Mandatory = $false)]
    [int]$ServerRecordAge = 5
    ,
    [Parameter(Mandatory = $false)]
    [array]$RequiredModules = @("Abacus-VeeamReport","Abacus-SQL")
    ,
    [Parameter(Mandatory = $false)]
    [string]$ServiceAccount = "srv-devopsveeam"
    ,
    [Parameter(Mandatory = $false)]
    [string]$DeveloperMode = $true
  )
& {
    Begin {
        $global:ScriptStartTime = Get-Date
        
        ### Database Connection
        ###-----------------------------------------
        $global:ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"

        ### Set DeveloperMode
        ###-----------------------------------------
        $global:DeveloperMode = $true                                                  ### <--- Manually Set the Scope of the Variable
        Write-Host "DeveloperMode : " $DeveloperMode -ForegroundColor Yellow

        if($DeveloperMode -eq $false){
            [array]$VMNameFilter = @("*FS0*","*ZDB*","*SQL*","TXDC*DC01*","L1DC*DC01*") ### <--- Default Production Report 
        }
        elseif($DeveloperMode -eq $true){
            try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch {$null}
            Start-Transcript -Path ($PSScriptRoot + "\logs\VeeamReport-Transcript.txt") -Force 

            ###--------------------------------------------
            ### Target VM's For Testing:
            ###--------------------------------------------
            [array]$VMNameFilter = @("*FS0*","*ZDB*","*SQL*","TXDC*DC01*","L1DC*DC01*") ### <--- Default Production Report 
            #[array]$vmNameFilter = @("SFDC-CAVFS01")
            #[array]$vmNameFilter = @("phdevsql01")
            #[array]$vmNameFilter = @("*FS0*","*ZDB*")
            #[array]$vmNameFilter = @("TXDC-*DC01*")
            #[array]$vmNameFilter = @("TXDC-A*DC01*","CB")
            #[array]$vmNameFilter = @("TXDC-AA*DC01*")
            #[array]$vmNameFilter = @("TXDC-AALDC01")
            #[array]$vmNameFilter = @("*SFS01*"
            #[array]$vmNameFilter = @("*ADFS02*","*BFNDC*","NYDC-JNEFS01","NYCL-EMPFS01")
            ###--------------------------------------------
        }

        ### Import Required Modules.
        ###------------------------------------------------
        foreach($RequiredModule in $RequiredModules){
            try {
                if( [bool](Get-Module -Name $RequiredModule -ListAvailable) -eq $true ){
                    Import-Module -Name $RequiredModule -Force
                }    
                else {
                    Write-Error -Message "Required Module $RequiredModule isnt available." 
                }
            }
            catch {
                Write-Warning -Message ("ERROR Importing required module: $RequiredModule" + $global:Error[0].Exception.Message) -ErrorAction Stop
                Exit
            }
        }
        ### Add Snapins
        ###---------------------------------------------
        Add-PSSnapin -Name VeeamPSSnapin
        ### Get Credentials from Secret Server
        ###---------------------------------------------
        [PSCredential]$Credentials = Get-Secret -SecretName $ServiceAccount | Convert-secretToKerb -domain Management -prefix
        ### Connect to the Veeam VBR Server.
        ###------------------------------------------------       
        Connect-ABAVBRServer -VBRServer $VBRServer -ServiceAccount $ServiceAccount -Credentials $Credentials
        ### Connect to the vCenters.
        ###------------------------------------------------
        #Connect-ABAVIServer -All -Credentials $Credentials ### <-- from Abacus-vmWare module.
        Connect-ABAvCenters                                 ### <-- Being used For Testing vCenter Connectivity Issues.
        exit
    }

    Process {
        ### Get Server Tag Assignments from VMWare.
        ###------------------------------------------------
        $ServerParams = @{
            VMNameFilter       = $VMNameFilter
            IncludeTagCategory = $IncludeTagCategory 
            ExcludeTagName     = $ExcludeTagName
            ServerRecordAge    = $ServerRecordAge
        }
        [PSCustomObject]$ServerTags = Get-ServerTagAssignments @ServerParams
        ### if Has Matching Tags: -->  Get Restore Points & Send Report
        ###------------------------------------------------
        if ( $null -ne $ServerTags ){
            ### Get Restore Points from Veeam.
            ###------------------------------------------------
            [PSCustomObject]$VeeamRestorePoints = Get-VeeamRestorePoints -ServerTags $ServerTags
            ### Get Target Servers without Restore Points.
            ###------------------------------------------------
            [PSCustomObject]$TargetServers = Get-TargetServers -VeeamRestorePoints $VeeamRestorePoints
            ### Get Server Record from SQL
            ###------------------------------------------------
            [PSCustomObject]$Report = Get-ServersForReport -TargetServers $TargetServers -ServerRecordAge $ServerParams.ServerRecordAge
            ### Send Email Report.
            ###------------------------------------------------
            Send-EmailReport @ServerParams -Report $Report
        }
        else {
            ### No matching Tags: --> Send Report & End.
            ###------------------------------------------------
            Write-Log -LogString "No servers have matching tags. Sending notification." -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor Cyan
            $Report = New-Object PSObject -Property @{ Message = ( "No servers found with tags matching filters: " + $includeTagCategory.ToUpper() + " and " + $excludeTagName.ToUpper() )}
            Send-EmailReport @ServerParams -Report $Report
        }
    }
    End {
        Disconnect-VBRServer
        if($DeveloperMode -eq $false){
            $global:DefaultVIServers | foreach-Object { Disconnect-VIServer -Server $_.Name -Confirm:$false }
        }
        Write-Log -LogString "End Script." -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkCyan
        Write-Host "Script Run Time:" ($(Get-Date) - $ScriptStartTime)
        try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch {$null}
    }
}