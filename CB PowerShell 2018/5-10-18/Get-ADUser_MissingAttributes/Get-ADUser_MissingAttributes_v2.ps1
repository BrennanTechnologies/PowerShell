<#
    
    This Script finds all mailboxes with LinkedMasterAcounts and then identifies the associated AD USer Accounts missing required attributes.
    
    cbrennan@eci.com
    4/20/18
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
    #######################################################################
    ### Create & Start the Custom Error Log Files & Transcript Log File
    #######################################################################

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
    ######################################
    ### Calculates Script Execution Time
    ######################################
    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    write-host `n`n
    write-log "Script ended at $StopTime" white
    write-log "Script Execution Time: $ElapsedTime" white
}


function Set-PSCredentials
{
    ######################################
    ### Open Exchange Console Session
    ######################################

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
    $ReportData | Export-Csv -Path $ReportFile -NoTypeInformation 
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
    ##########################################
    ### Calculates Script Execution Time
    ##########################################
    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    write-host `n`n
    write-log "Script ended at $StopTime" white
    write-log "Script Execution Time: $ElapsedTime" white
}


function Close-LogFiles
{
    ### Close the Log File and Write the Time
    $EndTime = get-date
    Write-Log "`n`n*** CLOSING LOG FILE at: $EndTime"

    ### Stop the Transcript Log
    if ($Host.Name -eq "ConsoleHost")
    {
        Write-Log "Stopping PS Transcript Log $EndTime" 
        Stop-transcript
    }
}


function Import-ExchangeSession
{
    ##########################################
    ### Check for Existing Session
    ##########################################
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


function Get-ADUser_MissingAttributes
{
    ##########################################
    # Main Function
    ##########################################
    
    ### Create/Clear the Arrays
    $Report                       = @()
    $script:ClientMailBoxes       = @()
    $script:NoLinkedMasterAccount = @()
    $script:ADErrors              = @()
    
    ### Get the MailBoxes
    $SearchOU = "ecicloud.com/clients" 
    #$SearchOU = "ecicloud.com/clients/Samco" 
    #$SearchOU = "ecicloud.com/Clients/SchoenerMgmt"
    #$SearchOU = "ecicloud.com/clients/Apex" 

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
            write-host "Getting AD User Account for Mailbox: " $MailBox.LinkedMasterAccount -ForegroundColor Cyan

            $Domain    = $MailBox.LinkedMasterAccount.split("\")[0]
            $UserName  = $MailBox.LinkedMasterAccount.split("\")[1]
        
            try
            {
                ### Alternate Method: Get-ADUser - Specify PDCEmulator - Takes Longer to run
                #$PDC = (Get-ADDomain -Identity $Domain | Select-Object -Property PDCEmulator).PDCEmulator
                #$ADAccount = Get-ADUser -Server $PDC -Identity $UserName -ErrorAction silentlycontinue

                ### Get-ADUser - Use NetBios Name for Domain
                #$script:ADAccount = Get-ADUser -Server $Domain -Identity $UserName -Properties * -ErrorAction silentlycontinue -ErrorVariable ErrorVar
                $script:ADAccount = Get-ADUser -Server $Domain -Identity $UserName -Properties Name,SamAccountName,GivenName,Surname,EmailAddress,DistinguishedName -ErrorAction silentlycontinue -ErrorVariable ErrorVar

                if($ErrorVar)
                {
                    write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue
                    write-error $ErrorVar
                }
            }
            catch
            {
                write-host "Error Finding AD User Account for Mailbox`t: " $MailBox.LinkedMasterAccount -ForegroundColor white
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
                AD_AccountOU      = (($ADAccount.DistinguishedName).split(",")[-2]).split("=")[-1]
                AD_Name           = $ADAccount.Name
                AD_SamAccountName = $ADAccount.SamAccountName
                AD_GivenName      = $ADAccount.GivenName
                AD_Surname        = $ADAccount.Surname
                AD_EmailAddress   = $ADAccount.EmailAddress
            } 

            foreach($ADAttribute in $ADAttributes)
            {
                ### Get AD Value
                $ADValue = $ADAccount.$ADAttribute
                #write-host "$ADAttribute : $ADValue" -ForegroundColor Green
                

                ### Build Logic for Dynamic Hash Table Generation
                <#
                # Testing this function
                ### Add to Hash Table 
                #$Hash.Add($Search_OU, ($SearchOU.split("/")[-1]))
                #$Hash.Add($ADAttribute, $ADValue)
                #$PSObject  =  New-Object PSObject -Property $Hash
                #>

                if(!$ADValue)
                {
                    write-host "AD Account: " $ADAccount.Name "`nMissing AD Attribute: " $ADAttribute -ForegroundColor Red
                    #$Hash.Add($ADAttribute, $ADValue)
                    $PSObject  =  New-Object PSObject -Property $Hash
                    $script:ADErrors += $PSObject
                    Continue
                }
                elseif ($ADValue)
                {
                  #write-host "$ADAttribute : $ADValue" -ForegroundColor Green
                }
            }
        }

        elseif(-not($MailBox.LinkedMasterAccount))
        {
            write-host "LinkedMasterAccount DOES NOT Exists: " $MailBox.Name -ForegroundColor Red
            
            ############################
            # Build Hash Table
            ############################

            $hash = [ordered]@{            
                Exchange_OU                  = (($MailBox.DistinguishedName).split(",")[-4]).split("=")[-1]
                Exchange_MailBox_Name        = $MailBox.Name   
                Exchange_MailBox_DisplayName = $MailBox.DisplayName         
                Exchange_DistinguishedName   = $MailBox.DistinguishedName            
            }                           
            $PSObject =  New-Object PSObject -Property $hash
            $script:NoLinkedMasterAccount   += $PSObject 
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

        Get-ADUser_MissingAttributes
    }

    End {
        ###########################
        ### Choose Export Options
        ###########################
        Export-Report-Console "AD_Missing_Attributes" $ADErrors
        Export-Report-Console "NoLinkedMasterAccount" $NoLinkedMasterAccount
        #Export-Report-CSV "AD_Missing_Attributes" $ADErrors
        #Export-Report-CSV "NoLinkedMasterAccount" $NoLinkedMasterAccount
        Export-Report-HTML "AD_Missing_Attributes" $ADErrors 
        Export-Report-HTML "NoLinkedMasterAccount" $NoLinkedMasterAccount
        #Email-Report "AD_Missing_Attributes" $ADErrors 
        #Email-Report "NoLinkedMasterAccount" $NoLinkedMasterAccount
        
        Measure-Script
        Close-LogFiles
    }
}

Execute-MainScript