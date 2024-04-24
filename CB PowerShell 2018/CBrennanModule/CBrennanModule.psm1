### Module CBrennanModule - Custom Functions, Templates, and Cmdlets

#region Document Properies
<#

.DESCRIPTION
    CBrennan Custom Functions & Cmdlet Library

.DATE
    April 2018

.AUTHOR
    Chris Brennan
    brennanc@hotmail.com
#>
#endregion


#region Notes & ToDo
<#

- Build Report Function

- Export-Report Function

- Try/Catch Function



#>
#endregion

#region Production Functions
#-----------------------------------------------------------------------------------

function Export-Members {
    Export-ModuleMember -Function "*"
    Export-ModuleMember -Cmdlet "*"
    Export-ModuleMember -Variable "*"
    Export-ModuleMember -Alias "*"
}

function Import-CBrennanModule {
    ### Reload Module at RunTime
    if(Get-Module -Name "CBrennanModule"){Remove-Module -Name "CBrennanModule"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\CBrennanModule\CBrennanModule.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CBrennanModule")){Write-Host "Loading Custom Module: CBrennanModule" -ForegroundColor Green}
    if(!(Get-Module -Name "CBrennanModule")){Write-Host "The Custom Module CBrennanModule WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Test-Module ($string) {
    Write-Host "Module CBrennanFunctions Exists" -ForegroundColor Green; Write-Host "Test String: $String" -ForegroundColor Green
}

function Set-ScriptVariables {
    ### Clear the Error Variable Array
    $global:Error.Clear()

    ### Clear all Variables
    ### BE CAREFUL!!!
    ### Get-Variable -Name * | Remove-Variable -Force -ErrorAction SilentlyContinue | Out-Null
    

    ### Standard Script Constants & Variables
    #-------------------------------------------------

    ### Get Start Time for Measure-Script function
    $global:StartTime = Get-Date

    ### Get the scripts current filename & directory
    $global:ScriptName  = split-path $MyInvocation.PSCommandPath -Leaf
    $global:ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent

    ### Set StrictMode/Debugging
    #-----------------------------------
    #Set-StrictMode -Version 2.0
    Set-PSDebug -Strict # [-Off ][-Trace <Int32>] [-Step] [-Strict]
   
    ### Set Error Action Preference
    $global:ErrorActionPreference  = "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
    #global:$ErrorActionPreference = “SilentlyContinue”
    #global:$ErrorActionPreference = "Continue"
    #global:$ErrorActionPreference = "Inquire"
    #global:$ErrorActionPreference = "Ignore"
    #global:$ErrorActionPreference = "Suspend"

    ### Get PS Version
    $global:PSVersion = $PSVersionTable.PSVersion

}

function Write-Log {
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Message,
    [Parameter(Mandatory = $False, Position = 1)] [string]$Value,
    [Parameter(Mandatory = $False, Position = 2)] [string]$Value2,
    [Parameter(Mandatory = $False)] [string]$ForegroundColor,
    [Parameter(Mandatory = $False)] [switch]$Quiet
    )
    
    ### Concatenate Message
    $Message = $Message + $Value + $Value2
    
    ### Write the Message to the Log File.
    "`n`n*****"   | out-file -filepath $LogFile -append
    $Message      | out-file -filepath $LogFile -append

    ### Write the Messages to the Console (or Not if -Quiet is True)
    if (-NOT($Quiet))
    {
        if (-NOT($Foregroundcolor)) {$Foregroundcolor = "White"}

        Write-Host $Message -Foregroundcolor $Foregroundcolor
    }
}

function Start-LogFiles {
    # Format the LogFile Timestamp
    $global:TimeStamp  = Get-Date -format "MM_dd_yyyy_hhmmss"
   
    # Create the Log Folder.
    $global:LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}

    # Create the Reports Folder.
    $global:ReportPath = $ScriptPath + "\Reports" 
    if(!(Test-Path -Path $ReportPath)) {New-Item -ItemType directory -Path $ReportPath | out-null}

    # Create Log File
    $global:LogFile = $LogPath + "\LogFile_" + $ScriptName + "_" + $TimeStamp + ".log"
    Write-Log "*** OPENING LOG FILES at: " $StartTime -ForegroundColor Gray
}

