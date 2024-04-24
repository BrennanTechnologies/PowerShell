<#
    This script checks the ADFS Certificates for ....?
#>

function Start-Script
{
    #################################
    # Setup Constancts and Variables
    #################################

    # Get Start Time for Measure-Script function
    $script:StartTime = Get-Date

    # Get the scripts current filename & directory
    $script:ScriptFileName  = split-path $MyInvocation.PSCommandPath -Leaf
    $script:ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent

    ### Set Debugging
    #Set-StrictMode -Version 2.0
    Set-PSDebug -Strict # [-Off ][-Trace <Int32>] [-Step] [-Strict]
   
    ### Set Error Action
    $ErrorActionPreference =  "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
    #$ErrorActionPreference = “SilentlyContinue”
    #$ErrorActionPreference = "Continue"
    #$ErrorActionPreference =  "Inquire"
    #$ErrorActionPreference =  "Ignore"
    #$ErrorActionPreference = "Suspend"
}

function Write-Log($string,$color) 
{
    ### Write Error-Trap messages to the console & the log file.
    if ($color -eq $null) {$color = "magenta"}
    write-host $string -foregroundcolor $color
    "`n`n"  | out-file -filepath $ErrorLogFile -append
    $string | out-file -filepath $ErrorLogFile -append
}

function Start-LogFiles
{
    ### Create & Start the Custom Error Log Files & Transcript Log File
    
    # Format the LogFile Timestamp
    $script:TimeStamp    = Get-Date -format "MM_dd_yyyy_hhmmss"
   
    # Create the Log Folder.
    $script:LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}

    # Create the Report Folder.
    $script:ReportPath = $ScriptPath + "\Reports" 
    if(!(Test-Path -Path $ReportPath)) {New-Item -ItemType directory -Path $ReportPath | out-null}
     
    # Create Custom Error Log File
    $ErrorLogName = "ErrorLog_" + $TimeStamp + ".log"
    $script:ErrorLogFile = $LogPath + "\" + $ErrorLogName
    $script:StartTime = Get-Date
    Write-Log "*** OPENING LOG FILES at: $StartTime ***" white

    # Create Transcript Log File
    if ($Host.Name -eq "ConsoleHost")
    {
        write-log "Starting Transcript log $TranscriptLogFile "
        $TranscriptLogName = "TranscriptLog_" + $TimeStamp + ".log"
        $TranscriptLogFile = $LogPath + "\" + $TranscriptLogName
        start-transcript -path $TranscriptLogFile
    }
    else
    {
        write-log "TRANSCRIPT LOG: Script is running from the ISE.. No Transcript Log will be generated" magenta
    }
}

function Measure-Script
{
    ### Calculates Script Execution Time

    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    write-host `n`n
    write-log "Script ended at $StopTime" white
    write-log "Script Execution Time: $ElapsedTime" white
}


function Set-PSCredentials
{
    $UserName = "cbrennan@eciadmin.onmicrosoft.com"
    
    $PasswordFile = $ScriptPath + "\Password.txt"
    write-host "Password File: $PasswordFile" -ForegroundColor Cyan

    if(-not (Test-Path $PasswordFile))
    {
        Read-Host "Enter Password for Azure To Bed Encrypted" -AsSecureString |  ConvertFrom-SecureString | Out-File $PasswordFile
        write-host "Created Encrypted Password File: " $PasswordFile -ForegroundColor Green
    }
    elseif(Test-Path $PasswordFile)
    {
        write-host "Using Existing Password File: " $PasswordFile -ForegroundColor Green
    }

    $script:PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $PasswordFile | ConvertTo-SecureString)
    #PSCredentials

}

function Export-Report-ToConsole
{
    ############################
    # Export Report to Console
    ############################
    write-host "`n`nReport:" -ForegroundColor Yellow
    $Report | Format-Table -AutoSize
}

function Export-Report-CSV
{
    ############################
    # Export TXT/CSV Report
    ############################
    $ReportName = $ScriptFileName
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".txt"
    $Report | Export-Csv -Path $ReportFile -NoTypeInformation 
    start-process $ReportFile
}


function Export-Report-HTML
{
    ############################
    # Export HTML Report
    ############################

    # HTML Header
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:10;font-color: #000000;text-align:center;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"

    $ReportName = $ScriptFileName
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".html"
    
    $PreContent = "Report Name: $ReportName Report Date: $ReportDate"

    #$Post = "Total Mailboxes Checked: ($ClientMailBoxes).count"
    $PostContent = "Mailboxes without Linked Master Accounts: $NoLinkedMasterAccount_Total"
    $Report |  ConvertTo-HTML -Head $Header -PreContent $PreContent -PostContent $PostContent | Out-File $ReportFile
    #$Report |  ConvertTo-HTML -Head $Header| Out-File $ReportFile
    start-process $ReportFile
}

function Email-Report
{
    ############################
    # Email Report
    ############################

    # Email Parameter Constants
    $From = "cbrennan@eci.com"
    $To   = "cbrennan@eci.com"
    #$CC   = "sdesimone@eci.com"
    $SMTP = "qts-outlook.ecicloud.com"

    # Email Parameter Variables
    $EmailParams = @{

                From       = $From
                To         = $To 
                #CC         = $CC
                SMTPServer = $SMTP
                }

    # HTML Header
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:10;font-color: #000000;text-align:center;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    # Send Email Report
    $ReportName = $ScriptFileName
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $PreContent = "Report Name: $ReportName Report Date: $ReportDate"
    $PostContent = "Mailboxes without Linked Master Accounts: $NoLinkedMasterAccount_Total"
    $Body = $Report | ConvertTo-Html -Head $Header -PreContent $PreContent -PostContent $PostContent
    Send-MailMessage @EmailParams -Body ($Body | Out-String) -BodyAsHtml -Subject "$ReportName - $ReportDate"
}

