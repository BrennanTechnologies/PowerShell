# Module BrennanFunctions

<#

.DESCRIPTION
    Custom Function Library

.DATE


.AUTHOR
    Chris Brennan
    brennanc@hotmail.com
#>

<#
Export-ModuleMember -Function "*"
Export-ModuleMember -Cmdlet "*"
Export-ModuleMember -Variable "*"
Export-ModuleMember -Alias "*"
#>

function Test-Module
{
    write-host "Module BrennanFunctions Exists" -ForegroundColor Green
}


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
    function Start-TranscriptLog
    {
        $TranscriptLogName = "TranscriptLog_" + $ScriptFileName + "_.log" #+ $TimeStamp + ".log"
        $TranscriptLogFile = $LogPath + "\" + $TranscriptLogName
        #write-log "Starting Transcript Log: $TranscriptLogFile "
        start-transcript -path $TranscriptLogFile
    }
    Start-TranscriptLog 

    if ($(Get-Host).Name -eq "ConsoleHost")
    {
        #Start-TranscriptLog
    }
    else
    {
        $PSVersion = ((get-host).Version).Major
        if ($PSVersion -ge 5) {
        #Start-TranscriptLog
        }
        if ($PSVersion -lt 5){write-log "TRANSCRIPT LOG: Script is running from Older ISE.. No Transcript Log will be generated" White}
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
        #$ExchangeCAS = (HostName).split("-")[0] + "-htcas01.ecicloud.com"
        #$ExchangeCAS = (HostName).split("-")[0] + "-htcas02.ecilab.net"
        $ExchangeCAS = (HostName).split("-")[0] + "-exch01.ecilab.net"
        $ExchangeSession = New-PSSession -Name ExchangeSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeCAS/PowerShell/ -Authentication Kerberos
            
        Import-PSSession $ExchangeSession -AllowClobber #-ea "silentlycontinue"  
        
        ### Debugging
        #Get-PSSession | Remove-PSSession 

    }
    else
    {
        write-host "Using Current Session: " $ExchangeSession 
    }
}


function Trap-Error
{
    #write-host "TRY-CATCH: *** FAILURE *** executing function: $FunctionName" red 
    Write-Host "Error Thrown In: $((Get-PSCallStack)[1].Command) "  -ForegroundColor Yellow
    write-host "InvocationInfo.Line : " $Error[0].InvocationInfo.Line -ForegroundColor Yellow
    write-host "Exception.Message: " $Error[0].Exception.Message -ForegroundColor Red
    write-host "ScriptStackTrace: " $Error[0].ScriptStackTrace -ForegroundColor DarkRed

    # Write Custom Error Messages
    if ($CustomErrMsg)
    {
        write-log $CustomErrMsg gray
    }
}

function Close-ErrorLog
{
    ###############################################
    ### Remember: Clear All Errors at top of Script
    ### $Error.Clear()
    ###############################################
    
    write-Host "Outputting Error Stack to Error Log" -ForegroundColor Cyan
    write-host "Total ErrorCount:" $Error.Count -ForegroundColor Yellow
    write-host "`n"

    if ($Error.Count -ne 0)
    {
        foreach ($Err in $Error)
        {
           
           
           Write-Host "Error Thrown In: $((Get-PSCallStack)[1].Command) "  -ForegroundColor Yellow
           write-host "Error Stack Index:" ([array]::indexof($Error,$Err)) -ForegroundColor Gray
           write-host "InvocationInfo.Line : " $error[0].InvocationInfo.Line -ForegroundColor DarkYellow
           write-host "Exception.Message: " $Err.Exception.Message -ForegroundColor Red
           write-host "ScriptStackTrace: " $Err.ScriptStackTrace -ForegroundColor DarkRed
        }
    }
    if ($Error.Count -eq 0)
    {
        write-host "No Errors Found!" -ForegroundColor Green
    }
}


##################

function oldTry-Catch($ScriptBlock)
{
    ### Define the Try/Catch function to trap errors and write to log & console.

    try
    {
        write-log "Executing Function: $FunctionName" yellow
        
        Invoke-Command -ScriptBlock $ScriptBlock
        #Start-Job -ScriptBlock $ScriptBlock
        
        ### Successfully Executed Last Command
        if ($? -eq "True")
        {
            $Msg = "TRY-CATCH: *** SUCCESS *** executing function: $FunctionName"
            Write-Log  $Msg green
        }    
    }
    catch [Exception]
    {
        Error-Trap
    }
    finally
    {
        $error.clear() 
    }
}

function oldClose-ErrorLogFile
{
    ### Close the Log File and Write the Time
    $ScriptExecutionTime = 0
    
    $EndTime = get-date
    Write-Log "`n`n*** CLOSING LOG FILE at: $EndTime"
}