function Start-Transcribing {
    
    try
    {
        # Start Transcript Log File
        if (($(Get-Host).Name -eq "ConsoleHost") -OR ($((get-host).Version).Major -ge "5")){Start-Transcript -path $LogPath"\TranscriptLog_"$ScriptName"_.log" -Force}
        else {Write-Host "No Transaction Log Started: This version of ISE doesnt support Tranaction Logs."}
    }
    catch
    {
        Write-Host "Error Starting Transcript Log" -ForegroundColor Red
    }
}

function Stop-Transcribing {
    try {Stop-Transcript | Out-Null} catch {Write-Host "No Transcript Running"}
}

function Trap-Error {
    Write-Log "`n`nError Trapped by Try-Catch: `n"       ('-' * 50) # Line Break in Error Log
    Write-Log "ERRORTRAP: CallStack Command:`t`t"        $((Get-PSCallStack)[1].Command)           -ForegroundColor Yellow
#   Write-Log "ERRORTRAP: CallStack FunctionName:`t"     $((Get-PSCallStack)[1].FunctionName)      -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Location:`t`t"       $((Get-PSCallStack)[1].Location)          -ForegroundColor Yellow
#   Write-Log "ERRORTRAP: CallStack ScriptLineNumber:"   $((Get-PSCallStack)[1].ScriptLineNumber)  -ForegroundColor Yellow
    Write-Log "ERRORTRAP: InvocationInfo.Line:`t`t"      $global:Error[0].InvocationInfo.Line      -ForegroundColor DarkYellow
    Write-Log "ERRORTRAP: Exception.Message:`t`t"        $global:Error[0].Exception.Message        -ForegroundColor Red
    Write-Log "ERRORTRAP: ScriptStackTrace:`t`t"         $global:Error[0].ScriptStackTrace         -ForegroundColor DarkRed
    Write-Log "End Try-Catch Error Trap: `n"             ('-' * 50) # Line Break in Error Log

    # Write Custom Error Messages
    if ($CustomErrMsg) {Write-Log $CustomErrMsg -ForegroundColor gray}

    <#
    # Debugging:
    #------------------------------------------------------------
    $CallStack = Get-PSCallStack | Select-Object -Property *
    Write-Host $CallStack.Command
    Write-Host "Location:" $CallStack.Location
    ###Write-Host $CallStack.Arguments
    Write-Host $CallStack.ScriptName
    Write-Host $CallStack.ScriptLineNumber
    Write-Host $CallStack.InvocationInfo
    Write-Host $CallStack.Position
    Write-Host $CallStack.FunctionName
    #>
}


function Try-Catch #($ScriptBlock)
{

    Param(
    [Parameter(Mandatory = $True,Position = 0)] [ScriptBlock]$ScriptBlock
    )

    ### Define the Try/Catch function to trap errors and write to log & console.

    try
    {
        Write-Log "Executing Function: $FunctionName" yellow
        
        Invoke-Command -ScriptBlock $ScriptBlock
        Invoke-Command -ScriptBlock $ScriptBlock -ErrorVariable ErrorVar
        #Start-Job -ScriptBlock $ScriptBlock
        
        ### Successfully Executed Last Command
        if ($? -eq "$True") #Returns True if last operation succeeded, else False.
        {
            $Msg = "TRY-CATCH: *** SUCCESS *** executing function: $FunctionName"
            Write-Log  $Msg green
        }   

        if ($? -eq "$False")
        {
            $Msg = "TRY-CATCH: *** SUCCESS *** executing function: $FunctionName"
            Write-Log  $Msg green
        }  

        if($Error[0])
        {
            write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue
            write-error $ErrorVar
        }
        if(-NOT($Error[0]))
        {
            $Msg = "TRY-CATCH: *** SUCCESS *** executing function: $FunctionName"
            Write-Log  $Msg green
        }  
                
        if(-NOT($ErrorVar))
        {
            $Msg = "TRY-CATCH: *** SUCCESS *** executing function: $FunctionName"
            Write-Log  $Msg green
        } 
        
        if($ErrorVar)
        {
            write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue
            write-error $ErrorVar
        }        
    }
    catch
    {
        Trap-Error 
    }
    finally
    {
        $Error.Clear() 
    }
}