function Check-ADFSCerts
{
    ### Connect to Azure
    write-host "Connecting to Azure" -ForegroundColor Cyan
    try{
        Connect-MsolService -Credential $PSCredentials
    }
    catch
    {
        write-Log "The following error occured: " Yellow
        write-Log $Error[0] Yellow
        Write-Log $Error[0].ScriptStackTrace Red
    }
    
    ### Get Tenants
    write-host "Getting Tenants" -ForegroundColor Cyan
    try
    {
        $Tenants = Get-MsolPartnerContract -All
    }
    catch
    {
        write-Log "The following error occured: " Yellow
        write-Log $Error[0] Yellow
        Write-Log $Error[0].ScriptStackTrace Red
    }
    write-host "Getting Tenant Domains" -ForegroundColor Cyan

    ### Clear the report array
    $script:Report = @()

    ############################################################################
    ### Get the ADFS Settings/Properties for the ROOT Domains for each Tenant
    ############################################################################

    foreach ($Tenant in $Tenants)
    {
        $Domains = Get-MsolDomain -TenantId $Tenant.TenantID | Where-Object {$_.authentication -eq “Federated”}
       
        foreach ($Domain in $Domains)
        {
            ### Get the ROOT Domain Name
            $DomainName = $Domain.Name
            $RootDomainName = $DomainName.split(".")[-2] + "." + $DomainName.split(".")[-1]
            try
            {
                ### Get Federation Properties (settings for both Azure Active Directory and the Active Directory Federation Services server)
                #Set-MsolADFSContext -Computer $DomainName
                #Get-FederationEndpoint -domain $DomainName
                #$FSDomainProperies =  Get-MsolFederationProperty -DomainName $RootDomainName


                ### Get Federation Settings (key settings for a federated domain from Azure Active Directory)
                $FSDomainSettings = Get-MsolDomainFederationSettings -DomainName $RootDomainName -TenantId $Tenant.TenantID -ErrorAction Stop -ErrorVariable ErrorVar
                if($ErrorVar)
                {
                    write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue
                    write-error $ErrorVar
                }
                write-host $Domain.Name -ForegroundColor Blue
            }
            catch
            {
                Write-Host $Domain.Name -ForegroundColor Red
                write-Log "The following error occured: " Yellow
                write-Log $Error[0] Yellow
                Write-Log $Error[0].ScriptStackTrace Red
            }

                [string]$SigningCertificate     = $FSDomainSettings.SigningCertificate
                [string]$NextSigningCertificate = $FSDomainSettings.NextSigningCertificate
                
                $Compare = $Null

                if ($NextSigningCertificate)
                {
                    $Status = $True
                    if($NextSigningCertificate -eq $SigningCertificate)
                    {
                        $Compare = $True
                    }
                    elseif ($NextSigningCertificate -ne $SigningCertificate)
                    {
                        $Compare = $True
                    }
                }
                elseif (-not($NextSigningCertificate))
                {
                    $Status = $False
                }

                write-host "Status: $Status"
                write-host "Compare: $Compare"

            ############################
            # Build Hash Table
            ############################

            $hash = [ordered]@{            
                DomainName              = $Domain.Name 
                TenantID                = $Tenant.TenantID 
                NextCertStatus          = $Status
                PassiveLogOnUri         = $FSDomainSettings.PassiveLogOnUri
                SigningCertificate      = $FSDomainSettings.SigningCertificate         
                NextSiginingCertificate = $FSDomainSettings.NextSigningCertificate         
            }
            
            ### Build the Object Array
            $PSObject       = New-Object PSObject -Property $hash
            $script:Report += $PSObject  
        }
    }
}

function Execute-MainScript
{
Begin {
        Start-Script
        Clear-Host
        Start-LogFiles
        Set-PSCredentials
    }

    Process {

        Check-ADFSCerts
    }

    End {
        Export-Report-ToConsole
        Export-Report-CSV
        Export-Report-HTML
        #Email-Report
        Measure-Script
    }
}

Execute-MainScript

<#

### hybrid alert script for adfs certificate expiration key signing

Connect-Msolservice 
$tenantids=Get-msolpartnercontract 
$domainstocheck=@()
Foreach($tenantid in $tenantids)
{
	$domains=Get-msoldomain -tenantid $tenantid.tenantid | where-object {$_.authentication  -eq “Federated”}
	
	foreach($domain in $domains)
	{
		$fedsettings=get-msoldomainfederationsettings -domainname $domain.name -tenantid $tenantid.tenantid
		$object = New-Object –TypeName PSObject
		$object | Add-Member –MemberType NoteProperty –Name Tenantid –Value $tenantid.tenantid
		$object | Add-Member –MemberType NoteProperty –Name domainname –Value $domain.name
		$object | Add-Member –MemberType NoteProperty –Name FederationServer –Value $fedsettings.PassiveLogOnUri
		$object | Add-Member –MemberType NoteProperty –Name SigningCertificate –Value $fedsettings.SigningCertificate
		$object | Add-Member –MemberType NoteProperty –Name NextSiginingCertificate –Value $fedsettings.NextSigningCertificate 
		$domainstocheck+=$object		
		clear-variable fedsettings
		
	}

}

#>