function oldClose-TranscriptLog
{
    ### Stop the Transcript Log

    if ($Host.Name -eq "ConsoleHost")
    {
        Write-Log "Stopping PS Transcript Log" 
        Stop-transcript
    }
}

function  Reboot-Computer
{
	#Reboots the Server Post Configuration
    Write-Host "Do you want to reboot the computer now?" White
    Write-Host -nonewline " (Y/N ?)" -ForegroundColor White
    $response = read-host
    if ($response -eq "Y") 
    {
        Write-Host "Rebooting computer in 5 seconds . . . " White
        Write-Host "Hit Ctrl-C or Ctrl-Break to exit script without rebooting."  
        Start-Sleep -s 5
        Restart-Computer -Force
    }
    elseif ($response -eq "N")  
    {
        Write-Host "Continuing script without rebooting in 5 seconds." White
        Start-Sleep -s 5
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        write-host "You did not enter Y or N!" -foregroundcolor white
        fcnReStartComputer
    }
}


function Test-InternetConnection
{

    $TargetURL = "google-public-dns-a.google.com"
    $TargetIP = "8.8.8.8"

    write-host "Testing Internet Connection."
    $TestInternetConnection = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet 
    $PingInternet = Test-Connection $TargetIP -count 1 -quiet


    If ($PingInternet -eq "True")
    {
        write-host "Internet Connection is Good."
    }
    elseif($PingInternet -eq "False")
    {
        write-host "Internet Connection is not Available."
    }
}

function Detect-MachineType
{
    <#------------------------------------------------------- 
        MachineType:   MachineModel:             Machine:
        Hyper-V        Virtual Machine           VM
        VMware         VMware Virtual Platform   VM
        VirtualBox     VirtualBox                VM  
        Physical       Default                   Physical
    ---------------------------------------------------------#>

    $Computer = $env:COMPUTERNAME

    $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $env:COMPUTERNAME #-ErrorAction Stop -Credential $Credential 

    switch ($ComputerSystemInfo.Model) 
    { 
        # Check for Hyper-V Machine Type 
        "Virtual Machine" 
        { 
            $MachineType="Hyper-V" 
            $Machine = "VM"
        } 
 
        # Check for VMware Machine Type 
        "VMware Virtual Platform"
        { 
            $MachineType="VMware"
            $Machine = "VM" 
        } 
 
        # Check for Oracle VM Machine Type 
        "VirtualBox" 
        { 
            $MachineType="VirtualBox" 
            $Machine = "VM"
        }
        default 
        { 
            $MachineType="Physical"
            $Machine = "Physical" 
        } 
     }          
     
    ### Get Machine Type    
    $Machine              = $Machine
    $MachineType          = $MachineType 
    $MachineModel         = $ComputerSystemInfo.Model 
    $MachineManufacturer  = $ComputerSystemInfo.Manufacturer 

    write-host "Machine: "             $Machine
    write-host "MachineType: "         $MachineType
    write-host "MachineModel: "        $MachineModel
    write-host "MachineManufacturer: " $MachineManufacturer
}


function Get-OSVersion
{

    ### Detects OS Version
 
    write-host "Checking OS Version" -ForegroundColor Blue
            
    ### Option 1: Using WMI to get OS Version
    [string]$CurrentOSVersion = (Get-CimInstance Win32_OperatingSystem).version

    ### Option 2: Using Environment to get OS Version
    #$OSVersion = [environment]::OSVersion.Version 

    Write-log "The Current OS Version is   : $CurrentOSVersion " yellow
}

function Ask-YesNoExit
{
    ### Check for Yes/No answer, and loop if it doesnt get a 'Y' or an 'N'

    function Check-Response
    {
       write-host "Do you want to pause the script?"
        write-host -nonewline "(Y/N?)" -ForegroundColor white
        $response = read-host

        if ($response -eq "Y") 
        {

            write-host "Press any key to continue ..."
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            write-log "Exiting script execution . . . " White
            exit
        }
        elseif ($response -eq "N")
        {
            write-log "Contining script execution . . . " White
        }
        elseif (($response -ne "Y") -or ($response -ne "N"))
        {
            write-host "You did not enter Y or N!" -ForegroundColor White
            Ask-YesNoExit
        }
    }
    Check-Response
}

function Ask-ContinueScript
{
	### Prompt user to Pause the Script

    write-host -nonewline "Continue Running the script?"
    write-host -nonewline " (Y/N ?)" -ForegroundColor white
    $response = read-host
    $response = $response.ToUpper()

    if ($response -eq "Y")  
    {
        Write-host "Continueing Script Execution."  
    }
    elseif ($response -eq "Y") 
    {
        write-host "Exiting the script in 10 seconds. . . " 
        Start-Sleep -sec 10
        Exit
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        write-host "You did not enter Y or N!" -foregroundcolor white
        Ask-ContinueScript
    }
}