function Close-LogFile {
    ########################################################################
    ### Remember: Clear All Errors at top of Script using $Error.Clear()
    ########################################################################

    ### Write the Entire Error Stack to the Log File
    Write-Log "`n`nOutputting Error Stack to Error Log File" -ForegroundColor Cyan
    Write-Log "`nTotal Error Count:`t" $global:Error.Count -ForegroundColor Yellow

    if ($global:Error.Count -ne 0)
    {
        Write-Log "`nERRORS FOUND: Dumping Error Array" -ForegroundColor Red
        Write-Log "ERROR ARRAY:`t`t " ('=' * 100)  -ForegroundColor Gray -Quiet # Line Break in Error Log
        Write-Log "`t`t "             ('=' * 100)  -ForegroundColor Gray -Quiet # Line Break in Error Log

        foreach ($global:Err in $GLOBAL:Error)
        {
            Write-Log "ERROR STACK ELEMENT:`t`t"                 ('-' * 100)                                        -ForegroundColor Gray        -Quiet   # Line Break in Error Log
            Write-Log "ERROR STACK INDEX:`t`t`t`t`t"             ([array]::indexof($global:Error,$global:Err))      -ForegroundColor Gray        -Quiet
            Write-Log "ERRORTRAP: CallStack Command:`t`t"        $((Get-PSCallStack)[1].Command)                    -ForegroundColor Yellow      -Quiet
        #   Write-Log "ERRORTRAP: CallStack FunctionName:`t"     $((Get-PSCallStack)[1].FunctionName)               -ForegroundColor Yellow      -Quiet
            Write-Log "ERRORTRAP: CallStack Location:`t`t"       $((Get-PSCallStack)[1].Location)                   -ForegroundColor Yellow      -Quiet
        #   Write-Log "ERRORTRAP: CallStack ScriptLineNumber:"   $((Get-PSCallStack)[1].ScriptLineNumber)           -ForegroundColor Yellow      -Quiet
            Write-Log "ERRORTRAP: InvocationInfo.Line:`t`t"      $global:Error[0].InvocationInfo.Line               -ForegroundColor DarkYellow  -Quiet
            Write-Log "ERRORTRAP: Exception.Message:`t`t"        $global:Error[0].Exception.Message                 -ForegroundColor Red         -Quiet
            Write-Log "ERRORTRAP: ScriptStackTrace:`t`t"         $global:Error[0].ScriptStackTrace                  -ForegroundColor DarkRed     -Quiet
        }
    }
    if ($global:Error.Count -eq 0)
    {
        Write-Host "`nNo Errors Found!" -ForegroundColor Green
    }
    
    Write-Log "`n`n*** CLOSING LOG FILE at: " $(Get-Date) -ForegroundColor Gray
}


function Export-Report-Console {
    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report
        )
    ### Export Report to Console
    ### -------------------------------
    Write-Host "`n`nReport Name: $global:ReportName" -ForegroundColor Yellow
    $Report | Format-Table -AutoSize
    Write-Host $ReportName "Total Count: " $Report.count


}

function Export-Report-CSV {

    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report
        )

    ### Export Report to TXT/CSV File
    ### -------------------------------
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".txt"
    $Report | Export-Csv -Path $ReportFile -NoTypeInformation 
    write-log "Report Exported: $ReportFile" -ForegroundColor Green
    start-process $ReportFile
}

function Export-Report-HTML {
    
    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report
        )

    ### HTML Header
    ### --------------------------
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"
    
    ### Format Report Data
    ### --------------------------
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $PreContent = "$ReportName <br> ScriptName: $ScriptName <br> Report Date/Time: $ReportDate"
    $PostContent = "Total Records: " + $Report.Count
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".html"
    $Report = $Report | ConvertTo-Html -Head $Header -PreContent $PreContent -PostContent $PostContent
    
    ### Export HTML Report
    ### --------------------------
    $Report | Out-File $ReportFile
    write-log "Report Exported: $ReportFile" -ForegroundColor Green
    start-process $ReportFile

 }

