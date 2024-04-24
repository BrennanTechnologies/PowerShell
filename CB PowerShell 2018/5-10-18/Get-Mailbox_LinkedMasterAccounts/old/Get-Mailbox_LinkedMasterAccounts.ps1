<#
    This script will find all mailboxes with Linked Master Accounts that do not have the user’s UPN from their AD Object in the client’s domain
#>

function Create-LogFile
{
    ### Create & Start the Custom Error Log Files & Transcript Log File
    # Get the scripts current filename & directory
    $script:ScriptFile  = split-path $MyInvocation.PSCommandPath -Leaf
    $script:ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent

    # Format the LogFile Timestamp
    $script:TimeStamp    = Get-Date -format "MM_dd_yyyy_hhmmss"

    # Create the Log Folder.
    $script:LogPath = $ScriptPath + "\Logs" 
    if(-not(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}
    
    # Create Custom Error Log File
    $ErrorLogName = "ErrorLog_" + $TimeStamp + ".log"
    $script:ErrorLogFile = $LogPath + "\" + $ErrorLogName
}

function Write-Log($string,$color) 
{
    ### Write Error-Trap messages to the console & the log file.
    if ($color -eq $null) {$color = "magenta"}
    write-host $string -foregroundcolor $color
    "`n`n"  | out-file -filepath $ErrorLogFile -append
    $string | out-file -filepath $ErrorLogFile -append
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
    $ClientMailBoxes = @()
    $NoLinkedMasterAccount = @()
    $UserError = @()
    
    ### Get the MailBoxes
    $OU = "ecicloud.com/clients/Samco" 
    $OU = "ecicloud.com/Clients/SchoenerMgmt"
    #$OU = "ecicloud.com/clients" 

    write-host "Getting mailboxes for`t:" $OU -ForegroundColor Yellow
    $ClientMailBoxes = Get-Mailbox -OrganizationalUnit $OU -ResultSize unlimited | Where-Object {($_.LinkedMasterAccount -notlike "NT AUTHORITY*") -AND ($_.LinkedMasterAccount -notlike "ECICLOUD\Domain Controllers") -AND ($_ -notlike "S-1-*")}

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
                #$ADAccount = Get-ADUser -Server $Domain -Identity $UserName
                $PDC = (Get-ADDomain -Identity $Domain | Select-Object -Property PDCEmulator).PDCEmulator
                $ADAccount = Get-ADUser -Server $PDC -Identity $UserName -ErrorAction silentlycontinue
            }
            catch
            {
                write-host "Error Finding AD User Account for Mailbox`t: $MailBox.LinkedMasterAccount" -ForegroundColor white

                #$Error[0] | out-file -filepath $ErrorLogFile -append
                #$Error[0].Exception | out-file -filepath $ErrorLogFile -append
                #$Error[0].ScriptStackTrace  | out-file -filepath $ErrorLogFile -append
                
                write-log $Error[0] yellow
            }

            ### Test to see if the UPN exists in the Mailbox Aliases
            if(-not($MailBox.EmailAddresses -match $ADAccount.UserPrincipalName))
            {
                ### Alert on mailbox
                write-host "There is no matching UPN for mailbox for`t:" $MailBox.LinkedMasterAccount -ForegroundColor Red
                $NoLinkedMasterAccount += $MailBox.LinkedMasterAccount
                
                #write-host $OU -ForegroundColor Yellow
                #write-host $MailBox.Name -ForegroundColor Yellow
                #write-host $MailBox.DistinguishedName -ForegroundColor Yellow
                #write-host $MailBox.EmailAddresses -ForegroundColor Yellow

                #$OU = $MailBox.DistinguishedName.Split(",")[2].split("=")[1]
                $ClientUPN = $MailBox.EmailAddresses | Where-Object {$_ -match "SMTP:"}
                $ClientUPN = $ClientUPN.split(":")[1]
                #write-host $ClientUPN  -ForegroundColor Yellow
                
                ############################
                # Build Hash Table
                ############################

                $hash = [ordered]@{            
                    OU                 = $OU
                    MailBox_Name       = $MailBox.Name            
                    DistinguishedName  = $MailBox.DistinguishedName            
                    ClientUPN          = $ClientUPN            
                }                           

                $PSObject =  New-Object PSObject -Property $hash
                $Report   += $PSObject 
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


    ### Export the Results to Out-File
    write-host "Total Mailboxes Checked: " $ClientMailBoxes.count
    write-host "Mailboxes without Linked Master Accounts: "$NoLinkedMasterAccount.count

functon Export-Report-CSV
{
    ############################
    # Export & Show the File
    ############################
    $ReportName = $ScriptName
    $ReportDate = Get-Date -Format ddmmyyyy
    $ReportFile = $LogPath + "\" + "Report" + $ReportName + "_" + $ReportDate + ".txt"
    $Report | Export-Csv -Path $ReportFile -NoTypeInformation 
    start-process $ReportFile
}


functon Export-Report-HTML
{
    ############################
    # Export HTML Report
    ############################

    # Header for HTML
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:10;font-color: #000000;text-align:center;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"

    <#
    $Header   = "<style>"
    $Header  += "TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header  += "TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}"
    $Header  += "TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}"
    $Header  += "</style>"
    #>


    $Pre = "Report Date: $ReportDate"
    $Post = "Total Mailboxes Checked: $ClientMailBoxes.count `n Mailboxes without Linked Master Accounts: $NoLinkedMasterAccount.count"

    $ReportName = $ScriptName
    $ReportDate = Get-Date -Format ddmmyyyy
    $ReportFile = $LogPath + "\" + "Report" + $ReportName + "_" + $ReportDate + ".html"
    $Report | Select-Object * | ConvertTo-HTML -Head $Header -PreContent $Pre -PostContent $Post | Out-File $ReportFile

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
    $CC   = "cbrennan@eci.com"
    $SMTP = "qts-outlook.ecicloud.com"

    # Email Parameter Variables
    $EmailParams = @{

                From       = $From
                To         = $To 
                CC         = $CC           
                SMTPServer = $SMTP
                        
                }

    # Send Email Report
    $ReportName = $ScriptName
    $ReportDate = Get-Date -Format ddmmyyyy
    $Body = $Report | ConvertTo-Html -Head $Header -PreContent $Pre -PostContent $Post
    Send-MailMessage @EmailParams -Body ($Body | Out-String) -BodyAsHtml -Subject "$ReportName - $ReportDate"
}

Export-Report-CSV
Export-Report-HTML
Email-Report

}


function Execute-MainScript
{
Begin {
        Clear-Host
        #Test
        Create-LogFile
        Import-ExchangeSession
    }

    Process {

        Get-Mailbox_LinkedMasterAccounts
   }

    End {
        
        ### Remove-Session
        if ($ExchangeSession) { Get-PSSession -Name ExchangeSession | Remove-PSSession }
    }
}
Execute-MainScript
