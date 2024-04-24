### Module CommonFunctions - Custom Functions, Templates, and Cmdlets

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

- WhatIf Function
    - Rollback/Undo Function
    - CSV Change/Undo Logging

    elseif (!$WhatIfPreference -OR !$Set)
    elseif (!$WhatIfPreference -AND !$Set)

- Function New-ScriptTemplate

- function New-FunctionTemplate

- Trap-Error Function
     
- Build-Report Function

- Export-Report Function

     - problem passing variable $ReportName 
     - ex: Export-Report -ReportName $ReportName -Report $Report -Console #-CSV #-HTML #-Email

- Update Try/Catch Function
    
    - Test Terminating & Non-Terminating Errors (Try/Catch)

    - Use: if $?
    - Use: if !Error[0]
 
- Module Manifest File
    - Module Version

- Start-Transcribing - FixOccasional Error on Start-Transcript - Cased From Not Closing Log File (script termnination)?

- Add Script-Template to end of CommonFunctions


- ADd Function Help Headers (Usage get-help, Example)


Transcript Error on first run
out-lineoutput : Access to the path 'C:\TranscriptLog_Process-WhatIf_v1.ps1_.log' is denied.
    + CategoryInfo          : NotSpecified: (:) [out-lineoutput], UnauthorizedAccessException
    + FullyQualifiedErrorId : System.UnauthorizedAccessException,Microsoft.PowerShell.Commands.OutLineOutputCommand

#>
#endregion

#region Production Functions
#-----------------------------------------------------------------------------------

function Export-Members 
{
    Export-ModuleMember -Function "*"
    Export-ModuleMember -Cmdlet "*"
    Export-ModuleMember -Variable "*"
    Export-ModuleMember -Alias "*"
}