function Export-Report-Email {
    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report,
        [Parameter(Mandatory=$True)][string]$From,
        [Parameter(Mandatory=$True)][string]$To,
        [Parameter(Mandatory=$False)][string]$CC,
        [Parameter(Mandatory=$False)][string]$SMTP
        )
    
    ### HTML Header
    ### --------------------------
    $Header  = "<style>"
    $Header += "BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}"
    $Header += "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $Header += "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}"
    $Header += "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #FFEFD5}"
    $Header += "</style>"

    ### Format Report Data
    ### --------------------------
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $PreContent = "$ReportName <br> ScriptName: $ScriptName <br> Report Date/Time: $ReportDate"
    $PostContent = "Total Records: " + $Report.Count
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".html"
    $Report = $Report | ConvertTo-Html -Head $Header -PreContent $PreContent -PostContent $PostContent

    ### Manually Overide Email Parameters
    ### ---------------------------------
    #$From = "cbrennan@eci.com"
    #$To   = "cbrennan@eci.com"
    #$CC   = "sdesimone@eci.com"
    $SMTP = "qts-outlook.ecicloud.com"

    ### Email Parameters
    $EmailParams = @{
                From       = $From
                To         = $To 
                #CC         = $CC
                SMTPServer = $SMTP
                }

    ### Email Report
    ###--------------------------
    try
    {
       Send-MailMessage @EmailParams -Body ($Report | Out-String) -BodyAsHtml -Subject $ReportName
       write-log "Report Emailed: From: $From To: $To CC: $CC" -ForegroundColor Green
    }
    catch
    {
        write-log "Error Emailing Report: SMTP Server: $SMTP" -ForegroundColor Green
    }
 }

 function Build-Report
{
    # Build-Report
    $PSObject      = New-Object PSObject -Property $Hash
    $Report       += $PSObject 
    $global:Report = $Report # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
}

function Export-Report
{
    param(
    [Parameter(Mandatory=$True)][string]$ReportName,
    [Parameter(Mandatory=$True)][array]$Report,
    [Parameter(Mandatory=$False)][switch]$Console,
    [Parameter(Mandatory=$False)][switch]$CSV,
    [Parameter(Mandatory=$False)][switch]$HTML,
    [Parameter(Mandatory=$False)][switch]$Email

    )

    if($Console) {Export-Report-Console}
    if($CSV)     {Export-Report-CSV}        
    if($HTML)    {Export-Report-HTML}
    if($Email)   {Export-Report-Email}
}

function Measure-Script {
    ### Calculates Script Execution Time

    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    Write-Log "`nScript Started At:`t`t" $StartTime -ForegroundColor Gray
    Write-Log "Script Ended At:`t`t" $StopTime -ForegroundColor Gray
    Write-Log "Script Execution Time:`t" $ElapsedTime -ForegroundColor Gray
}

function Reboot-Computer{
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
        Write-Host "You did not enter Y or N!" -foregroundcolor white
        fcnReStartComputer
    }
}

function Get-OSVersion {

    ### Get OS Version
    [string]$global:OSVersion = (Get-CimInstance Win32_OperatingSystem).version    # Option 1: Using WMI to get OS Version
    #[string]$global:OSVersion = [environment]::OSVersion.Version                  # Option 2: Using Environment to get OS Version

}


function Test-InternetConnection {

    $TargetURL = "google-public-dns-a.google.com"
    $TargetIP = "8.8.8.8"

    Write-Host "Testing Internet Connection."
    $TestInternetConnection = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]'{DCB00C01-570F-4A9B-8D69-199FDBA5723B}')).IsConnectedToInternet 
    $PingInternet = Test-Connection $TargetIP -count 1 -quiet


    If ($PingInternet -eq "True")
    {
        Write-Host "Internet Connection is Good."
    }
    elseif($PingInternet -eq "False")
    {
        Write-Host "Internet Connection is not Available."
    }
}

function Detect-MachineType {
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

    Write-Host "Machine: "             $Machine
    Write-Host "MachineType: "         $MachineType
    Write-Host "MachineModel: "        $MachineModel
    Write-Host "MachineManufacturer: " $MachineManufacturer
}

