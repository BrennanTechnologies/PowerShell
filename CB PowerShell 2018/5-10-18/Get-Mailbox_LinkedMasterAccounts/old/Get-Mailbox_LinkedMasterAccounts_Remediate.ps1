<#
    This script will find all mailboxes with Linked Master Accounts that do not have the user’s UPN from their AD Object in the client’s domain
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
    $LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}
     
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

function Export-Report-CSV
{
    ############################
    # Export TXT/CSV Report
    ############################
    $ReportName = $ScriptFileName
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $LogPath + "\" + "Report" + $ReportName + "_" + $ReportDate + ".txt"
    $Report | Export-Csv -Path $ReportFile -NoTypeInformation 
    start-process $ReportFile
}


function Export-Report-GroupBy
{
    ############################
    # Export GroupBy Report
    ############################
    $ReportName = $ScriptFileName
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $LogPath + "\" + "GroupBy" + $ReportName + "_" + $ReportDate + ".txt"
    $GroupBy.Group | Export-Csv -Path $ReportFile -NoTypeInformation 
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
    $ReportFile = $LogPath + "\" + "Report" + $ReportName + "_" + $ReportDate + ".html"
    
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
    ### Create &  Clear the Arrays
    $Report = @()
    $script:ClientMailBoxes = @()
    $NoLinkedMasterAccount = @()
    $UserError = @()
    
    ### Get the MailBoxes
    #$SearchOU = "ecicloud.com/clients/Samco" 
    #$SearchOU = "ecicloud.com/clients" 
    $SearchOU = "ecicloud.com/Clients/SchoenerMgmt"

    write-host "Getting mailboxes for`t:" $SearchOU -ForegroundColor Yellow
    $ClientMailBoxes = Get-Mailbox -OrganizationalUnit $SearchOU -ResultSize unlimited | `
        Where-Object { `
             ($_.LinkedMasterAccount -notlike "NT AUTHORITY*") `
        -AND ($_.LinkedMasterAccount -notlike "ECICLOUD\Domain Controllers") `
        -AND ($_.LinkedMasterAccount -notlike "S-1-*") } |`
        Sort-Object -Property OrganizationalUnit


    foreach($MailBox in $ClientMailBoxes)
    {
        ### Check if a Linked Master Account exists, if it exists then lookup the users UPN in the client domain.
        if ($MailBox.LinkedMasterAccount)
        {
            write-host "Getting AD User Account for Mailbox`t: " $MailBox.LinkedMasterAccount -ForegroundColor Cyan

            $Domain    = $MailBox.LinkedMasterAccount.split("\")[0]
            $UserName  = $MailBox.LinkedMasterAccount.split("\")[1]
        
            try
            {
                ### Use NetBios Name for Domain
                $ADAccount = Get-ADUser -Server $Domain -Identity $UserName -ErrorAction silentlycontinue
                
                ### Specify PDCEmulator - Takes Longer to run
                #$PDC = (Get-ADDomain -Identity $Domain | Select-Object -Property PDCEmulator).PDCEmulator
                #$ADAccount = Get-ADUser -Server $PDC -Identity $UserName -ErrorAction silentlycontinue

            }
            catch
            {
                write-host "Error Finding AD User Account for Mailbox`t: $MailBox.LinkedMasterAccount" -ForegroundColor white
                write-log $Error[0] yellow
            }

            ### Test to see if the UPN exists in the Mailbox Aliases
            if(-not($MailBox.EmailAddresses -match $ADAccount.UserPrincipalName))
            {
                ### Alert on mailbox
                write-host "There is no matching UPN for mailbox for`t:" $MailBox.LinkedMasterAccount -ForegroundColor Red
                $NoLinkedMasterAccount += $MailBox.LinkedMasterAccount

                ### Get Mailbox Data
                $ClientOU = $MailBox.DistinguishedName.Split(",")[2].split("=")[1]
                $ClientUPN = $MailBox.EmailAddresses | Where-Object {$_ -match "SMTP:"}
                $ClientUPN = $ClientUPN.split(":")[1]

                
                ############################
                # Build Hash Table
                ############################

                $hash = [ordered]@{            
                    AD_OU                   = $ClientOU
                    AD_UserPrincipalName    = $ADAccount.UserPrincipalName
                    EX_MailBox_EmailAddress = $MailBox.EmailAddresses
                    EX_MailBox_Name         = $MailBox.Name            
                    EX_DistinguishedName    = $MailBox.DistinguishedName            
                    EX_Client_UPN           = $ClientUPN            
                }                           
                $PSObject =  New-Object PSObject -Property $hash
                $Report   += $PSObject 
                $script:Report = $Report
            }
            else
            {
                write-host "Match - UPN for acccount $Username is`t:" $ADAccount.UserPrincipalName -ForegroundColor Green 
            }
        }
        else
        {
            write-host "This Mailbox Does NOT have A Linked Master Account`t:" $MailBox.DisplayName  -ForegroundColor Yellow
            Continue
        }
    }

    ### Write Report to Console
    write-host "Writing Report(s): "  -ForegroundColor Cyan

    $GroupBy = $Report | Group-Object -Property $ClientOU
    $GroupBy = $GroupBy.Group
    
    $GroupBy | FT -AutoSize

    foreach($Group in $GroupBy)
    {
        #$Group.Client_OU
        #$Group.MailBox_Name
        #$Group.DistinguishedName
        #$Group.Client_UPN   
    }
    write-host "Count:" $GroupBy.Count
    
    # Output Results
    $script:NoLinkedMasterAccount_Total = $NoLinkedMasterAccount.count
    $script:ClientMailBoxes_Total       = $ClientMailBoxes.count
    write-host "Total Mailboxes Checked: " $ClientMailBoxes_Total
    write-host "Mailboxes without Linked Master Accounts: "$NoLinkedMasterAccount_Total
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
        #Export-Report-CSV
        #Export-Report-GroupBy
        #Export-Report-HTML
        #Email-Report
        Measure-Script
    }
}

Execute-MainScript