function Import-Modules 
{
    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\Modules\"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\Modules\"}
    if($env:COMPUTERNAME  -eq "W2K16V2")      {$Module = "\\tsclient\Z\CBrennanScripts\Modules\"}
    
    $Modules = @()
    #$Modules += "CommonFunctions"
    $Modules += "ConfigServer"

    foreach ($Module in $Modules)
    {
        ### Reload Module at RunTime
        if(Get-Module -Name $Module){Remove-Module -Name $Module}

        ### Import the Module
        $ModulePath = $ModulePath + $Module + "\" + $Module + ".psm1"
        Import-Module -Name $ModulePath -DisableNameChecking #-Verbose

        ### Test the Module - Exit Script on Failure
        if( (Get-Module -Name $Module)){Write-Host "Loading Custom Module: $Module" -ForegroundColor Green}
        if(!(Get-Module -Name $Module)){Write-Host "The Custom Module $Module WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
    }
}

function Test-Module ($string) 
{
    Write-Host "Module CBrennanFunctions Exists" -ForegroundColor Green; Write-Host "Test String: $String" -ForegroundColor Green
}

function Get-CBCommands
{
    [CmdletBinding()]
    [Alias("gcbc")]
    param ()
 
    Get-Command -Module CommonFunctions
}

function Set-ScriptVariables 
{

    Write-Host "Setting Script Variables" -ForegroundColor DarkGreen

    ### Standard Script Constants & Variables
    #-------------------------------------------------

    ### Clear the Error Variable Array
    $global:Error.Clear()

    ### Clear all Variables
    ### BE CAREFUL!!!
    ### Get-Variable -Name * | Remove-Variable -Force -ErrorAction SilentlyContinue | Out-Null

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
Set-ScriptVariables 

function Write-Log 
{
    [CmdletBinding()]
    #[CmdletBinding(SupportsShouldProcess=$False)]

    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Message,
    [Parameter(Mandatory = $False, Position = 1)] [string]$String,
    [Parameter(Mandatory = $False, Position = 2)] [string]$String2,
    [Parameter(Mandatory = $False, Position = 3)] [string]$String3,
    [Parameter(Mandatory = $False, Position = 4)] [string]$String4,
    [Parameter(Mandatory = $False)] [string]$ForegroundColor,
    [Parameter(Mandatory = $False)] [switch]$Quiet,
    [Parameter(Mandatory = $False)] [switch]$Whatif = $False
    )
    
    ### Concatenate Message
    $Message = $Message + $String + $String2 + $String3 + $String4
    
    ### Write the Message to the Log File.
    "`n`n*****"   | out-file -filepath $LogFile -append -Whatif:$false # Create Line Break between Log File entries  = $False
    $Message      | out-file -filepath $LogFile -append -Whatif:$false  # Write the Log File Entry

    ### Write the Messages to the Console (or Not if -Quiet is True)
    if (-NOT($Quiet))
    {
        if (-NOT($Foregroundcolor)) {$Foregroundcolor = "White"}

        Write-Host $Message -Foregroundcolor $Foregroundcolor
    }
}

function Start-LogFiles 
{
    # Format the LogFile Timestamp
    $global:TimeStamp  = Get-Date -format "MM_dd_yyyy_hhmmss"
   
    # Create the Log Folder
    $global:LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}

    # Create Log File
    $global:LogFile = $LogPath + "\LogFile_" + $ScriptName + "_" + $TimeStamp + ".log"
    Write-Log "CREATING LOG FILES at:`t" $StartTime "`t`tLogFile: " $LogFile -ForegroundColor Gray

    # Create the Reports Folder
    $global:ReportPath = $ScriptPath + "\Reports" 
    if(!(Test-Path -Path $ReportPath)) {New-Item -ItemType directory -Path $ReportPath | out-null}
}

function Start-Transcribing 
{

    ### Close Any Transcript Files Left Open by Previos Script
    try {Stop-transcript -ErrorAction SilentlyContinue | Out-Null} catch {}  
    
    ### Start Transcript Log File
    if        (($(Get-Host).Name -eq "ConsoleHost") -OR ($((get-host).Version).Major -ge "5"))
    {
        try   {Start-Transcript -path $LogPath"\TranscriptLog_"$ScriptName"_.log" -Force}
        catch {Write-Host "Error Starting Transcript Log" -ForegroundColor Red}
    }
    else      {{Write-Host "No Transaction Log Started: This version of ISE does not support Tranaction Logs." -ForegroundColor DarkRed}}
    }

function Stop-Transcribing 
{
    try {Stop-Transcript -ErrorAction SilentlyContinue | Out-Null} catch {Write-Host "No was Transcript Running"}
}

function Trap-Error 
{
    Write-Log "`n`nError Trapped by Try-Catch: `n"       ('-' * 50)                                      -ForegroundColor Red
    Write-Log "ERRORTRAP: CallStack Command0:`t`t"        $((Get-PSCallStack)[0].Command)                -ForegroundColor Yellow    
    Write-Log "ERRORTRAP: CallStack Command1:`t`t"        $((Get-PSCallStack)[1].Command)                -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Command2:`t`t"        $((Get-PSCallStack)[2].Command)                -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Command3:`t`t"        $((Get-PSCallStack)[3].Command)                -ForegroundColor Yellow
   #Write-Log "ERRORTRAP: CallStack FunctionName:`t"     $((Get-PSCallStack)[2].FunctionName)            -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Location:`t`t"       $((Get-PSCallStack)[1].Location)                -ForegroundColor Yellow
   #Write-Log "ERRORTRAP: CallStack ScriptLineNumber:"   $((Get-PSCallStack)[1].ScriptLineNumber)        -ForegroundColor Yellow
    Write-Log "ERRORTRAP: InvocationInfo.Line:`t`t"      $global:Error[0].InvocationInfo.Line            -ForegroundColor DarkYellow
    Write-Log "ERRORTRAP: Exception.Message:`t`t"        $global:Error[0].Exception.Message              -ForegroundColor Red
    Write-Log "ERRORTRAP: ScriptStackTrace:`t`t"         $global:Error[0].ScriptStackTrace               -ForegroundColor DarkRed
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

function Try-Catch
{

    Param(
    [Parameter(Mandatory = $True,Position = 0)] [ScriptBlock]$ScriptBlock
    )

    ### Define the Try/Catch function to trap errors and write to log & console.

    try
    {
        Write-Log "Try-Catch: Executing Function: " $((Get-PSCallStack)[1].Command) -ForegroundColor DarkYellow
        
        Invoke-Command -ScriptBlock $ScriptBlock -ErrorVariable ErrorVar
        
        ### If Last Command Successfull
        if ($? -eq "$True") #Returns True if last operation Succeeded.
        {
            Write-Log  "Try-Catch: *** SUCCESS *** Executing Function: $((Get-PSCallStack)[1].Command)" -ForegroundColor DarkGreen
        }
        ### If Last Command Failed
        if (-NOT($? -eq "$True")) #Returns False if last operation Failed.
        {
            Write-Log  "Try-Catch: *** ERROR *** Executing Function: $((Get-PSCallStack)[1].Command)" -ForegroundColor Red
        }
        
        <#
        ### If Last Command Failed
        if ($? -eq "$False") #Returns True if last operation succeeded, else False.
        {
            Write-Log  "TRY-CATCH: *** FAILURE *** executing function: $((Get-PSCallStack)[1].Command)" -ForegroundColor Red
        }    
        if(-NOT($Error[0]))
        {
            Write-Log  "TRY-CATCH: *** SUCCESS *** executing function: $((Get-PSCallStack)[1].Command)" -ForegroundColor DarkGreen
        }  
        if($ErrorVar)
        {
            write-warning -Message "Error: $ErrorVar getting ADFS Domain Setiings" -WarningAction Continue
            write-error $ErrorVar
        }        
        #>

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


function NewTry-Catch #($ScriptBlock)
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

function Close-LogFile 
{
    Param([Parameter(Mandatory = $False)][switch]$Quiet)

    ########################################################################
    ### Remember: Clear All Errors at top of Script using $Error.Clear()
    ########################################################################

    ### Write the Entire Error Stack to the Log File
    Write-Log "`n`nOutputting Error Stack to Error Log File:" `n('=' * 50) -ForegroundColor Gray
    Write-Log "`nTotal Error Count:`t" $global:Error.Count -ForegroundColor Yellow

    if ($global:Error.Count -ne 0)
    {
        Write-Log "`nERRORS FOUND: Dumping Error Array to LogFile `n$LogFile" -ForegroundColor Red
        Write-Log "ERROR ARRAY:`t`t " ('=' * 100)  -ForegroundColor Gray -Quiet # Line Break in Error Log
        Write-Log "`t`t "             ('=' * 100)  -ForegroundColor Gray -Quiet # Line Break in Error Log

        foreach ($global:Err in $GLOBAL:Error)
        {
            Write-Log "ERROR STACK ELEMENT:`t`t"                 ('-' * 100)                                        -ForegroundColor Gray        -Quiet:$Quiet   # Line Break in Error Log
            Write-Log "ERROR STACK INDEX:`t`t`t`t`t"             ([array]::indexof($global:Error,$global:Err))      -ForegroundColor Gray        -Quiet:$Quiet
            Write-Log "ERRORTRAP: CallStack Command:`t`t"        $((Get-PSCallStack)[1].Command)                    -ForegroundColor Yellow      -Quiet:$Quiet
            #Write-Log "ERRORTRAP: CallStack FunctionName:`t"     $((Get-PSCallStack)[1].FunctionName)              -ForegroundColor Yellow      -Quiet:$Quiet
            Write-Log "ERRORTRAP: CallStack Location:`t`t"       $((Get-PSCallStack)[1].Location)                   -ForegroundColor Yellow      -Quiet:$Quiet
           #Write-Log "ERRORTRAP: CallStack ScriptLineNumber:"   $((Get-PSCallStack)[1].ScriptLineNumber)           -ForegroundColor Yellow      -Quiet:$Quiet
            Write-Log "ERRORTRAP: InvocationInfo.Line:`t`t"      $global:Error[0].InvocationInfo.Line               -ForegroundColor DarkYellow  -Quiet:$Quiet
            Write-Log "ERRORTRAP: Exception.Message:`t`t"        $global:Error[0].Exception.Message                 -ForegroundColor Red         -Quiet:$Quiet
            Write-Log "ERRORTRAP: ScriptStackTrace:`t`t"         $global:Error[0].ScriptStackTrace                  -ForegroundColor DarkRed     -Quiet:$Quiet
        }
    }
    if ($global:Error.Count -eq 0)
    {
        Write-Host "`nNo Errors Found!" -ForegroundColor Green
    }
    
    Write-Log "`nCLOSING LOG FILE At:`t"  $(Get-Date) `n('=' * 50) -ForegroundColor Gray
}

function Process-WhatIf
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Target,
    [Parameter(Mandatory = $True, Position = 1)] [string]$CommitValue,
    [Parameter(Mandatory = $True, Position = 1)] [string]$UndoValue,
    [Parameter(Mandatory = $True)][scriptblock]$CommitScriptBlock,
    [Parameter(Mandatory = $True)][scriptblock]$UndoScriptBlock,
    [Parameter(Mandatory = $False)][switch]$Commit,
    [Parameter(Mandatory = $False)][switch]$Force,
    [Parameter(Mandatory = $False)][switch]$RollBack
    )

    ### Configure "Whatif" $Results
    #---------------------------------------------
    $WhatifFile = $LogPath + "\Whatif_Log_" + $ScriptName + "_" + $TimeStamp + ".txt"
    $Results = "`tTARGET:  " + $Target + "   `n`tVALUE:   " + $CommitValue
    [string]$CommitCommand = ((($CommitScriptblock -replace 'Target', $Target) -replace 'CommitValue', $CommitValue) -replace [char]36,$NULL)
    $CommitCommand = $CommitCommand.Replace('$','')

    ### Configure "Commit" Process
    #---------------------------------------------
    $CommitLog = $LogPath + "\Commit_Log_" + $ScriptName + "_" + $TimeStamp + ".txt"
    
    ### Configure "Undo" Process
    #---------------------------------------------
    $UndoLog = $LogPath + "\Undo_Log_" + $ScriptName + "_" + $TimeStamp + ".txt"
    [string]$UndoCommand = ((($UndoScriptBlock -replace 'Target', $Target) -replace 'UndoValue', $UndoValue) -replace [char]36,$NULL)
    $UndoCommand = $UndoCommand.Replace('$','')

    ### Configure "RollBack" Process
    #---------------------------------------------
    $RollBackData = @()
    $RollBackFile = $LogPath + "\" + "RollBack_Log_" + $ScriptName + "_" + $TimeStamp + ".txt"


    ###############################################################
    ### If No "-Whatif or "-Confirm" Flag used then -- Do nothing
    ###############################################################
    if (!$WhatIfPreference -AND !$Commit -AND !$RollBack)
    {
        Write-Host "This funtion $FunctionName must be run with the switch -Whatif or -Commit." -ForegroundColor Yellow
    }
    elseif ($WhatIfPreference -AND $Commit -AND !$RollBack)
    {
        Write-Host "This funtion $FunctionName must be run with ONLY ONE switch -Whatif or -Commit." -ForegroundColor Yellow
    }

    ###########################
    ### "Whatif" Flag is True
    ###########################
 
    elseif ($WhatIfPreference)
    {
        Write-Log "WHATIF Flag is True: Running Whatif Process ...." -ForegroundColor Green

        ### Write the Command & Results
        #--------------------------------- 
        Write-Log "WHATIF RESULTS:`n $Results" -ForegroundColor Yellow
        Write-Log "WHATIF COMMAND: $Command"-ForegroundColor Yellow
        
        ### Log Command and Results
        #---------------------------------
        "WHATIF COMMAND: " + $Command | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
        "WHATIF RESULTS: " + $Results | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
    }

    ###########################
    ### "Commit" Flag is True
    ###########################
    elseif ($Commit)
    {
        Write-Log "COMMIT Flag is True: Running Commit Commands ...." -ForegroundColor Green
        
        ### Validate Target is a Single Object
        #--------------------------------------------------------
        if($Target -IsNot [System.Array] -and $Target.count -eq 1) 
        {
            Write-log "Validated: Target is a Single Object" -ForegroundColor DarkYellow
            
            ### Write the Command & Results
            #---------------------------------
            
            Write-Log "WHATIF RESULTS:`n $Results" -ForegroundColor Yellow -Whatif:$false
            Write-Log "COMMIT COMMAND:`n $CommitCommand" -ForegroundColor Yellow

            ### Log Command and Results
            #---------------------------------
            "SET COMMAND: "+ $CommitCommand | Out-file -FilePath $CommitLog -Append -Force -Whatif:$false

            #######################################
            ### Create Rollback File
            #######################################

            write-log "Creating RollBack Data File" -ForegroundColor Cyan

            # Build Hash Table for RollBackData
            #------------------------------------

            $RollBackHash    = [ordered]@{            
                Target       = $Target
                CommitValue  = $CommitValue
                UndoValue    = $UndoValue
            }                           
            $PSObject             = New-Object PSObject -Property $RollBackHash
            $RollBackData        += $PSObject 
            $RollBackData | Export-Csv -Path $RollBackFile -NoTypeInformation -NoClobber -Append
            #$RollBackData | Out-file -FilePath $RollBackFile -Append -Force -Whatif:$false

            #######################################
            ### Undo Command                        
            #######################################
            Write-Log "UNDO COMMAND:`n`t$UndoCommand" -ForegroundColor Yellow
            $UndoCommand = $UndoCommand.trim()
            $UndoCommand | Out-file -FilePath $UndoLog -Append -Force -Whatif:$false
                        
            #######################################
            ### Execute Commit Scriptblock Commands
            #######################################
            try
            {
                if (!$Force)
                {
                    write-Log "Confirm is Turned ON. All Commits must be confirmed." -foregroundcolor Green
                    if ($PSCmdlet.ShouldProcess($param)) 
                    {
                        Invoke-Command $CommitScriptblock
                    }
                }
                if ($Force)
                {
                    write-Log "Force Run was specified. ALL COMMIT Commands will run without Confirmation." -foregroundcolor Red
                    Invoke-Command $CommitScriptblock
                }
            }
            catch
            {
                Write-Log "Error Executing CommitScriptblock" -ForegroundColor Red
                Write-Log $Error[0] yellow
                Write-Log "Catch: $($PSItem.ToString())" yellow
            }
        }
    }
    elseif($RollBack)
    {
        Write-Log "RollBack Switch is True: Rolling back changes!" -ForegroundColor Red

        $RollBackFile = Read-Host -prompt "Enter RollBack File Full Path & FileName:"
        $RollBackElements = Import-CSV -Path $RollBackFile

        foreach ($Element in $RollBackElements)
        {
            write-host $UndoCommand
        }


    }
}

function Export-Report-Console 
{
    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report
        )
    ### Export Report to Console
    ### -------------------------------
    Write-Host "`n`nReport Name: $ReportName" -ForegroundColor Yellow
    $Report | Format-Table -AutoSize
    Write-Host $ReportName "Total Count: " $Report.count
}

function Export-Report-CSV 
{

    param(
        [Parameter(Mandatory=$True)][string]$ReportName,
        [Parameter(Mandatory=$True)][array]$Report
        )

    ### Export Report to TXT/CSV File
    ### -------------------------------
    $ReportDate = Get-Date -Format dd_mm_yyyy_hh-mm-ss
    $ReportFile = $ReportPath + "\" + "Report_" + $ReportName + "_" + $ReportDate + ".txt"
    $Report | Export-Csv -Path $ReportFile -NoTypeInformation 
    Write-Log "Report Exported: $ReportFile" -ForegroundColor Green
    start-process $ReportFile
}

function Export-Report-HTML 
{
    
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
    Write-Log "Report Exported: $ReportFile" -ForegroundColor Green
    start-process $ReportFile

 }

function Export-Report-Email 
{
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
       Write-Log "Report Emailed: From: $From To: $To CC: $CC" -ForegroundColor Green
    }
    catch
    {
        Write-Log "Error Emailing Report: SMTP Server: $SMTP" -ForegroundColor Green
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

function Measure-Script 
{
    ### Calculates Script Execution Time

    $StopTime = Get-Date
    $ElapsedTime = ($StopTime-$StartTime)
    Write-Log "`nScript Start Time:`t`t" $StartTime -ForegroundColor Gray
    Write-Log "Script End Time:`t`t" $StopTime -ForegroundColor Gray
    Write-Log "Script Execution Time:`t" $ElapsedTime -ForegroundColor Gray
}

function Reboot-Computer
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
        Write-Host "You did not enter Y or N!" -foregroundcolor white
        fcnReStartComputer
    }
}