function Check-RequiredlFiles {

    ### Advanced Function using cmdletbinding Methods
    [cmdletbinding()]

    [Parameter(Mandatory=$True, Position=0)]
    [String]$ScriptPath,

    [Parameter(Mandatory=$True, Position=1)]
    [String]$RequiredFiles

    ### This function checks for any files that are required by the script.
    
    Write-Log "Checking for requiried files." -ForegroundColor yellow

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
        Write-Log "Required File Path: $RequiredFilePath"
        
        If((Test-Path -Path $RequiredFilePath) -ne $false) 
        {
            Write-Host "`t`t All Requires Files Exist: " $RequiredFile green
        }
    
        else
        {
            Write-Log "`t`t $RequiredFile file does not exist" -ForegroundColor red
            #Write-Log "The required files must reside in the folder... $ScriptPath" white
            Write-Log "Do you want to exit the script now?... " -ForegroundColor white
            Write-Host -nonewline "Press 'Y' to exit or 'N' to continue the script. " -foregroundcolor -ForegroundColor white
            
            Pause-Script
        }
    }
}

function Import-ExchangeSession {
    ### Check for Existing Session
    $ExchangeSession = Get-PSSession | where { $_.ConfigurationName -eq "Microsoft.Exchange"  -and $_.State -eq 'Opened' }

    if (-not $ExchangeSession) 
    {
        Write-Host "Creating New Session"    
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
        Write-Host "Using Current Session: " $ExchangeSession 
    }
}

#endregion

#region Old Functions
#-----------------------------------------------------------------------------------
function Ask-YesNoExit {
    ### Check for Yes/No answer, and loop if it doesnt get a 'Y' or an 'N'

    function Check-Response
    {
       Write-Host "Do you want to pause the script?"
        Write-Host -nonewline "(Y/N?)" -ForegroundColor white
        $response = read-host

        if ($response -eq "Y") 
        {

            Write-Host "Press any key to continue ..."
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            Write-Log "Exiting script execution . . . " -ForegroundColor White
            exit
        }
        elseif ($response -eq "N")
        {
            Write-Log "Contining script execution . . . " -ForegroundColor White
        }
        elseif (($response -ne "Y") -or ($response -ne "N"))
        {
            Write-Host "You did not enter Y or N!" -ForegroundColor White
            Ask-YesNoExit
        }
    }
    Check-Response
}

function Ask-ContinueScript {
	### Prompt user to Pause the Script

    Write-Host -nonewline "Continue Running the script?"
    Write-Host -nonewline " (Y/N ?)" -ForegroundColor white
    $response = read-host
    $response = $response.ToUpper()

    if ($response -eq "Y")  
    {
        Write-host "Continueing Script Execution."  
    }
    elseif ($response -eq "Y") 
    {
        Write-Host "Exiting the script in 10 seconds. . . " 
        Start-Sleep -sec 10
        Exit
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        Write-Host "You did not enter Y or N!" -foregroundcolor white
        Ask-ContinueScript
    }
}

function Ask-ExitScript {
	### Prompt user to Pause the Script

    Write-Host -nonewline "Do you want to Exit the script?"
    Write-Host -nonewline " (Y/N ?)" -ForegroundColor white
    $response = read-host
    $response = $response.ToUpper()

    if ($response -eq "Y") 
    {
        Write-Host "Exiting the script in 10 seconds. . . " 
        Start-Sleep -sec 10
        Write-Host "Press any key to continue ..."
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Exit
    }
    elseif ($response -eq "N")  
    {
        Write-host "Continueing Script Execution."  
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        Write-Host "You did not enter Y or N!" -foregroundcolor white
        AskExit-Script
    }
}

function Pause-Console {
    # If running in the console, wait for input before closing.
    if ($Host.Name -eq "ConsoleHost")
    {
        Write-Host "Press any key to continue..."
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    }
}

function Check-ConsoleMode ($Msg) {
    ### Check Console Mode.
    if ($Host.Name -eq "ConsoleHost")
    {
        Write-log "Thi Script is running in the PS Console Mode"
    }
    else
    {
        Write-log "This Script is running in the PS ISE Mode"
        #Write-Host $Msg -ForegroundColor Cyan
        #Read-Host -Prompt "Press Enter to continue"
    }
}

