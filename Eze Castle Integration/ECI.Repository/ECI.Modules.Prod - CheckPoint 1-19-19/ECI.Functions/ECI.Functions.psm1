### Module CommonFunctions - Custom Functions, Templates, and Cmdlets

###Production Functions
& { 
    ###################################
    ### Set PS Environment Variables
    ###################################
    
    ### Set StrictMode/Debugging
    ### --------------------------------------------
    Set-StrictMode -Version Latest
    Set-PSDebug -Strict # [-Off ][-Trace <Int32>] [-Step] [-Strict]
   
    ### Set Error Action Preference
    ### --------------------------------------------
    $global:ErrorActionPreference  = "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
    #global:$ErrorActionPreference = “SilentlyContinue”
    #global:$ErrorActionPreference = "Continue"
    #global:$ErrorActionPreference = "Inquire"
    #global:$ErrorActionPreference = "Ignore"
    #global:$ErrorActionPreference = "Suspend"

    ### Get PS Version
    ### --------------------------------------------
    $global:PSVersion = $PSVersionTable.PSVersion


    ### Export all Module Members
    #Export-ModuleMember -alias * -function *

    #Write-Host "Initilizing Module: " (Split-Path $PSScriptRoot -Leaf) -ForegroundColor Gray

    ### Standard Script Constants & Variables
    #-------------------------------------------------

    ### Clear the Error Variable Array
   # if($Error){$global:Error.Clear()}

    ### Clear all Variables
    ### --------------------------------------------
    ### BE CAREFUL!!!
    ### This is used for debugging. This can pull the rug out from under PS
    ### Get-Variable -Name * | Remove-Variable -Force -ErrorAction SilentlyContinue | Out-Null

    ### Get Start Time for Measure-Script function
    ### --------------------------------------------
    $global:StartTime = Get-Date

    <#
    ### Get Call Stack Info
    ### --------------------------------------------
    $CallStack = Get-PSCallStack
    $CallStackInvocationInfoName = (Get-PSCallStack)[-1].InvocationInfo.MyCommand.Name
    $CallStackInvocationInfoPath = (Get-PSCallStack)[-1].InvocationInfo.MyCommand.Path
    $CallStackInvocationInfoInvocationName = ((Get-PSCallStack)[-1].InvocationInfo).InvocationName
  
    ### Debugging
    ### --------------------------------------------
    write-host "CallStack: " $CallStack -ForegroundColor DarkMagenta
    write-host "CallStackInvocationInfoName: " $CallStackInvocationInfoName -ForegroundColor Magenta
    write-host "CallStackInvocationInfoPath: " $CallStackInvocationInfoPath -ForegroundColor Magenta 
    write-host "CallStackInvocationInfoInvocationName: " $CallStackInvocationInfoInvocationName -ForegroundColor Magenta
    pause
    #>

    ### Set the Script Path
    ### --------------------------------------------
    #$global:ScriptName  = $CallStackInvocationInfoName
    #$global:ScriptPath = Split-Path -Path $CallStackInvocationInfoPath -Parent
    #write-host "CallStack ScriptName: " $ScriptName -ForegroundColor Yellow
    #write-host "CallStack ScriptPath: " $ScriptPath -ForegroundColor Yellow

    ### OLD Version--- Get the scripts current filename & directory
    #$global:ScriptName  = split-path $MyInvocation.PSCommandPath -Leaf
    #$global:ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent
    #$global:ScriptName  = $CallStackInvocationInfoName
    #$global:ScriptPath  = $CallStackInvocationInfoPath





    ### Get Module Meta Data
    ### --------------------------------------------
<#
    #$ManifestFile = Get-ChildItem (Get-Module $Module).ModuleBase -Filter *.psd1

    if(Test-ModuleManifest -Path $ManifestFile.FullName)
    {
        $ModuleName    = (Get-Module -Name $Module).Name
        $ModuleVersion = (Get-Module -Name $Module).Version
        write-host "Module Manifest Meta Data: " -ForegroundColor DarkMagenta
        write-host "Manifest File: " $Manifest.FullName -ForegroundColor DarkMagenta
        Write-Host "Module Version: $ModuleName  version: $ModuleVersion" -ForegroundColor DarkMagenta

        #Write-Host "Major: " ((Get-Module -Name $Module).Version).Major
        #Write-Host "Minor: " ((Get-Module -Name $Module).Version).Minor
        #Write-Host "Build: " ((Get-Module -Name $Module).Version).Build
        #Write-Host "Revision: " ((Get-Module -Name $Module).Version).Revision
    }
    if (!$Manifest)
    {
        write-host "No Manifest File for this Module: " $Module -ForegroundColor DarkYellow
    }
#>
}


function Get-ECI.Commands
{
    $Modules = Get-Module -ListAvailable ECI*
    
    if($Modules)
    {
    foreach($Module in $Modules)
    {
        Get-Command -Module $Module
    }
    }
    elseif(!$Modules)
    {
        Write-Host "Modules are not Loaded!" -ForegroundColor Red
    }
}

function Write-ErrorStack
{
    Write-Host "PSCallStack       :" $((Get-PSCallStack)[0].Command) -ForegroundColor Red
    Write-Host "Exception.Message :" $_.Exception.Message -ForegroundColor Red
    Write-Host "ScriptStackTrace  :" $_.ScriptStackTrace -ForegroundColor Red
}

function Clear-Variables
{
    ### Clear all Variables
    ### --------------------------------------------
    ### BE CAREFUL!!!
    ### This is used for debugging. This can pull the rug out from under PS
    Write-Host "Clearing All Variables! " -ForegroundColor Yellow
    Get-Variable -Name * | Remove-Variable -Force -ErrorAction SilentlyContinue | Out-Null
    
    ### ????
    #Set-Alias -Name clearvar -Value Clear-Variables
}


function Publish-DevtoStage
{
    $Source = "\\eciscripts.file.core.windows.net\clientimplementation\Development\Modules.Dev"
    $Target = "\\eciscripts.file.core.windows.net\clientimplementation\Staging\Modules.Stage"
    
    Copy-Item -Path $Source -Destination $Target -Recurse -Container -Force

}

function Publish-StagetoProd
{
    $Source = "\\eciscripts.file.core.windows.net\clientimplementation\Staging\Modules.Stage"
    $Target = "\\eciscripts.file.core.windows.net\clientimplementation\Production\Modules.Prod"
    

}

function Publish-DevtoProd
{
    $Source = "\\eciscripts.file.core.windows.net\clientimplementation\Development\Modules.Dev"
    $Target = "\\eciscripts.file.core.windows.net\clientimplementation\Production\Modules.Prod"
    

}

