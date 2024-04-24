<#
finish script that looks for client ad accounts without a last name 

get all mailboxes in ecilcoud.com/clients ou with linked master account 
get-aduser on linked master account 
check linked master account has first name , lastname email populated 
create report on that.


This is the basics of the script:

$array = @()
$problems = @()

$clientMailboxes = Get-Mailbox -OrganizationalUnit "ecicloud.com/clients" -ResultSize unlimited

foreach($mailbox in $clientMailboxes)
{
if($mailbox.linkedMasterAccount)
{
$adAccount = Get-ADUser -Server $mailbox.linkedmasteraccount.split("\")[0] -Identity $mailbox.linkedmasteraccount.split("\")[1] -Properties EmailAddress
if($? -eq $false)
{

}#if it fails, record problem, continue
if(!$adAccount.GivenName)
{

}#find accounts w/o first name
if(!$adAccount.Surname)
{

}#find accounts w/o last name
if(!$adAccount.EmailAddress)
{

}#find accounts w/o first name

}#if there's a linked master account then look for the first name, last name, and mail address in the client's domain
else
{
continue
}#no linked master account? skip because we're not capturing this right now
}#loop through each mailbox, if there's a linked master account, look to see if the client's first name, last name, and email address attributes from their domain exist on the ad object
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

function Export-Report-Console
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


function Measure-Script
{
    ### Calculates Script Execution Time

    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    write-host `n`n
    write-log "Script ended at $StopTime" white
    write-log "Script Execution Time: $ElapsedTime" white
}

function Import-ExchangeSession
{
    ### Check for Existing Session
    $ExchangeSession = Get-PSSession | where { $_.ConfigurationName -eq "Microsoft.Exchange"  -and $_.State -eq 'Opened' }

    if (-not $ExchangeSession) 
    {
        write-host "Creating New Session"    
        ### Create Session to Import Exchange Tools
        $ExchangeCAS = (HostName).split("-")[0] + "-htcas01.ecicloud.com"
        $ExchangeSession = New-PSSession -Name ExchangeSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeCAS/PowerShell/ -Authentication Kerberos
            
        Import-PSSession $ExchangeSession -AllowClobber #-ea "silentlycontinue"  
    }
    else
    {
        write-host "Using Current Session: " $ExchangeSession 
    }
}


function Get-Mailbox_LinkedMasterAccounts
{
    ### Create/Clear the Arrays
    $Report                       = @()
    $script:ClientMailBoxes       = @()
    $script:NoLinkedMasterAccount = @()
    $script:ADErrors              = @()
    
    ### Get the MailBoxes
    #$SearchOU = "ecicloud.com/clients" 
    $SearchOU = "ecicloud.com/clients/Samco" 
    #$SearchOU = "ecicloud.com/Clients/SchoenerMgmt"

    write-host "Getting mailboxes for`t:" $SearchOU -ForegroundColor Yellow
    $ClientMailBoxes = Get-Mailbox -OrganizationalUnit $SearchOU -ResultSize unlimited | `
        Where-Object { `
             ($_.LinkedMasterAccount -notlike "NT AUTHORITY*") `
        -AND ($_.LinkedMasterAccount -notlike "ECICLOUD\Domain Controllers") `
        -AND ($_.LinkedMasterAccount -notlike "S-1-*") `
        -AND ($_.LinkedMasterAccount -like "S*") }| `
        Sort-Object -Property OrganizationalUnit
    
    
    foreach($MailBox in $ClientMailBoxes)
    {
        #write-host "Name: "$MailBox.Name -ForegroundColor Magenta
        #write-host "LinkedMasterAccount: "$MailBox.LinkedMasterAccount -ForegroundColor Magenta

        ### Check if a Linked Master Account exists, if it exists then lookup the users UPN in the client domain.
        if ($MailBox.LinkedMasterAccount)
        {
            write-host "Getting AD User Account for Mailbox: " $MailBox.LinkedMasterAccount -ForegroundColor Cyan

            $Domain    = $MailBox.LinkedMasterAccount.split("\")[0]
            $UserName  = $MailBox.LinkedMasterAccount.split("\")[1]
        
            try
            {
                ### Get-ADUser - Specify PDCEmulator - Takes Longer to run
                #$PDC = (Get-ADDomain -Identity $Domain | Select-Object -Property PDCEmulator).PDCEmulator
                #$ADAccount = Get-ADUser -Server $PDC -Identity $UserName -ErrorAction silentlycontinue

                ### Get-ADUser - Use NetBios Name for Domain
                $script:ADAccount = Get-ADUser -Server $Domain -Identity $UserName -Properties * -ErrorAction silentlycontinue -ErrorVariable ErrorVar

                if($ErrorVar)
                {
                    write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue$ad
                    write-error $ErrorVar
                }
            }
            catch
            {
                write-host "Error Finding AD User Account for Mailbox`t: $MailBox.LinkedMasterAccount" -ForegroundColor white
                write-log $Error[0] yellow
            }
            
            ####################################
            # Check Required AD Attributes
            ####################################

            $ADAttributes  = @()
            $ADAttributes += "Name"
            $ADAttributes += "SamAccountName"
            $ADAttributes += "GivenName"
            $ADAttributes += "Surname"
            $ADAttributes += "EmailAddress"
            
            ### Build Hash Table        
            $hash = [ordered]@{
                Search_OU = $SearchOU.split("/")[-1]
                Name =  $ADAccount.Name
                SamAccountName =  $ADAccount.SamAccountName
                GivenName =  $ADAccount.GivenName
                Surname =  $ADAccount.Surname
                EmailAddress =  $ADAccount.EmailAddress
            } 

            foreach($ADAttribute in $ADAttributes)
            {
                ### Get AD Value
                $ADValue = $ADAccount.$ADAttribute
                write-host "$ADAttribute : $ADValue" -ForegroundColor Green
                ### Add to Hash Table 
                #$Hash.Add($Search_OU, ($SearchOU.split("/")[-1]))
                #$Hash.Add($ADAttribute, $ADValue)
                #$PSObject  =  New-Object PSObject -Property $Hash
                
                if(!$ADValue)
                {
                    write-host "Missing Attribute: $ADAttribute" -ForegroundColor Red
                    #$Hash.Add($ADAttribute, $ADValue)
                    $PSObject  =  New-Object PSObject -Property $Hash
                    Continue
                }
            }
            $script:ADErrors += $PSObject 
        }

        elseif(-not($MailBox.LinkedMasterAccount))
        {
            write-host "LinkedMasterAccount DOES NOT Exists" $MailBox.DisplayName -ForegroundColor Red
            
            ############################
            # Build Hash Table
            ############################

            $hash = [ordered]@{            
                Client_UPN         = $ClientUPN            
                MailBox_Name       = $MailBox.Name   
                MailBox_DisplayName = $MailBox.DisplayName         
                DistinguishedName  = $MailBox.DistinguishedName            

            }                           
            $PSObject =  New-Object PSObject -Property $hash
            $NoLinkedMasterAccount   += $PSObject 
            Continue
        }
    }

    # Output Results
    $script:NoLinkedMasterAccount_Total = $NoLinkedMasterAccount.count
    $script:ADErrors_Total = $ADErrors.count
    write-host "Accounts w/o LinkedMasterAccount: " $NoLinkedMasterAccount_Total
    write-host "Accounts missing AD Attributes: "$ADErrors_Total

    write-host "REPORT: No Linked Master Accounts" -ForegroundColor Yellow
    $NoLinkedMasterAccount  | FT -AutoSize
    
    write-host "REPORT: AD Accounts Missing Attributes" -ForegroundColor Yellow
    $ADErrors | FT -AutoSize
}



############################
# Execute the Script
############################

function Execute-MainScript
{
Begin {
        Start-Script
        Clear-Host
        Start-LogFiles
        Import-ExchangeSession
    }

    Process {

        Get-Mailbox_LinkedMasterAccounts
    }

    End {
        #Export-Report-Console
        #Export-Report-CSV
        #Export-Report-GroupBy
        #Export-Report-HTML
        #Email-Report
        #Measure-Script
    }
}

Execute-MainScript