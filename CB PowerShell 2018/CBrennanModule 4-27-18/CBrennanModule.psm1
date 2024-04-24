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
    if( (Get-Module -Name "CBrennanModule")){write-host "Loading Custom Module: CBrennanModule" -ForegroundColor Green}
    if(!(Get-Module -Name "CBrennanModule")){write-host "The Custom Module CBrennanModule WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Test-Module ($string) {
    write-host "Module CBrennanFunctions Exists" -ForegroundColor Green; write-host "Test String: $String" -ForegroundColor Green
}

function Set-ScriptVariables {
    ### Clear the Error Variable Array
    $global:Error.Clear()

    ### Clear all Variables
    ### BE CAREFUL!!!
    Get-Variable * -scope Global | Remove-Variable -ErrorAction SilentlyContinue | Out-Null
    Get-Variable *
    exit

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
    [Parameter(Mandatory = $False)] [string]$ForegroundColor,
    [Parameter(Mandatory = $False)] [switch]$Quiet
    )

    ### Write the Messages to the Console.
    if (!$Quiet)
    {
        if (!$Foregroundcolor) {$Foregroundcolor = "White"}
        $Message = $Message + $Value
        write-host $Message -Foregroundcolor $Foregroundcolor
    }

    ### Write the Message to the Log File.
    "`n`n*****"   | out-file -filepath $LogFile -append
    $Message      | out-file -filepath $LogFile -append
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
    write-log "*** OPENING LOG FILES at: " $StartTime -ForegroundColor Gray
}

function Start-Transcribing {
    
    try
    {
        # Start Transcript Log File
        if (($(Get-Host).Name -eq "ConsoleHost") -OR ($((get-host).Version).Major -ge "5")){Start-Transcript -path $LogPath"\TranscriptLog_"$ScriptName"_.log" -Force}
        else {write-host "No Transaction Log Started: This version of ISE doesnt support Tranaction Logs."}
    }
    catch
    {
        Write-Host "Error Starting Transcript Log" -ForegroundColor Red
    }
}

function Stop-Transcribing {
    try{Stop-Transcript | Out-Null} catch{write-host "No Transcript Running"}
}

function Trap-Error {
    write-log "`n`nError Trapped by Try-Catch:"
    write-log "ERRORTRAP: Call Stack Command:`t"   $((Get-PSCallStack)[1].Command)      -ForegroundColor Yellow
    write-log "ERRORTRAP: InvocationInfo.Line:`t"  $global:Error[0].InvocationInfo.Line -ForegroundColor Yellow
    write-log "ERRORTRAP: Exception.Message:`t"    $global:Error[0].Exception.Message   -ForegroundColor Red
    write-log "ERRORTRAP: ScriptStackTrace:`t"     $global:Error[0].ScriptStackTrace    -ForegroundColor DarkRed

    # Write Custom Error Messages
    if ($CustomErrMsg) {write-log $CustomErrMsg -ForegroundColor gray}

    <#
    # Debugging:
    #------------------------------------------------------------
    $CallStack = Get-PSCallStack | Select-Object -Property *
    write-log $CallStack.Command
    write-log $CallStack.Location
    write-log $CallStack.Arguments
    write-log $CallStack.ScriptName
    write-log $CallStack.ScriptLineNumber
    write-log $CallStack.InvocationInfo
    write-log $CallStack.Position
    write-log $CallStack.FunctionName
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
        write-log "Executing Function: $FunctionName" yellow
        
        Invoke-Command -ScriptBlock $ScriptBlock
        Invoke-Command -ScriptBlock $ScriptBlock -ErrorVariable ErrorVar
        #Start-Job -ScriptBlock $ScriptBlock
        
        ### Successfully Executed Last Command
        if ($? -eq "$True")
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
    write-log "Outputting Error Stack to Error Log File" -ForegroundColor Cyan
    write-log "`nTotal Error Count:" $global:Error.Count -ForegroundColor Yellow

    if ($global:Error.Count -ne 0)
    {
        write-log "`nErrors Found: Logging Error Array" -ForegroundColor Red

        foreach ($global:Err in $GLOBAL:Error)
        {
           write-log "`n" # Blank Line
           write-log "Error Thrown Command:`t"     $((Get-PSCallStack)[1].Command)                 -ForegroundColor Yellow
           write-log "Error Stack Index No.:`t"    ([array]::indexof($global:Error,$global:Err))   -ForegroundColor Gray
           write-log "InvocationInfo.Line:`t"      $global:Error[0].InvocationInfo.Line            -ForegroundColor DarkYellow
           write-log "Exception.Message:`t`t"      $global:Err.Exception.Message                   -ForegroundColor Red
           write-log "ScriptStackTrace:`t`t"       $global:Err.ScriptStackTrace                    -ForegroundColor DarkRed
        }
    }
    if ($global:Error.Count -eq 0)
    {
        write-host "`nNo Errors Found!" -ForegroundColor Green
    }
    
    write-log "`n`n*** CLOSING LOG FILE at: " $(Get-Date) -ForegroundColor Gray
}