function Import-ECI.Root.ModuleLoader-old
{
    ######################################
    ### Bootstrap Module Loader
    ######################################

    ### Set Execution Policy to ByPass
    Write-Host "Setting Execution Policy: ByPass"
    #Set-ExecutionPolicy Bypass

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
            
    #((Get-PSDrive | Where {((Get-PSDrive).DisplayRoot) -like "\\eciscripts"}) | Remove-PSDrive -Force ) | Out-Null

    if(-NOT((Get-PSDrive -PSProvider FileSystem).Name) -eq "X")
    {
        ####New-PSDrive -Name $RootDrive -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope global
        New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global
    }

    #$PSDrive = New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Persist -Scope Global

    ### Import the Module Loader - Dot Source
    ### ----------------------------------------------------------------------
    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\ECI.Root.ModuleLoader.ps1" -Env dev
}

function Get-CallStack-CommonFunctions
{
    ### Get Call Stack Info
    ### --------------------------------------------
    $CallStack = Get-PSCallStack
    $CallStackInvocationInfoName = (Get-PSCallStack)[-1].InvocationInfo.MyCommand.Name
    $CallStackInvocationInfoPath = (Get-PSCallStack)[-1].InvocationInfo.MyCommand.Path
    $CallStackInvocationInfoInvocationName = ((Get-PSCallStack)[-1].InvocationInfo).InvocationName
  
    ### Debugging
    ### --------------------------------------------
    write-host "CallStack: " $CallStack -ForegroundColor Magenta
    write-host "CallStackInvocationInfoName: " $CallStackInvocationInfoName -ForegroundColor Cyan
    write-host "CallStackInvocationInfoPath: " $CallStackInvocationInfoPath -ForegroundColor Cyan 
    write-host "CallStackInvocationInfoInvocationName: " $CallStackInvocationInfoInvocationName -ForegroundColor Cyan
    pause
}

function Import-ECIModules 
{
    ### Import ECI Modules
    ###--------------------------------------
    $ECIModules = Get-Module -ListAvailable -Name ECI.*
    foreach ($ECIModule in $ECIModules)
    {
        Write-Host "Importing Module: $ECIModule" -ForegroundColor Green
        Import-Module -Name $ECIModule -DisableNameChecking -Global -Force #-Prefix ECI  
    }
}

function Reload-ECI.Modules
{
    ### Import ECI Modules
    ###--------------------------------------
    $ECIModules = Get-Module -ListAvailable -Name ECI.*
    foreach ($ECIModule in $ECIModules)
    {
        Write-Host "Importing Module: $ECIModule" -ForegroundColor Green
        Import-Module -Name $ECIModule -DisableNameChecking -Global -Force 
    }
}