function Get-OSVersion 
{

    ### Get OS Version
    [string]$global:OSVersion = (Get-CimInstance Win32_OperatingSystem).version    # Option 1: Using WMI to get OS Version
    #[string]$global:OSVersion = [environment]::OSVersion.Version                  # Option 2: Using Environment to get OS Version

}


function Test-InternetConnection 
{

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

    Write-Host "Machine: "             $Machine
    Write-Host "MachineType: "         $MachineType
    Write-Host "MachineModel: "        $MachineModel
    Write-Host "MachineManufacturer: " $MachineManufacturer
}

function Check-RequiredlFiles 
{

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

function Import-ExchangeSession 
{
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
function Ask-YesNoExit 
{
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

function Ask-ContinueScript 
{
	### Prompt user to Pause the Script

    Write-Host -nonewline "Continue Running the script?"
    Write-Host -nonewline " (Y/N ?)" -ForegroundColor white
    $response = read-host
    $response = $response.ToUpper()

    if ($response -eq "Y")  
    {
        Write-Host "Continueing Script Execution."  
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

function Ask-ExitScript 
{
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
        Write-Host "Continueing Script Execution."  
    }
    elseif (($response -ne "Y") -or ($response -ne "N")) 
    {
        Write-Host "You did not enter Y or N!" -foregroundcolor white
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
        Write-Log "Thi Script is running in the PS Console Mode"
    }
    else
    {
        Write-Log "This Script is running in the PS ISE Mode"
        #Write-Host $Msg -ForegroundColor Cyan
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

function Ask-YesNo($Prompt, $YesMsg, $NoMsg) 
{
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

#region Test/Development Functions
#-----------------------------------------------------------------------------------

function New-FunctionTemplate
{
<# 
    [CmdletBinding()]
    [Alias("gcb")]
   
    param ()

 
    BEGIN 
    {
    
    }
    
    PROCEES 
    {
    
    }
    
    END 
    {
    
    }
#>
}

function New-Function2 
{

$name= Read-Host "What do you want to call the new function?"

$functionText=@"
 #requires -version 4.0

# -----------------------------------------------------------------------------
# Script: $name.ps1
# Author: $env:username 
# Date: $((get-date).ToShortDateString())
# Keywords:
# Comments:
#
# -----------------------------------------------------------------------------

Function $name {

<#
   .Synopsis
    This... 
    .Description
    A longer explanation
     .Parameter FOO 
    The parameter...
   .Example
    PS C:\> FOO
    Example- accomplishes 
  
   .Notes
    NAME: $Name
    VERSION: 1.0
    AUTHOR: Jeffery Hicks
    LASTEDIT: $(Get-Date)
    
        
   .Link
    
   .Inputs
    
   .Outputs

#>

[cmdletBinding()]

Param(
[Parameter(Position=0,Mandatory=`$False,ValueFromPipeline=`$True)]
[string[]]`$FOO

)

Begin {
    Write-Verbose "`$(Get-Date) Starting `$(`$myinvocation.mycommand)"

} #close Begin

Process {
    Foreach (`$item in `$FOO) {
    
    
    
    }#close Foreach item

} #close process

End {
    Write-Verbose  "`$(Get-Date) Ending `$(`$myinvocation.mycommand)"
} #close End

} #end Function
 
 
"@

$psise.CurrentFile.Editor.InsertText($FunctionText)

} #end function

Function New-ScriptTemplate
{
<# 
.DESCRIPTION 
    Create a new blank script from CBrennan-Template

.PARAMETER InstallMenu 
    Specifies if you want to install this as a PSIE add-on menu 

.PARAMETER ScriptName 
    This is the name of the new script. 

.EXAMPLE 
    New-Script -ScriptName "New-ImprovedScript" 
                
    Description 
    ----------- 
    This example shows calling the function with the ScriptName parameter 

.EXAMPLE 
    New-Script -InstallMenu $true 
#>



}

function Test-IsAdministrator
{
    param() 
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-OSVersion-Switch
{
    $OS = Get-WmiObject Win32_OperatingSystem -computerName $computer -Impersonation Impersonate -Authentication PacketPrivacy

    Switch -regex ($os.Version)
    {
        "5.1.2600" { "Windows XP" }
        "5.1.3790" { "Windows Server 2003" }
        "6.0.6001" {
            if ($os.ProductType -eq 1) {
                "Windows Vista"
            } else {
                "Windows Server 2008"
            }
        } 
        "6.1."    { "Windows 7" }
        DEFAULT { Throw "Version not listed" }
    }
}


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
#endregion

function Test-Function 
{
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

function Execute-Script 
{
    BEGIN {
         # Initialize Script
        #--------------------------
        Clear-Host
        Write-Log "Running BEGIN Block" -ForegroundColor Blue
        Import-Modules
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

### 4/29/18
#######################################
<#
function Import-CommonFunctions 
    {
    ### Reload Module at RunTime
    if(Get-Module -Name "CommonFunctions"){Remove-Module -Name "CommonFunctions"}

    ### Set the Module Location
    if($env:USERDNSDOMAIN -eq "ECILAB.NET")   {$Module = "\\tsclient\P\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECICLOUD.COM") {$Module = "\\tsclient\P\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    if($env:USERDNSDOMAIN -eq "ECI.CORP")     {$Module = "\\eci.corp\dfs\nyusers\cbrennan\CBrennanScripts\CommonFunctions\CommonFunctions\CommonFunctions.psm1"}
    
    ### Import the Module
    Import-Module -Name $Module -DisableNameChecking #-Verbose
    
    ### Test the Module - Exit Script on Failure
    if( (Get-Module -Name "CommonFunctions")){Write-Host "Loaded Custom Module: CommonFunctions" -ForegroundColor Green}
    if(!(Get-Module -Name "CommonFunctions")){Write-Host "The Custom Module CommonFunctions WAS NOT Loaded! `nFunctions Wont Work! `nExiting Script!" -ForegroundColor Red;exit}
}

function Throw-Errors 
{
    $CMDs = @()
    #$CMDs += "Bad-Command"
    #$CMDs += "Test-Command"
    #$CMDs += "Get-ChildItem -Path 'z:\BadDir' # -ErrorAction SilentlyContinue"
    $CMDs += Write-Log "Date: `t" (Get-Date) -ForegroundColor cyan #-Quiet

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

function Test1-Example 
{
    ### Create Report Array
    $Report = @()

    ### Create Report Name
    $script:ReportName = ($MyInvocation.MyCommand).Name

    ### Custom Function
    $SearchBase = "OU=Users,OU=Hong Kong,DC=eci,DC=corp"
    #$SearchBase = "OU=Users,OU=edlcap,OU=Clients,DC=ecicloud,DC=com"
    $Users = Get-ADUser -Filter * -properties * -SearchBase $SearchBase -SearchScope Subtree #-Identity ""

    foreach ($User in $Users)
    {

        # Build-Report
        #------------------------------
        $Hash = [ordered]@{            
            User       = $User.Name
            Department = $User.Department
        }                           
        $PSObject      = New-Object PSObject -Property $Hash
        $Report       += $PSObject 
        $global:Report = $Report # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
    }
}

function Test2-Example 
{
    ### Create Report Array
    $Report = @()

    ### Create Report Name
    $script:ReportName = ($MyInvocation.MyCommand).Name

    $Services = Get-Service | Where-Object {$_.Name -like "A*"}

    foreach ($Service in $Services)
    {

        # Build Report
        #------------------------------
        $Hash = [ordered]@{            
            User        = $Service.Name
            DisplayName = $Service.DisplayName
            Status      = $Service.Status
        }                           
        
        # Build-Report
        $PSObject      = New-Object PSObject -Property $Hash
        $Report       += $PSObject 
        $global:Report = $Report # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
    }

        Export-Report-Console -ReportName $ReportName -Report $Report

        ### Export Report:
        ### Example Usage: Export-Report -ReportName $ReportName -Report $Report -Console -CSV -HTML -Email
        ### ----------------------------------------------------------------------------------------
        #Export-Report -ReportName "Chris" -Report $Report -Console #-CSV #-HTML #-Email
}

function Execute-Script 
{
   
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-CommonFunctions
        Set-ScriptVariables
        Start-Transcribing 
        Start-LogFiles
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------
        #Throw-Errors
        #Test1-Example
        Test2-Example
    }

    END 
    {
        Write-Log "`nRunning: END Block"  -ForegroundColor Blue

        # Export Reports
        #--------------------------
        #Export-Report-Console -ReportName $ReportName -Report $Report
        #Export-Report-CSV -ReportName $ReportName -Report $Report
        #Export-Report-HTML -ReportName $ReportName -Report $Report
        #Export-Report-EMAIL -ReportName $ReportName -Report $Report -From "cbrennan@eci.com" -To "cbrennan@eci.com"  

        # Close Script
        #--------------------------
        Close-LogFile
        Measure-Script
        Stop-Transcribing
    }
}

Execute-Script


#>