function Export-Report-Console($ReportName, $ReportData) {
    #################################
    ### Export Report to PS Console
    #################################
    write-host "`n`nReport: $global:ReportName" -ForegroundColor Yellow
    $global:ReportData | Format-Table -AutoSize
    write-host $ReportName "Total Count: " $ReportData.count
}

function Export-Report-CSV($ReportName, $ReportData) {
    ###################################
    ### Export Report to TXT/CSV File
    ###################################
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".txt"
    $ReportData | Export-Csv -Path $ReportFile -NoTypeInformation 
    start-process $ReportFile
}

function Export-Report-HTML($ReportName, $ReportData) {
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
    $PreContent = "$ReportName <br> ScriptName: $ScriptFile <br> Report Date/Time: $ReportDate"
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

function Measure-Script {
    ### Calculates Script Execution Time

    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    write-host `n`n
    write-log "Script ended at " $StopTime -ForegroundColor Gray
    write-log "Script Execution Time: " $ElapsedTime -ForegroundColor Gray
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
        write-host "You did not enter Y or N!" -foregroundcolor white
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

    write-host "Machine: "             $Machine
    write-host "MachineType: "         $MachineType
    write-host "MachineModel: "        $MachineModel
    write-host "MachineManufacturer: " $MachineManufacturer
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
        write-log "Required File Path: $RequiredFilePath"
        
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

#endregion

#region Old Functions
#-----------------------------------------------------------------------------------
function Ask-YesNoExit {
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

            write-log "Exiting script execution . . . " -ForegroundColor White
            exit
        }
        elseif ($response -eq "N")
        {
            write-log "Contining script execution . . . " -ForegroundColor White
        }
        elseif (($response -ne "Y") -or ($response -ne "N"))
        {
            write-host "You did not enter Y or N!" -ForegroundColor White
            Ask-YesNoExit
        }
    }
    Check-Response
}

function Ask-ContinueScript {
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

function Ask-ExitScript {
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
        #write-host $Msg -ForegroundColor Cyan
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

#endregion    

#region Test Functions
#-----------------------------------------------------------------------------------


#endregion


#region PS Verbs
#---------------------------------
<#
#Get-Verb
Verb        Group         
----        -----         
Add         Common        
Clear       Common        
Close       Common        
Copy        Common        
Enter       Common        
Exit        Common        
Find        Common        
Format      Common        
Get         Common        
Hide        Common        
Join        Common        
Lock        Common        
Move        Common        
New         Common        
Open        Common        
Optimize    Common        
Pop         Common        
Push        Common        
Redo        Common        
Remove      Common        
Rename      Common        
Reset       Common        
Resize      Common        
Search      Common        
Select      Common        
Set         Common        
Show        Common        
Skip        Common        
Split       Common        
Step        Common        
Switch      Common        
Undo        Common        
Unlock      Common        
Watch       Common        
Backup      Data          
Checkpoint  Data          
Compare     Data          
Compress    Data          
Convert     Data          
ConvertFrom Data          
ConvertTo   Data          
Dismount    Data          
Edit        Data          
Expand      Data          
Export      Data          
Group       Data          
Import      Data          
Initialize  Data          
Limit       Data          
Merge       Data          
Mount       Data          
Out         Data          
Publish     Data          
Restore     Data          
Save        Data          
Sync        Data          
Unpublish   Data          
Update      Data          
Approve     Lifecycle     
Assert      Lifecycle     
Complete    Lifecycle     
Confirm     Lifecycle     
Deny        Lifecycle     
Disable     Lifecycle     
Enable      Lifecycle     
Install     Lifecycle     
Invoke      Lifecycle     
Register    Lifecycle     
Request     Lifecycle     
Restart     Lifecycle     
Resume      Lifecycle     
Start       Lifecycle     
Stop        Lifecycle     
Submit      Lifecycle     
Suspend     Lifecycle     
Uninstall   Lifecycle     
Unregister  Lifecycle     
Wait        Lifecycle     
Debug       Diagnostic    
Measure     Diagnostic    
Ping        Diagnostic    
Repair      Diagnostic    
Resolve     Diagnostic    
Test        Diagnostic    
Trace       Diagnostic    
Connect     Communications
Disconnect  Communications
Read        Communications
Receive     Communications
Send        Communications
Write       Communications
Block       Security      
Grant       Security      
Protect     Security      
Revoke      Security      
Unblock     Security      
Unprotect   Security      
Use         Other 
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

function Throw-Errors
{
    $global:CMDs = @()
    $CMDs += "Bad-Command"
    $CMDs += "Get-ChildItem -Path 'z:\badDir' # -ErrorAction SilentlyContinue"
    $CMDs += write-log "test" "hjgh" -ForegroundColor cyan #-Quiet
    
    
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
        write-log "Running BEGIN Block" -ForegroundColor Blue
        Import-CBrennanModule
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS {
        write-log "Running PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        Throw-Errors

}

    END {
        write-log "Running END Block"  -ForegroundColor Blue

        # Export Reports
        #--------------------------
        write-host $CMDs
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