function Ask-ExitScript
{
	### Prompt user to Pause the Script

    write-host -nonewline "Do you want to Exit the script?"
    write-host -nonewline " (Y/N ?)" -ForegroundColor white
    $response = read-host
    $response = $response.ToUpper()

    if ($response -eq "Y") 
    {
        write-host "Exiting the script in 10 seconds. . . " 
        Start-Sleep -sec 10
        write-host "Press any key to continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Exit
    }
    elseif ($response -eq "N")  
    {
        Write-host "Continueing Script Execution."  
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        write-host "You did not enter Y or N!" -foregroundcolor white
        AskExit-Script
    }
}

function Pause-Console
{
    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost")
    {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }
}

function Check-ConsoleMode ($Msg)
{
    ### Check Console Mode.
    if ($Host.Name -eq "ConsoleHost")
    {
        Write-log "Thi Script is running in the PS Console Mode"
    }
    else
    {
        Write-log "This Script is running in the PS ISE Mode"
        #write-host $Msg -ForegroundColor Cyan
        #Read-Host -Prompt "Press Enter to continue"
    }
}


function Pause-Script ($message)
{
    ### Pause for both ISE & Console

    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

### Current - Stop the Script to Ask Yes or No
    function Ask-YesNo($Prompt, $YesMsg, $NoMsg)
    {
        ### Advanced Function using cmdletbinding Methods
        [cmdletbinding()]

        [Parameter(Mandatory=$True, Position=0)]
        [String]$Prompt,

        [Parameter(Mandatory=$True, Position=1)]
        [String]$YesMsg

        [Parameter(Mandatory=$True, Position=1)]
        [String]$NoMsg

        $ReadHost = Read-Host "$Prompt [Y/N]"
        $ReadHost = $ReadHost.ToUpper()

        if ($ReadHost -eq "Y" )
        {
            write-host $YesMsg
        }
        elseif($ReadHost -eq "N")
        {
            write-host $NoMsg
        }
        elseif (($ReadHost -ne "Y") -or ($ReadHost -ne "N"))
        {
            write-host "You did not enter Y or N!" -foregroundcolor white
            Ask-YesNo
        }
    }
    ### Use this to call the function
    #Ask-YesNo

    
function Check-RequiredlFiles
{

    ### Advanced Function using cmdletbinding Methods
    [cmdletbinding()]

    [Parameter(Mandatory=$True, Position=0)]
    [String]$ScriptPath,

    [Parameter(Mandatory=$True, Position=1)]
    [String]$RequiredFiles

    ### This function checks for any files that are required by the script.
    
    Write-Log "Checking for requiried files." yellow

    $RequiredFiles  = @()
    $RequiredFiles += 'Parameters.txt'
    #$RequiredFiles += 'NonExistantTestFile'
    
    foreach ($RequiredFile in $RequiredFiles)
    {
        ### Check for if each file exists.
        #$RequiredFile = $ScriptPath + $RequiredFile
        Write-Log "`t Checking for $RequiredFile" 

        ### All required files are called from the path that the script if in.
        #$RequiredFilePath = $ScriptPath + $RequiredFile
        $RequiredFilePath = $ScriptPath + "\" + $RequiredFile
        write-log "Required File Path: $RequiredFilePath"
        
        If((Test-Path -Path $RequiredFilePath) -ne $false) 
        {
            Write-Host "`t`t All Requires Files Exist: " $RequiredFile green
        }
    
        else
        {
            Write-Log "`t`t $RequiredFile file does not exist" red
            #Write-Log "The required files must reside in the folder... $ScriptPath" white
            Write-Log "Do you want to exit the script now?... " white
            Write-Host -nonewline "Press 'Y' to exit or 'N' to continue the script. " -foregroundcolor white
            
            Pause-Script
        }
    }
}


### START FUNCTION: This Function is a Template for all Functions
function Function-Template
{
    ### Advanced Function using cmdletbinding Methods
    [CmdletBinding()]            

    PARAM()

    BEGIN
    {
        $script:FunctionName = $MyInvocation.MyCommand.name #Get the name of the currently executing function
    }

    PROCESS
    {
        $script:CustomErrMsg = "Custome Error Msg: Error with funtion Do-Somthing"
    
        ##### Setup the scriptblock to execute with the Try/Catch function.
        $ScriptBlock = 
        {

            Do-Something
        
        }
        Try-Catch $ScriptBlock
    }        
    END
    {
        #Remove-Variable -name -scope -Include -Exclude -Force
    }
}
### END FUNCTION: Function-Template


