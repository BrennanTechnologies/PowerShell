<#
    This script will find all mailboxes with Linked Master Accounts that do not have the user’s UPN from their AD Object in the client’s domain
#>


function Start-Script
{
    ############################################
    # Standard Script Constants & Variables
    ############################################

    ### Get Start Time for Measure-Script function
    $script:StartTime = Get-Date

    ### Get the scripts current filename & directory
    $script:ScriptFileName  = split-path $MyInvocation.PSCommandPath -Leaf
    $script:ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent

    ### Set StrictMode/Debugging
    #Set-StrictMode -Version 2.0
    Set-PSDebug -Strict # [-Off ][-Trace <Int32>] [-Step] [-Strict]
   
    ### Set Error Action Preference
    $ErrorActionPreference  = "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
    #$ErrorActionPreference = “SilentlyContinue”
    #$ErrorActionPreference = "Continue"
    #$ErrorActionPreference = "Inquire"
    #$ErrorActionPreference = "Ignore"
    #$ErrorActionPreference = "Suspend"

    ### Get OS Version
     [string]$CurrentOSVersion = (Get-CimInstance Win32_OperatingSystem).version    # Option 1: Using WMI to get OS Version
    #[string]$CurrentOSVersion = [environment]::OSVersion.Version                  # Option 2: Using Environment to get OS Version

    ### Get PS Version
    $PSVersion = $PSVersionTable.PSVersion

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

    # Create the Reports Folder.
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

function Export-Report-Console($ReportName, $ReportData)
{
    #################################
    ### Export Report to PS Console
    #################################
    write-host "`n`nReport: $ReportName" -ForegroundColor Yellow
    $ReportData | Format-Table -AutoSize
    write-host $ReportName "Total Count: " $ReportData.count
}

function Export-Report-CSV($ReportName, $ReportData)
{
    ###################################
    ### Export Report to TXT/CSV File
    ###################################
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".txt"
    New-Item -Path $ReportFile -ItemType "file" -Value "This is a text string." -Force
    write-host $ReportFile -ForegroundColor Yellow
    exit
    #$ReportData | Export-Csv -Path $ReportFile -NoTypeInformation 
    start-process $ReportFile
}

function Export-Report-HTML($ReportName, $ReportData)
{
    ############################
    ### HTML Header
    ############################
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    ############################
    ### Format Report Data
    ############################
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $PreContent = "$ReportName <br> ScriptName: $ScriptFileName <br> Report Date/Time: $ReportDate"
    $PostContent = "Total Records: " + $ReportData.Count
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".html"
    $Report = $ReportData | ConvertTo-Html -Head $Header -PreContent $PreContent -PostContent $PostContent

    ############################
    ### Email HTML Report
    ############################

    ### Email Constants
    $From = "cbrennan@eci.com"
    $To   = "cbrennan@eci.com"
    #$CC   = "sdesimone@eci.com"
    $SMTP = "qts-outlook.ecicloud.com"

    ### Email Parameters
    $EmailParams = @{
                From       = $From
                To         = $To 
                #CC         = $CC
                SMTPServer = $SMTP
                }

    ############################
    ### Export HTML Report
    ############################
    function Export-HTMLReport
    {
        $Report | Out-File $ReportFile
        start-process $ReportFile
    }

    function Email-HTMLReport
    {
        Send-MailMessage @EmailParams -Body ($Report | Out-String) -BodyAsHtml -Subject $ReportName
    }

    Export-HTMLReport
    Email-HTMLReport

    # Build Logic for Parameter
    <#
    if($Email)
    {
        Export-HTMLReport
    }
    if($HTML)
    {
        Email-HTMLReport
    }
    #>
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
        $ExchangeCAS = (HostName).split("-")[0] + "-htcas02.ecilab.net"
         
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
    $ReportData = @()
    $script:ClientMailBoxes = @()
    $NoLinkedMasterAccount = @()
    $UserError = @()
    
    ### Get the MailBoxes
    #$SearchOU = "ecicloud.com/clients/Samco" 
    #$SearchOU = "ecicloud.com/clients" 
    #$SearchOU = "ecicloud.com/Clients/SchoenerMgmt"
    $SearchOU = "ecilab.net/Clients"
    #$SearchOU = "ecilab.net/Clients/PJTPartners/Users"
    $SearchOU = "ecilab.net/Clients/MacdonaldVentures"

    write-host "Getting mailboxes for`t:" $SearchOU -ForegroundColor Yellow
    $ClientMailBoxes = Get-Mailbox -OrganizationalUnit $SearchOU -ResultSize unlimited | `
        Where-Object { `
             ($_.LinkedMasterAccount -notlike "NT AUTHORITY*") `
        -AND ($_.LinkedMasterAccount -notlike "ECICLOUD\Domain Controllers") `
        -AND ($_.LinkedMasterAccount -notlike "S-1-*") } |`
        Sort-Object -Property OrganizationalUnit `
        | Where-Object {$_.Name -like "Ham Burglar"}


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
                $ADAccount = Get-ADUser -Server $Domain -Identity $UserName `
                -Properties Name,SamAccountName,GivenName,Surname,EmailAddress,Mail,Displayname,DistinguishedName -ErrorAction silentlycontinue 

            }
            catch
            {
                write-host "Error Finding AD User Account for Mailbox`t: $MailBox.LinkedMasterAccount" -ForegroundColor white
                write-log $Error[0] yellow
            }


            function Remediate-Mailbox
            {
                [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="Low")]
                param (
                    [Parameter()]
                    [switch] $Remediate,
                    [Parameter()]
                    [switch] $Record,
                    [Parameter(Mandatory=$false, Position=0)]
                    [string] $Target,
                    [ValidateNotNullOrEmpty()]
                    [Parameter(Mandatory=$false, Position=1)]
                    [ValidateNotNullOrEmpty()]
                    [string] $Results,
                    [Parameter(Mandatory=$false, Position=2)]
                    [int] $PageSize

                )

                ############################
                # Write-Console
                ############################
                write-host "Whatif:" $WhatIfPreference
                write-host "EX_Name" $MailBox.Name -ForegroundColor Magenta
                write-host "EX_DistinguishedName" $MailBox.DistinguishedName -ForegroundColor Magenta
                write-host "EX_MailBox_EmailAddress: " $MailBox.EmailAddresses -ForegroundColor Magenta
                write-host "AD_samAccountName: " $ADAccount.samAccountName -ForegroundColor Magenta
                write-host "AD_Name: " $ADAccount.Name -ForegroundColor Magenta
                write-host "AD_UPN: " $ADAccount.UserPrincipalName -ForegroundColor Magenta
                write-host "AD_Mail: " $ADAccount.mail -ForegroundColor Magenta
                #exit


                ############################
                # Build Hash Table
                ############################

                $hash = [ordered]@{            
                    EX_Name                 = $MailBox.Name
                    EX_DistinguishedName    = $MailBox.DistinguishedName
                    EX_EmailAddress         = $MailBox.EmailAddresses
                    AD_samAccountName       = $ADAccount.samAccountName
                    AD_DistinguishedName    = $ADAccount.DistinguishedName
                    AD_UserPrincipalName    = $ADAccount.UserPrincipalName
                    AD_Mail                 = $ADAccount.mail            
                }                           
                $PSObject = New-Object PSObject -Property $hash
                $ReportData += $PSObject 
                $Whatif_Record = $ReportData

                #############################################
                ### Set mailbox
                #############################################

                if ($WhatIfPreference)
                {
                    #$Whatif_Record | ft
                    Export-Report-Console "Whatif_EX_Mailbox_Updates" $Whatif_Record
                    Export-Report-CSV "Whatif_EX_Mailbox_Updates" $Whatif_Record

                    write-host "Record Whatif" -ForegroundColor Yellow
                }
                if (-not($WhatIfPreference))
                {
                    write-host "Skipping" -ForegroundColor Yellow
                }

                write-host "Setting Alias:" -ForegroundColor Red
                
                $Update_MailBox = Get-Mailbox -Identity $MailBox.DistinguishedName
                if ($Update_MailBox -eq 1)
                {
                    "yes"
                    #$Update_MailBox | Set-Mailbox -EmailAddresses @{add=$ADAccount.UserPrincipalName} -whatif
                }

            }

            ### Test to see if the UPN exists in the Mailbox Aliases
            if(-not($MailBox.EmailAddresses -match $ADAccount.UserPrincipalName))
            {
                ### Alert on mailbox
                write-host "There is no matching UPN for mailbox for`t:" $MailBox.LinkedMasterAccount -ForegroundColor Red

                ### Remediate Mailbox
                Remediate-Mailbox -WhatIf

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
                    #EX_MailBox_EmailAddress = $MailBox.EmailAddresses
                    EX_MailBox_Name         = $MailBox.Name            
                    EX_DistinguishedName    = $MailBox.DistinguishedName            
                    EX_Client_UPN           = $ClientUPN       = $ClientUPN            
                }                           
                $PSObject           = New-Object PSObject -Property $hash
                $ReportData += $PSObject 
                $script:ReportData  = $ReportData
            }
            else
            {
                write-host "Match - UPN for Acccount $Username is`t:" $ADAccount.UserPrincipalName -ForegroundColor Green 
            }
        }
        else
        {
            write-host "This Mailbox Does NOT have A Linked Master Account`t:" $MailBox.DisplayName  -ForegroundColor Yellow
            Continue
        }
    }

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
        ###########################
        ### Choose Export Options
        ###########################
        #Export-Report-Console "NoLinkedMasterAccount" $ReportData
        #Export-Report-Console "NoLinkedMasterAccount" $NoLinkedMasterAccount
        #Export-Report-CSV "AD_Missing_Attributes" $ADErrors
        #Export-Report-CSV "NoLinkedMasterAccount" $NoLinkedMasterAccount
        #Export-Report-HTML $Report #"AD_Missing_Attributes" $ADErrors 
        #Export-Report-HTML "NoLinkedMasterAccount" $NoLinkedMasterAccount
        #Email-Report "AD_Missing_Attributes" $ADErrors 
        #Email-Report "NoLinkedMasterAccount" $NoLinkedMasterAccount
        Measure-Script
    }
}

Execute-MainScript