function Pause-Script ($message)  {
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

function Ask-YesNo($Prompt, $YesMsg, $NoMsg) {
    ### Current - Stop the Script to Ask Yes or No
        
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
        Write-Host $YesMsg
    }
    elseif($ReadHost -eq "N")
    {
        Write-Host $NoMsg
    }
    elseif (($ReadHost -ne "Y") -or ($ReadHost -ne "N"))
    {
        Write-Host "You did not enter Y or N!" -foregroundcolor white
        Ask-YesNo
    }
}

#endregion    

#region Test Functions
#-----------------------------------------------------------------------------------


#endregion


#region PS Valid Verbs
#---------------------------------
<#

PS P:\> Get-Verb | Sort-Object verb

Verb        Group         
----        -----         
Add         Common        
Approve     Lifecycle     
Assert      Lifecycle     
Backup      Data          
Block       Security      
Checkpoint  Data          
Clear       Common        
Close       Common        
Compare     Data          
Complete    Lifecycle     
Compress    Data          
Confirm     Lifecycle     
Connect     Communications
Convert     Data          
ConvertFrom Data          
ConvertTo   Data          
Copy        Common        
Debug       Diagnostic    
Deny        Lifecycle     
Disable     Lifecycle     
Disconnect  Communications
Dismount    Data          
Edit        Data          
Enable      Lifecycle     
Enter       Common        
Exit        Common        
Expand      Data          
Export      Data          
Find        Common        
Format      Common        
Get         Common        
Grant       Security      
Group       Data          
Hide        Common        
Import      Data          
Initialize  Data          
Install     Lifecycle     
Invoke      Lifecycle     
Join        Common        
Limit       Data          
Lock        Common        
Measure     Diagnostic    
Merge       Data          
Mount       Data          
Move        Common        
New         Common        
Open        Common        
Optimize    Common        
Out         Data          
Ping        Diagnostic    
Pop         Common        
Protect     Security      
Publish     Data          
Push        Common        
Read        Communications
Receive     Communications
Redo        Common        
Register    Lifecycle     
Remove      Common        
Rename      Common        
Repair      Diagnostic    
Request     Lifecycle     
Reset       Common        
Resize      Common        
Resolve     Diagnostic    
Restart     Lifecycle     
Restore     Data          
Resume      Lifecycle     
Revoke      Security      
Save        Data          
Search      Common        
Select      Common        
Send        Communications
Set         Common        
Show        Common        
Skip        Common        
Split       Common        
Start       Lifecycle     
Step        Common        
Stop        Lifecycle     
Submit      Lifecycle     
Suspend     Lifecycle     
Switch      Common        
Sync        Data          
Test        Diagnostic    
Trace       Diagnostic    
Unblock     Security      
Undo        Common        
Uninstall   Lifecycle     
Unlock      Common        
Unprotect   Security      
Unpublish   Data          
Unregister  Lifecycle     
Update      Data          
Use         Other         
Wait        Lifecycle     
Watch       Common        
Write       Communications
#>
#endregion

#Region Script Template

#region Old Script Template
#-----------------------------------------------------------------------------------
### START FUNCTION: This Function is a Template for all Functions
function Function-Template {
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
#endregion

function Test-Function {
    $global:CMDs = @()
    $CMDs += "Bad-Command"
    $CMDs += "Get-ChildItem -Path 'z:\badDir' # -ErrorAction SilentlyContinue"
    $CMDs += Write-Log "test" "hjgh" -ForegroundColor cyan #-Quiet
   
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

function Execute-Script {
    BEGIN {
         # Initialize Script
        #--------------------------
        Clear-Host
        Write-Log "Running BEGIN Block" -ForegroundColor Blue
        Import-CBrennanModule
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS {
        Write-Log "Running PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        Throw-Errors

}

    END {
        Write-Log "Running END Block"  -ForegroundColor Blue

        # Export Reports
        #--------------------------
        Write-Host $CMDs
        Export-Report-Console "Cmds" $Cmds
        #Export-Report-CSV
        #Export-Report-HTML
        #Export-Report-EMAIL 

        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing

    }
}

#endregion