function Update-ECIModuleManifest
{
    [CmdletBinding()]
    [Alias("Update-ECIModule")]
    [Alias("upmod")]

    Param([Parameter(Mandatory = $True)][string]$ModuleName = "ECI.Core.CommonFunctions.Dev")

    write-host "Updating Module: " $ModuleName -ForegroundColor Yellow
    pause

    ### Check for Module Manifest
    $ManifestFile = Get-ChildItem (Get-Module $ModuleName).ModuleBase -Filter *.psd1

    ### No Manifest Exists
    if(!(Test-ModuleManifest -Path $ManifestFile.FullName)) 
    {
        write-host "There is No Manifest File for this Module: " $ModuleName -ForegroundColor DarkYellow
    }

    ### Manifest Exists
    if(Test-ModuleManifest -Path $ManifestFile.FullName)
    {
        ### Import Manifest Data
        $ManifestData = Import-PowerShellDataFile $ManifestFile.FullName
        
        ### Get Manifest Version
        [version]$ManifestVersion = $ManifestData.ModuleVersion
        $ManifestVersion | ft
        
        ### Get Functions from Manifest
        [array]$ManifestFunctions = $ManifestData.FunctionsToExport

        ### Get Functions from Module
        [array]$ModuleFunctions = (Get-Command -Module $ModuleName).Name

        
        ### Check for New Parameters, ALiases, Variables
        <#
        
        Update-ModuleManifest  -CmdletsToExport  '*' -VariablesToExport '*' -AliasesToExport '*' 

        foreach ($ModuleFunction in $ModuleFunctions)
        {
            #Get-Command -Module $Module -Name $ModuleFunction -ArgumentList * | where {$_.Parameters -ne $Null}
            (Get-Command -Module $Module -Name $ModuleFunction -ArgumentList * | where {$_.ParameterSets -ne "{}"})
            #write-host "Function: " $ModuleFunction
            #write-host "Alias: " $ModuleFunction.Alias
           # .Parameters.Keys
        }
        pause
        #>
        

        ### Get Version Version Numbers
        $MajorVersion    = $ManifestVersion.Major
        $MinorVersion    = $ManifestVersion.Minor
        $BuildVersion    = $ManifestVersion.Build
        $RevisionVersion = $ManifestVersion.Revision

        ### Compare Functions: Module has New Functions
       
    write-host "Module:" $Module
    write-host "ModuleFunctions:" $ModuleFunctions 
    write-host "ManifestFunctions:" $ManifestFunctions
    pause

        $Compare = (Compare-Object $ModuleFunctions $ManifestFunctions)
        
        ### If New Functions - Increment the Build Version
        if ($Compare)
        {
            write-host "Incrementing Build Number:" $CompareFunctions -ForegroundColor Gray

            ### Increment the Build Version
            $BuildVersion      = ($ManifestVersion.Build + 1)
            $RevisionVersion   = '0'

            ### New Functions: New Functions in Module
            $FunctionsToExport = $ModuleFunctions 
        }
        
        ### Compare: Module has New Updates - Increment the Revision Version
        elseif (!$Compare)
        {
            write-host "Incrementing Revision Number:" -ForegroundColor Gray
        
            ### Increment the Revision Version
            $RevisionVersion  = ($ManifestVersion.Revision + 1)
        
            ### Same Functions: Manifest
            $FunctionsToExport = $ManifestFunctions 
        }

        ### Increment the Version Numbers
        [version]$NewVersion = "{0}.{1}.{2}.{3}" -f $MajorVersion, $MinorVersion, $BuildVersion, $RevisionVersion 
        #[version]$NewVersion = "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, ($Version.Build + 1) 
        $NewVersion | ft
        
        ### Backup & Archive Modules & Manifest
        ###--------------------------------------
        
        ### Backup Module
        $ModuleFilePath = ($(Get-Module -Name $ModuleName).Path)
        $ModuleBackupFile = ((Get-Module -Name $ModuleName).Path + ".version." + $ManifestVersion)
        Copy-Item -Path $ModuleFilePath -Destination $ModuleBackupFile
        
        ### Backup Manifest
        $ManifestFilePath = $ManifestFile.FullName
        $ManifestBackupFile = ($ManifestFilePath + ".version." + $ManifestVersion)
        Copy-Item -Path $ManifestFilePath  -Destination $ManifestBackupFile

        ### Archive (Zip) Files 
        $ArchiveFolder = ((Get-Module -Name $Module).ModuleBase + "\Archives\")
        $ArchiveFile = $ArchiveFolder + $Module + "_Archives.zip"

        ### Create Archive Folder & File
        if(!(Test-Path $ArchiveFolder)){New-Item -Path $ArchiveFolder -ItemType "directory" -Force | Out-Null}
        if(!(Test-Path $ArchiveFile))  {New-Item -Path $ArchiveFile -ItemType "file" -Force | Out-Null}

        ### Zip Files
        Compress-Archive -LiteralPath $ModuleBackupFile, $ManifestBackupFile -DestinationPath $ArchiveFile -Update
        
        ### Remove Backup Files After Archival
        Remove-Item -Path $ModuleBackupFile, $ManifestBackupFile

        ### Update the Manifest File  
        ###-----------------------------------  
        
        write-host "Updating Manifest File: " $ManifestFile.FullName -ForegroundColor Gray
        #$FunctionsToExport = '*' # Overide Option to Export *ALL* Functions!        
        Update-ModuleManifest -Path ($ManifestFile.FullName) -ModuleVersion $NewVersion -FunctionsToExport $FunctionsToExport -CmdletsToExport  '*' -VariablesToExport '*' -AliasesToExport '*' 
    }
}

function Export-ECIModuleMembers 
{
    Write-Host "Export Custom Module Members"

    Export-ModuleMember -Function "*"
    Export-ModuleMember -Cmdlet "*"
    Export-ModuleMember -Variable "*"
    Export-ModuleMember -Alias "*"

    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
}

function Tail-ECI.Log
{
   
    cls
    $File = $Null

    $Dir = "C:\Scripts\ServerRequest\TranscriptLogs\"

    $Filter = "PowerShell_transcript*.txt"

    #$LatestFile = Get-ChildItem -Path $Dir -Filter $Filter | Sort-Object LastAccessTime -Descending | Select-Object -First 1
    $LatestFile = Get-ChildItem -Path $Dir | Sort-Object LastAccessTime -Descending | Select-Object -First 1

    $File = $Dir + $LatestFile
    #$File = "PowerShell_transcript.ECILAB-BOSDEV02.aXfb2Fv6.20180907084329.txt"

    Write-Host "File: " $File
    Get-Content $File –Wait
}

function Is-Admin
{
    param ($User)

    #are we an administrator or LUA?
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [System.Security.Principal.WindowsPrincipal]($User)
    Return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function IsAdmin
{
    $User = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Return $Role
}

function Pause-Script
{
    [CmdletBinding()]
    [Alias("pause")]

    #$t = 10
    #write-host "Pausing Script for $t seconds . . . "
    #Start-Sleep -Seconds $True

    Param([Parameter(Mandatory = $False)][string]$Msg)
    if($Msg) { Read-Host $Msg }
    Else { Read-Host "Press ENTER to Continue" }
}

function Create-ModuleManifest
{
    [CmdletBinding()]
    [Alias("cm")]
    
    Param([Parameter(Mandatory = $True)] [string]$ModuleName)

    $ModuleName = $ModuleName
    $Args = @{

    #Path = ""
    RootModule  = "$ModuleName.psm1"
    Author = "Chris Brennan"
    CompanyName = "Eze Castle"
    ModuleVersion = "5.18.18" 
    Description = "Library of Common Functions"
    #PowerShellVersion = ""
    #RequiredModules = ""
    #FileList = ""
    #ModuleList = ""
    #ReleaseNotes = ""
    #ScriptsToProcess = ""
    
    }
    New-ModuleManifest @Args
}

function Get-ECICommands
{
    [CmdletBinding()]
    [Alias("ecicommands")]
    [Alias("commonfunctions")]
    
    param ($Module)
    
    if ($Module)
    {
        Get-Command -Module $Module
    }
    elseif (!$Module)
    {
        Get-Command -Module ECI.Core.CommonFunctions.$Env
    }    
}

function Get-MyCallStack-deleteme #-deleteme????
{
    $CallStack = Get-PSCallStack | Select-Object -Property *
    if($CallStack.Count -eq 1)
    {
        $CallStack = $CallStack[0]
    }
    else
    {
        $CallStack = $CallStack[($CallStack.Count - 1)] 
    }

    if ($CallStack.Command -eq "<ScriptBlock>")
    {
        $global:ScriptName = "VMAutomation"
    }
    else
    {
        $global:ScriptName = (Split-Path ($CallStack).ScriptName -leaf).Split(".")[0]
    }

    <#
    $hash = @{            
        Command   = $CallStack.Command
        ScriptName = $CallStack.ScriptName 
    } 
    $MyCallStack = New-Object PSObject -Property $hash 
    #>

    #$MyCallStack.Command

    #write-host "CallStack: " $CallStack -ForegroundColor Gray
    #write-host "CallStack.Command: " $CallStack.Command -ForegroundColor Gray
    #write-host "CallStack.ScriptName: " $CallStack.ScriptName -ForegroundColor Gray
    #write-host "ScriptName: " $ScriptName -ForegroundColor Gray
}
########################################################################

function Write-Log
{
    [CmdletBinding()]

    Param(
    [Parameter(Mandatory = $True,  Position = 0)] [string]$Message,
    [Parameter(Mandatory = $False, Position = 1)] [string]$String1,
    [Parameter(Mandatory = $False, Position = 2)] [string]$String2,
    [Parameter(Mandatory = $False, Position = 3)] [string]$String3,
    [Parameter(Mandatory = $False, Position = 4)] [string]$String4,
    [Parameter(Mandatory = $False, Position = 5)] [string]$String5,
    [Parameter(Mandatory = $False, Position = 6)] [string]$String6,
    [Parameter(Mandatory = $False)] [string]$ForegroundColor,
    [Parameter(Mandatory = $False)] [switch]$Quiet,
    [Parameter(Mandatory = $False)] [switch]$Whatif = $False
    )

    function Start-Logs
    {
        ### ScriptName
        ### -------------------------------------------
        #$CallStack = Get-PSCallStack | Select-Object -Property Command
            
        $CallStack = (Get-PSCallStack).Command 
        $CallStack = ($CallStack | Where-Object {$_ -like "*.PS1"})[-1]
        $global:ScriptName = $CallStack
            
        ### Create Timestamp
        $global:TimeStamp  = Get-Date -format "MM-dd-yyyy_hh_mm_ss"

        ### Output Path
        ### -------------------------------------------
        $OutputPath = "C:\Scripts\Logs"

        ### Create Log Folder
        ### -------------------------------------------
        $global:LogPath = $OutputPath + "\LogFiles\" + $ScriptName
        Write-host "LogPath: " $LogPath
        if(-NOT(Test-Path -Path $LogPath)) {(New-Item -ItemType directory -Path $LogPath -Force | out-null)}

        ### Create Log File
        ### -------------------------------------------
        $global:LogFile = $LogPath + "\LogFile_" + $ScriptName + "_" + $TimeStamp + ".log"
        Write-Host "CREATING LOG FILES at: $LogFile"  -ForegroundColor Gray
        if(!(Test-Path -Path $LogFile)) {New-Item -ItemType file -Path $LogFile | out-null}

        ### Create the Reports Folder
        ### -------------------------------------------
        $global:ReportPath = $OutputPath + "\Reports\" + $ScriptName + "\"
        if(!(Test-Path -Path $ReportPath)) {New-Item -ItemType directory -Path $ReportPath | out-null}
    }
    
    if (((Get-Variable 'LogFile' -Scope Global -ErrorAction 'Ignore')) -eq $Null)    #if (-NOT($LogFile))
    {
        #Write-Host "No Logfile exists. Starting Log Files:" -ForegroundColor Gray
        Start-Logs
    }
    else
    {
        #Write-Host "Logfile exists." -ForegroundColor Gray
    }

    ### Concatenate Message
    $Message = $Message + $String1 + $String2 + $String3 + $String4 + $String5 + $String6
    
    ### Write $Message to the Log File.
    $LineBreak = "`n`n ----------------------------------------------------------"
    $LineBreak | out-file -filepath $LogFile -append -Whatif:$false  ### Create Line Break between Log File entries  = $False
    $Message   | out-file -filepath $LogFile -append -Whatif:$false  ### Write the Log File Entry

    ### Write the Messages to the Console (or Not if -Quiet is True)
    if (-NOT($Quiet))
    {
        if (-NOT($Foregroundcolor)) {$Foregroundcolor = "White"}
        ### Write Console Message
        Write-Host $Message -Foregroundcolor $Foregroundcolor
    }
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

########################################################################


function Start-Logs-orig
{
    Get-MyCallStack

    ### Create Timestamp
    $global:TimeStamp  = Get-Date -format "MM-dd-yyyy_hh_mm_ss"

    ### Set Output Path
    if($ScriptName -eq "VMAutomation")
    {
        ### Create OutputPath
        ### -------------------------------------------
        $OutputPath = "\\eciscripts.file.core.windows.net\clientimplementation\_VMAutomationLogs\$VM"

        ### Create Log Folder
        ### -------------------------------------------
        $global:LogPath = $OutputPath
        #if(-NOT(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path -Force $LogPath | Out-Null}
        if(-NOT(Test-Path -Path $LogPath)) {(New-Item -ItemType directory -Path $LogPath -Force | out-null);Write-Host "Creating LogPath: " $LogPath }
        ### Create Log File
        ### -------------------------------------------
        $global:LogFile = $LogPath + "\LogFile_" + $VM + "_" + $TimeStamp + ".log"
        Write-Host "CREATING LOG FILE:" $StartTime "`nLogFile: " $LogFile -ForegroundColor Gray
    }
    else
    {
        ### Create OutputPath
        ### -------------------------------------------
        $OutputPath = $EnvPath + "\_OutputFiles"

        ### Create Log Folder
        ### -------------------------------------------
        $global:LogPath = $OutputPath + "\Logs\" + $ScriptName
        if(-NOT(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | Out-Null}

        ### Create Log File
        ### -------------------------------------------
        $global:LogFile = $LogPath + "\LogFile_" + $ScriptName + "_" + $TimeStamp + ".log"
        Write-Host "CREATING LOG FILES at:`t" $StartTime "`t`tLogFile: " $LogFile -ForegroundColor Gray
    
        ### Create the Reports Folder
        ### -------------------------------------------
        $global:ReportPath = $OutputPath + "\Reports\" + $ScriptName + "\"
        if(!(Test-Path -Path $ReportPath)) {New-Item -ItemType directory -Path $ReportPath | out-null}
    }
}

function Write-Log-orig
{
    [CmdletBinding()]

    Param(
    [Parameter(Mandatory = $True,  Position = 0)] [string]$Message,
    [Parameter(Mandatory = $False, Position = 1)] [string]$String1,
    [Parameter(Mandatory = $False, Position = 2)] [string]$String2,
    [Parameter(Mandatory = $False, Position = 3)] [string]$String3,
    [Parameter(Mandatory = $False, Position = 4)] [string]$String4,
    [Parameter(Mandatory = $False, Position = 5)] [string]$String5,
    [Parameter(Mandatory = $False, Position = 6)] [string]$String6,
    [Parameter(Mandatory = $False)] [string]$ForegroundColor,
    [Parameter(Mandatory = $False)] [switch]$Quiet,
    [Parameter(Mandatory = $False)] [switch]$Whatif = $False
    )
    
    if (((Get-Variable 'LogFile' -Scope Global -ErrorAction 'Ignore')) -eq $Null)    #if (-NOT($LogFile))
    {
        #Write-Host "No Logfile exists. Starting Log Files:" -ForegroundColor Gray
        Start-Logs
    }
    else
    {
        #Write-Host "Logfile exists." -ForegroundColor Gray
    }

    ### Concatenate Message
    $Message = $Message + $String1 + $String2 + $String3 + $String4 + $String5 + $String6
    
    ### Write $Message to the Log File.
    $LineBreak = "`n`n ----------------------------------------------------------"
    $LineBreak | out-file -filepath $LogFile -append -Whatif:$false  ### Create Line Break between Log File entries  = $False
    $Message   | out-file -filepath $LogFile -append -Whatif:$false  ### Write the Log File Entry

    ### Write the Messages to the Console (or Not if -Quiet is True)
    if (-NOT($Quiet))
    {
        if (-NOT($Foregroundcolor)) {$Foregroundcolor = "White"}
        ### Write Console Message
        Write-Host $Message -Foregroundcolor $Foregroundcolor
    }
}



function Trap-Error 
{
    $CallStack = Get-PSCallStack
    $CallStack = $CallStack[-1].Location

    Write-Log "`n`nERRORTRAP: Trapped by Try-Catch `n"   ('-' * 50)                                      -ForegroundColor Red
    Write-Log "ERRORTRAP: CallStack Command0:`t`t"       $((Get-PSCallStack)[0].Command)                 -ForegroundColor Yellow    
    Write-Log "ERRORTRAP: CallStack Command1:`t`t"       $((Get-PSCallStack)[1].Command)                 -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Command2:`t`t"       $((Get-PSCallStack)[2].Command)                 -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Command3:`t`t"       $((Get-PSCallStack)[3].Command)                 -ForegroundColor Yellow
   #Write-Log "ERRORTRAP: CallStack FunctionName:`t"     $((Get-PSCallStack)[2].FunctionName)            -ForegroundColor Yellow
    Write-Log "ERRORTRAP: CallStack Location:`t`t"       $((Get-PSCallStack)[1].Location)                -ForegroundColor Yellow
   #Write-Log "ERRORTRAP: CallStack ScriptLineNumber:"   $((Get-PSCallStack)[1].ScriptLineNumber)        -ForegroundColor Yellow
    Write-Log "ERRORTRAP: InvocationInfo.Line:`t`t"      ($global:Error[0].InvocationInfo.Line).Trim()   -ForegroundColor DarkYellow
    Write-Log "ERRORTRAP: Exception.Message:`t`t"        $global:Error[0].Exception.Message              -ForegroundColor Red
    Write-Log "ERRORTRAP: ScriptStackTrace:`t`t"         $global:Error[0].ScriptStackTrace               -ForegroundColor DarkRed
    Write-Log "ERRORTRAP: End Try-Catch Error Trap `n"   ('-' * 50)                                      -ForegroundColor Red

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
    [Parameter(Mandatory = $True,Position = 0)] [ScriptBlock]$ScriptBlock,
    [Parameter(Mandatory = $False)] [switch]$Quiet
    )
 

    ### USEAGE:
    ###         Try-Catch $Scriptblock


    if ($Quiet)
    {    
        Write-Log "Try-Catch: EXECUTING FUNCTION: " $((Get-PSCallStack)[1].Command) -Quiet
    }
    elseif(-NOT($Quiet))
    {
        Write-Log "Try-Catch: EXECUTING FUNCTION: " $((Get-PSCallStack)[1].Command) -ForegroundColor DarkYellow
    }

    ### Define the Try/Catch function to trap errors and write to log & console.
    try
    {
        Invoke-Command -ScriptBlock $ScriptBlock -ErrorVariable ErrorVar
        
        ### If Last Command Successfull
        if ($? -eq "$True") #Returns True if last operation Succeeded.
        {
            if ($Quiet)
            {
                Write-Log  "Try-Catch: *** SUCCESS *** EXECUTING FUNCTION: $((Get-PSCallStack)[1].Command)" -Quiet
            }
            elseif(-NOT($Quiet))
            {
                Write-Log  "Try-Catch: *** SUCCESS *** EXECUTING FUNCTION: $((Get-PSCallStack)[1].Command)" -ForegroundColor DarkGreen
            }
        }
        ### If Last Command Failed
        if (-NOT($? -eq "$True")) #Returns False if last operation Failed.
        {
            if ($Quiet)
            {
                Write-Log  "Try-Catch: *** ERROR *** EXECUTING FUNCTION: $((Get-PSCallStack)[1].Command)" -Quiet
            }
            elseif(-NOT($Quiet))
            {
                Write-Log  "Try-Catch: *** ERROR *** EXECUTING FUNCTION: $((Get-PSCallStack)[1].Command)" -ForegroundColor Red
            }
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
        #$($_.Exception.Message)
        #Write-Debug "Ping to $TargetIPAddress threw exception: $($_.Exception.Message)"
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
        Write-Log "EXECUTING FUNCTION: $FunctionName" yellow
        
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
    Write-Log `n('=' * 50)
    Write-Log "OUTPUTTING ERROR STACK TO ERROR LOG FILE:" -ForegroundColor Gray
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
    
    Write-Log "`nCLOSING LOG FILE At:`t"  $(Get-Date) -ForegroundColor Gray
    Write-Log ('=' * 50) -ForegroundColor Gray
}

function Invoke-Whatif
{
    [CmdletBinding()]
    param(
          
        [Parameter(Mandatory = $False)][switch] $Whatif,
        [Parameter(Mandatory = $False)][switch] $Commit,
        [Parameter(Mandatory = $False)][switch] $Force,
        [Parameter(Mandatory = $False)][switch] $RollBack
    )   
        
        #################################
        ### Set Required Parameters
        #################################

        <#
        ### Set the $TARGET
        ###--------------------------------------------- 
        $Target      = $Target
        write-host $Target

        ### Set the VALUES
        ###--------------------------------------------- 
        $CommitValue = $CommitValue
        $UndoValue   = $UndoValue

        ### Get ScriptBlock Commands
        ###--------------------------------------------    
        $GetScriptBlock = 
        {
            $GetScriptBlock 
        }

        ### Commit ScriptBlock Commands
        ###--------------------------------------------    
        $CommitScriptBlock = 
        {
            $CommitScriptBlock 
        }

        ### Undo ScriptBlock Commands
        ###---------------------------------------------    
        $UndoScriptBlock = 
        {
           $UndoScriptBlock
        }
        #>

        ### Run Whatif Processs
        ###---------------------------------------------    
     
        ### Pass Arguments with Hash table to pass switches -Whatif, -Commit, -Force, & -RollBack
        $WhatifArguments   = [ordered]@{
            Target             = $Target
            CommitValue        = $CommitValue 
            CommitScriptBlock  = $CommitScriptBlock
            UndoValue          = $UndoValue
            UndoScriptBlock    = $UndoScriptBlock
            Whatif             = $Whatif
            Commit             = $Commit
            Force              = $Force
            RollBack           = $RollBack
        }

        Process-Whatif @WhatifArguments
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
    $Results = "`tTARGETPROPERTY:`t`t" + $TargetProperty + "`n`tTARGETVALUE:`t`t" + $Target + "`n`tCOMMITPROPERTY:`t`t" + $CommitProperty + "`n`tCOMMITVALUE:`t`t" + $CommitValue

    ### Commit Command
    #---------------------------------------------
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
        Write-Log "WHATIF COMMAND: $CommitCommand" -ForegroundColor Yellow
        Write-Log "WHATIF RESULTS:`n $Results" -ForegroundColor Yellow
        
        
        ### Log Command and Results
        #---------------------------------
        "WHATIF COMMAND: " + $CommitCommand | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
        "WHATIF RESULTS: " + $Results       | Out-file -FilePath $WhatifFile -Append -Force -Whatif:$false
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
    #$To  
    $VMTempTest = Get-Template -Name $VMTemplate -ErrorAction SilentlyContinue
    
     = "cbrennan@eci.com"
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

function Test-IsAdministrator
{
    # Get the ID and Security Principal of the Current User Account
    $CurrentWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsID)

    # Get the Security Principal for the Administrator Role
    $AdminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
 
    # Check to see if we are currently running "as Administrator"
    $Elevated = $CurrentWindowsPrincipal.IsInRole($AdminRole)

    if ($Elevated)
    {
        ### We are running "as Administrator"
        Write-Host "ELEVATED: Currently Running with Elevated Privledges" -ForegroundColor White
    }
    if (-NOT($Elevated))
    {
        ### We are NOT running "as Administrator"
        Write-Host "NOT ELEVATED: Not Running with Elevated Privledges"  -ForegroundColor White
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

function Function-Template 
{

}

function Script-Template 
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

function Original_New-FunctionTemplate 
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

$psise.CurrentFile.Editor.InsertText($TextBlock)

}

function New-Function 
{
    [CmdletBinding()]
    [Alias("nf")]
    
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Name
    )

$TextBlock = @"


Function $name {

# -----------------------------------------------------------------------------
#
# Function Name: $Name
# Author: $env:username 
# Date: $((get-date).ToShortDateString())
# Description:
#
# -----------------------------------------------------------------------------

[cmdletBinding()]

    Param(
    [Parameter(Mandatory = $False, Position = 0)] [string]'$String',
    [Parameter(Mandatory = $False)] [switch]'$Switch'
    )

    BEGIN
    {
        Write-Log "EXECUTING FUNCTION:  '$((Get-PSCallStack)[2].Command) `n('-' * 50)'"
    }

    PROCESS
    {
        $ScriptBlock = 
        {
            ### Do-Foo
        }

        Try-Catch $ScriptBlock
    }


    END
    {
        Write-Verbose  "`$(Get-Date) Ending `$(`$myinvocation.mycommand)"
    }

}
"@

$PSISE.CurrentFile.Editor.InsertText($TextBlock)

}

function New-WhatifFuntion 
{
    [CmdletBinding()]
    [Alias("nwif")]
    
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Name
    )

$functionText=@"

<# -----------------------------------------------------------------------------
 WHATIF FUNCTION:

    Function Name: $Name
    Author: $env:username 
    Date: $((get-date).ToShortDateString())
    Description:


    USAGE:  - Must use either -Whatif or -Commit.
            - Can ONLY use EITHER -Whatif or -Commit. Not Both!
            - Force is optional when -Commit is used.

            - Whatif : This switch ONLY runs a whatif and show the result. NO SETS or COMMITS are made.
            - Commit : This switch will Commit the Set command actionss. By default the -Confirm switch is set to on. (You will be prompted to Confirm Actions)
            - Force  : This switch will overide the -Confirm switch and force all commit actions. (You WILL NOT be prompted to Confirm Actions)
            - RollBack  : Rolls back all chanches made by the commit command.

    USAGE:  - Must use either -Whatif or -Commit -Force
            
    EXAMPLES:
                Invoke-Whatif -Whatif 
                Invoke-Whatif -Commit
                Invoke-Whatif -Commit -Force
                Invoke-Whatif -Commit -Rollback

# -----------------------------------------------------------------------------#?

function $Name
{
    ##############################
    ### Get ScriptBlock
    ##############################

    $script:GetScriptBlock =
    {
        ### Do-Something
        ###-----------------------------------------
        Write-Log "Running GetScriptBlock"-foregroundcolor DarkGreen
        $script:Users = Get-ADUser -Identity $User -Properties * | where {(($_.ProxyAddresses).count -ne "0") -AND ($_.UserPrincipalName -ne $Null)}
    }

    ##############################
    ### Commit ScriptBlock
    ##############################

    $global:CommitScriptBlock = 
    {    
        Set-ADUser -Identity $Target -Add @{ProxyAddresses="smtp:$CommitValue"}
    } 

    ##############################
    ### Undo ScriptBlock
    ##############################
    
    $global:UndoScriptBlock = 
    {    
        Set-ADUser -Identity $Target -Remove @{ProxyAddresses="smtp:$UndoValue"}
    }

    ##############################
    ### Execute Commands
    ##############################
    
    $UPNinProxyCounter = 0
    Invoke-Command $GetScriptBlock

    foreach ($User in $Users)
    {
        ############################
        ### Set Target and Values
        ############################

        ### Set Target
        ###------------------------------------------
        $global:TargetProperty = '$User.DistinguishedName'
        $global:Target         = $User.UserPrincipalName
        
        ### Set Commit Value
        ###------------------------------------------
        $global:CommitProperty = '$User.UserPrincipalName'
        $global:CommitValue    = $User.UserPrincipalName
        
        ### Set Undo Value
        ###------------------------------------------
        $global:UndoValue = $CommitValue
        
        ### Find Users with UPN in ProxyAddresses
        $UPNinProxy = ($User.ProxyAddresses -replace "smtp:","").Contains($User.UserPrincipalName)

        if($UPNinProxy -ne $True)
        {
            $UPNinProxyCounter ++

            write-host "UPNinProxy: "  $UPNinProxy -ForegroundColor Gray
            #Write-host "Name: " $User.Name
            #Write-host "Target: $Target `nValue: $CommitValue `nUndoValue: $UndoValue" -ForegroundColor Cyan
            Write-host "ProxyAddresses: " ($User.ProxyAddresses -replace "smtp:","") -ForegroundColor Cyan
            Write-host "UserPrincipalName: " $User.UserPrincipalName -ForegroundColor Cyan
            #write-host "UPNinProxy: " ($User.ProxyAddresses).Contains($User.UserPrincipalName)

            ############################
            ### Invoke-Whatif
            ############################
 
            <######################################################################
                USAGE:  - Must use either -Whatif or -Commit.
                        - Can ONLY use EITHER -Whatif or -Commit. Not Both!
                        - Force is optional when -Commit is used.

                        - Whatif : This switch ONLY runs a whatif and show the result. NO SETS or COMMITS are made.
                        - Commit : This switch will Commit the Set command actionss. By default the -Confirm switch is set to on. (You will be prompted to Confirm Actions)
                        - Force  : This switch will overide the -Confirm switch and force all commit actions. (You WILL NOT be prompted to Confirm Actions)
                        - RollBack  : Rolls back all chanches made by the commit command.

                USAGE:  - Must use either -Whatif or -Commit -Force
            
                EXAMPLES:
                            Invoke-Whatif -Whatif 
                            Invoke-Whatif -Commit
                            Invoke-Whatif -Commit -Force
                            Invoke-Whatif -Commit -Rollback
            <######################################################################>
        
            Invoke-Whatif -Whatif
            #Invoke-Whatif -Commit
            #Invoke-Whatif -Commit -Force
            #Invoke-Whatif -RollBack
        }
        
        if ($UPNinProxyCounter -eq "0")
        {
            write-host "No Objects met the criteries:" 
            write-host "UPNinProxyCounter: "  $UPNinProxyCounter
        }
        
        write-host "UPNinProxyCounter: "  $UPNinProxyCounter
    }
}
 
 
"@

$PSISE.CurrentFile.Editor.InsertText($FunctionText)

}

function New-Script 
{
    [CmdletBinding()]
    [Alias("ns")]
    
    Param(
    [Parameter(Mandatory = $True, Position = 0)] [string]$Name
    )

$TextBlock=@"

# -----------------------------------------------------------------------------
#
# Script Name: $Name.ps1
# Author: $env:username 
# Date: $((get-date).ToShortDateString())
# Description:
#
# -----------------------------------------------------------------------------

function Execute-Script 
{
   
    BEGIN 
    {
        # Initialize Script
        #--------------------------
        Clear-Host
        Write-Host "`nRunning: BEGIN Block" -ForegroundColor Blue
        Import-CBModules 
        #Start-Transcribing 
    }

    PROCESS 
    {
        Write-Log "`nRunning: PROCESS Block" -ForegroundColor Blue
        # Run Functions
        #--------------------------

        Do-Something
    }

    END 
    {
        # Close Script
        #--------------------------
        Write-Log "`nRunning: END Block"  -ForegroundColor Blue
        #Close-LogFile -Quiet
        #Measure-Script
        #Stop-Transcribing
    }
}

Execute-Script
 
"@

$PSISE.CurrentFile.Editor.InsertText($TextBlock)

}

function New-Hash
{
    $TextBlock=@"
        ### Create Object Array
        $Objects = @()

        # Build-Report
        #------------------------------
        $Hash = [ordered]@{            
            User       = $User.Name
            Department = $User.Department
        }                           
        $PSObject      = New-Object PSObject -Property $Hash
        $Objects       += $PSObject 
        $global:Objects = $Objects # IMPORTANT: Set Vaiable Scope Here (or else +=PSOp adds the $Report)
"@
    $PSISE.CurrentFile.Editor.InsertText($TextBlock)
}
    
function New-Report
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

function Set-PSCredentials
{

    ### Data Protection API (DAPI):
    ### ----------------------------------------------------------------------------------------------------------------------------
    ### This method Uses the Windows Native  DAPI (Data Protection API) to encrypt the password from the ‘secure string’ 
    ### Performing the Convert-FromSecureString cmdlet with no parameters, you are effectively telling PowerShell to do the encryption using DAPI. 
    ### You can however also provide a specific AES Key for it to use to perform the encryption instead. 


    ### Limitations:
    ### ----------------------------------------------------------------------------------------------------------------------------
    ### The script that runs and reads the saved credentials, must be run on the same machine and in the same user context.
    ### You cannot copy the ‘saved credential’ file to other machines and reuse it.
    ### Scripts run as scheduled tasks the service account requires ‘Interactive’ ability. This means the service account, at least temporarily, needs ‘log on locally’ to give you that interactive session.
    ### GPO setting Network Access: Do not allow storage of passwords and credentials for network authentication must be set to Disabled (or not configured).  Otherwise the encryption key will only last for the lifetime of the user session (i.e. upon user logoff or a machine reboot, the key is lost and it cannot decrypt the secure string text)
    
    $UserName = "Administrator"
    $PasswordFile = "\\eciscripts.file.core.windows.net\clientimplementation\_VMAutomationLogs\PSCredentials\VMGuestLocalAdmin.txt"

    ### Run this Command Manually to Create Password File
    ##############################################################
    ### Read-Host "Enter Password To Be Encrypted" -AsSecureString | ConvertFrom-SecureString | Out-File $PasswordFile
    ### You have to create the password string on the same computer and with the same login that you will use to run it.
    ##############################################################

    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $PasswordFile | ConvertTo-SecureString)
    
}

function Encrypt-AESEncryptionKey
{
    ###############################################################
    ###  Create a Secure Password File using AES Encryption
    ###############################################################
    
    ### Prompt you to enter the username and password. The PSCredentials now holds the password in a ‘securestring’ format
    $PSCredentials = Get-Credential 

    # The PSCredentials object now holds the password in a ‘securestring’ format
    $UserName = $PSCredentials.UserName
    $PasswordSecureString = $PSCredentials.Password

    ### Set Location for AESCredentials
    #$AESCredentialsPath = "\\eciscripts.file.core.windows.net\clientimplementation\_VMAutomationLogs\AESCredentials\"
    $AESCredentialsPath = "X:\_VMAutomationLogs\AESCredentials"
    #$AESCredentialsPath = "C:\Temp\"

    $AESCredentialsPath = $AESCredentialsPath + $UserName
    if(-NOT(Test-Path -Path $AESCredentialsPath)) {(New-Item -ItemType directory -Path $AESCredentialsPath -Force | Out-Null);Write-Host "Creating AESCredentialsPath: " $AESCredentialsPath }

    ### Define a location to store the AESKey
    $AESKeyFileName = “AESKey.txt”
    $AESKeyFilePath = $AESCredentialsPath + "\" + $UserName + $AESKeyFileName
    
    ### Define a location to store the file that hosts the encrypted password
    $PasswordFileName = “Password.txt”
    $PasswordFilePath = $AESCredentialsPath + "\" + $UserName + $PasswordFileName

    ### Generate a random AES Encryption Key.
    $AESKey = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)

    ### Store the AESKey in a file. This file should be protected! (e.g. ACL on the file to allow only select people to read)
    Set-Content $AESKeyFilePath $AESKey # Any existing AES Key file will be overwritten
    
    ### Store the Password in a file. This file should be protected! (e.g. ACL on the file to allow only select people to read)
    $Password = $PasswordSecureString | ConvertFrom-SecureString -Key $AESKey
    Add-Content $PasswordFilePath $Password
}

function Decrypt-AESEncryptionKey
{
    #Set Up Path and User Variables
    $UserName = "Administrator"
    #$Domain = ""
    #$UserUPN = "$Domain\$UserName"
    #$AESCredentialsPath = "\\eciscripts.file.core.windows.net\clientimplementation\_VMAutomationLogs\AESCredentials\"
    $AESCredentialsPath = "X:\_VMAutomationLogs\AESCredentials"
    #$AESCredentialsPath = "C:\Temp\"

    ### Get AES Key
    $AESKeyFileName = “AESKey.txt” # location of the AESKey                
    $AESKeyFilePath = $AESCredentialsPath + $UserName + "\" + $UserName + $AESKeyFileName
    $AESKey = Get-Content -Path $AESKeyFilePath 

    ### Get Password File
    $PasswordFileName = “Password.txt” # location of the file that hosts the encrypted password 
    $PasswordFilePath = $AESCredentialsPath + $UserName + "\" + $UserName + $PasswordFileName
    $Password = Get-Content -Path $PasswordFilePath
    $SecurePass = $Password | ConvertTo-SecureString -Key $AESKey
    #$SecurePass = (Get-Content -Path $PasswordFilePath) | ConvertTo-SecureString -Key $AESKey

    ### Create PSCredential Object w/ the Valid UserName & Password
    $PSCredentials = New-Object System.Management.Automation.PSCredential($UserName, $SecurePass)

    ### Test Creds
    #IsAdmin $PSCredentials

}

function Export-AESEncryptionKey-old
{
    ### Generate a random AES Encryption Key.
    $AESKey = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
	
    ### Store the AESKey into a file. This file should be protected!  (e.g. ACL on the file to allow only select people to read)
    $AESKeyFilePath = "\\eciscripts.file.core.windows.net\clientimplementation\_VMAutomationLogs\AESKeys\VMGuestLocalAdmin.txt"
    
    $g = ( Read-Host "Enter Password To Be Encrypted" -AsSecureString | ConvertFrom-SecureString) #| Out-File $PasswordFile

    Set-Content $AESKeyFilePath $AESKey   # Any existing AES Key file will be overwritten		
    $Password = $PasswordSecureString | ConvertFrom-SecureString -Key $AESKey
    Add-Content $CredentialFilePath $Password
}

function Import-AESEncryptionKey-old
{
    $UserName   = "Administrator"
    $AESKey     = Get-Content $AESKeyFilePath
    $PwdTxt     = Get-Content $SecurePwdFilePath
    $SecurePwd  = $PwdTxt | ConvertTo-SecureString -Key $AESKey
    $CredObject = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePwd
}

function Set-PSCredentials-old
{
    #$UserName = "cbrennan@eciadmin.onmicrosoft.com"
    $UserName = "Administrator"

    $ScriptPath  = split-path $MyInvocation.PSCommandPath -Parent
    
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

    $PSCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $PasswordFile | ConvertTo-SecureString)
    #PSCredentials

}

function Get-Colors
{
    [enum]::GetValues([System.ConsoleColor]) | Foreach-Object {Write-Host $_ -ForegroundColor $_} 
    $colors = [enum]::GetValues([System.ConsoleColor])
    Foreach ($bgcolor in $colors)
    {
        Foreach ($fgcolor in $colors) {Write-Host "$fgcolor |"  -ForegroundColor $fgcolor -BackgroundColor $bgcolor -NoNewLine }
        Write-Host " on $bgcolor"
    }
}

function Count-Lines
{
   # $Dir = "Y:\ECI.Modules.Dev\*.*"

   #####################################################################
   ### NOTE: Errors are fromn the Get-Conent command on empty folders!
   #####################################################################

    #

    Get-ChildItem X:\Production\ECI.Modules.Prod -Filter "*.p*" -Recurse -File | Get-Content | Measure-Object -line -word -Character
    #Get-ChildItem X:\Production -Exclude "ECI.Modules.Prod - Checkpoint 11-12-18" -Filter "*.p*" -Recurse -File | Get-Content | Measure-Object -line -word -Character
    #Get-ChildItem X:\development\ECI.Modules.Dev -Filter "*.p*" -Recurse -File | Get-Content | Measure-Object -line -word -Character
    #Get-ChildItem "\\eciscripts.file.core.windows.net\clientimplementation\Production\ECI.Modules.Prod" -Filter "*.p*" -Recurse | Get-Content | Measure-Object -line -word -Character
    #Get-ChildItem "\\eciscripts.file.core.windows.net\clientimplementation\Production\ECI.Modules.Prod" -Filter "*.p*" -Recurse | Get-Content | Measure-Object -line -word -Character
    #Get-ChildItem "C:\Users\cbrennan\OneDrive - Eze Castle Integration, Inc\Documents\ECI.Repository\ECI.Modules.Prod 11-3-18" -Filter "*.p*" -Recurse | Get-Content | Measure-Object -line -word -Character
    
}


### TextBlock
$TextBlock = @"

Textblock Text

"@

Export-ModuleMember -alias * -function * -Cmdlet * -Variable *

function New-ECI.ModuleManifest
{
 New-ModuleManifest -Path  -RootModule -ModuleVersion "1.0.0"
}

#######################################
### Function: Set-TranscriptPath
#######################################
function Set-TranscriptPath
{
    $global:TranscriptPath = "C:\Scripts\Transcripts"

    if(-NOT(Test-Path -Path $TranscriptPath)) {(New-Item -ItemType directory -Path $TranscriptPath | Out-Null);Write-Host "Creating TranscriptPath: " $TranscriptPath }
    Return $TranscriptPath
}


function Generate-RandomAlphaNumeric
{
    Param([Parameter(Mandatory = $False)][int]$Length)

    if(!$Length){[int]$Length = 15}

    ##ASCII
    #48 -> 57 :: 0 -> 9
    #65 -> 90 :: A -> Z
    #97 -> 122 :: a -> z

    for ($i = 1; $i -lt $Length; $i++) {

        $a = Get-Random -Minimum 1 -Maximum 4 

        switch ($a) 
        {
            1 {$b = Get-Random -Minimum 48 -Maximum 58}
            2 {$b = Get-Random -Minimum 65 -Maximum 91}
            3 {$b = Get-Random -Minimum 97 -Maximum 123}
        }

        [string]$c += [char]$b
    }

    Return $c
}

