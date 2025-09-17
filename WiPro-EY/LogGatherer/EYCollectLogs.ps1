<#
Revision History
Version   Date        Developer               Description
1.0       2022.06.02  Gyorgy Nemesmagasi      Initial version
1.1       2022.06.03  Gyorgy Nemesmagasi      Fixed month value in datetime string, fixed creating log file, improved error handling about create 
                                              zip archive. Added Bitlocker status, added more eventlog exports and changed the startup dialog to 
                                              allow to cancel the script execution.
1.2       2022.06.08  Gyorgy Nemesmagasi      Added more logs. Fixed the zipping if the user name longer than 12 char.
1.3       2022.06.08  Gyorgy Nemesmagasi      Improved error logging.
1.4       2022.06.15  Gyorgy Nemesmagasi      Request and run elevated the script if it is running behind ESP without elevation.
1.5       2022.06.16  Gyorgy Nemesmagasi      Request and run elevated the script if it is running without elevation (any time).
1.6       2022.09.16  Gyorgy Nemesmagasi      Added more logs and updated comments. Added Export-Registry, Export-ConsoleApp, Export-App functions. 
                                              Added copy the final zip to a folder where Intune log capture can collect remotely.

This script collects autopilot related log files, windows events, MDM diagnostics information, 
Window's diagnostic information and image information. All the files are compressed into a single zip file 
that can be used for troubleshooting Autopilot related problems. The script work behind the ESP, with or 
without elevated rights (in this case less information collected). 
The output .zip archive can be provided for troubleshooting the Autopilot enrollment.

How you extend the log collection
- Go to the section "Collect diagnostics logs (START)" below.
- Add Update-Progress line with a meaningful text. It displayed on the progress bar when the next action is running.
- Add an export step e.g. Copy-FolderContent, Copy-File, Export-WindowsEvent.
- Continue the previous two steps to accommodate other exports.
- Update the $StepCount variable to match the number of the progress steps displayed in Update-Progress + 1.
- Test the script with and without elevation.
- Add the recent script's source code to the DevOps repository.


Export and file collection function
  Copy-FolderContent       Recursive copy of the source folder content.
  Copy-File                Copy the files match the filter text from the source folder. Add -Recurse to recursive copy.
  Export-WindowsEvent      Exports the Windows event logs in evtx format.
  Export-RegistryKey       Exports the specified registry key and its subkeys into a .reg file.
  Export-ConsoleApp        Runs the specified console application and captures its output.
  Export-App               Runs the specified application and validates it output file exists.

#>

param (
    [string]$ZipName
)

# Common script level variables.
$EYScriptVersion       = '1.6'
$EYFriendlyName        = 'EYCollectLogs'
$EYSeparatorCharCount  = 60
$nl                    = [Environment]::NewLine
$EYScriptLogFolder     = 'c:\Maintenance\Logs'
$EYScriptLogFile = "$EYScriptLogFolder\$($MyInvocation.MyCommand.Name).log"


# Additional global variables.
$ShowStartupDialog = $true
$ZipOutFolder = 'C:\Maintenance'
$IntuneLogCollectionFolder = "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs"
$UtcDate = (Get-date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
$TempFullPath = (Get-Item -Path $env:TEMP).FullName
$ZipNameTemplate = "Autopilot-$($env:COMPUTERNAME)"

if (-not $ZipName) {
    # First run, generate zip name.
    $ZipFileName = "$ZipNameTemplate-$UtcDate"
}
else {
    # Elevation requested, do not show the startup dialog again, just run it.
    # The zip file name already generated, use it.
    $ShowStartupDialog = $false
    $ZipFileName = $zipName
}

$ZipTempFolder = "$TempFullPath\$ZipFileName"
$ZipFilePath = "$ZipOutFolder\$($ZipFileName).zip"

$script:CurrentStep = 0
# Number of the info collection steps displayed in the progress bar. It used to calculate the current position
# when the progress bar update (before all the collection element).
$StepCount = 57

<#
    .SYNOPSIS
        Copies content of a folder to another location.

    .DESCRIPTION
        Copies all files and sub-folders of a folder to another location.

    .PARAMETER Path
        Full path of the source folder.

    .PARAMETER Destinaton
        Full path to the new location.
#>
function Copy-FolderContent
{
    param (
        $Path,
        $Destination
    )
    
    try {
        Write-LogInfo "Copy $Path folder content to $Destination."

        Copy-Item -Path $Path -Destination $Destination -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable FolderCopyError
        
        # Process errors
        if ($FolderCopyError) {
            Write-LogError 'Folder copy completed with failure. Failed to copy the following files.'
            $FolderCopyError | % { Write-LogError $_.ToString() }
        }
        else {
            Write-LogInfo 'Folder copy completed.'
        }
        
    }
    catch {
        Write-LogError "Folder copy failed. $_"
    }
}

<#
    .SYNOPSIS
        Copies files of a folder to another location.

    .DESCRIPTION
        Copies all files of a folder that match the specified filter to another location.

    .PARAMETER Path
        Full path of the source folder.

    .PARAMETER Destination
        Full path to the new location's folder.

    .PARAMETER Filter
        Parameter to filter file copy. The filter compared against the file name (including extension). 
        Used it to filter by extension or use the file name if like to specifiy a single file.
        Wide cards allowed. 

    .PARAMETER Recurse
        Recursive copies the files from the subfolder.
        If it $true it copies file from the subfolders as well.
        If it $false it copies files only from the first level.
#>
function Copy-File
{
    param(
        $Path,
        $Destination,
        $Filter = "*",
        [Switch]$Recurse,
        [Switch]$IncludeZip
    )

    try {
        # If a filter used in Copy-Item cmdlet it ignores the -ErrorAction parameter and stops at the 
        # first error. To copy as much as file we can the files collected by the Get-ChildItem cmdlet
        # (with the same file name filter) and pipe to the Copy-Item to copies it one by one.
        
        # Garter the files first.
        Write-LogInfo "Copy files from $Path folder to $Destination with $Filter filter."
        $sourceFiles = Get-ChildItem "$Path" -Filter $Filter -Recurse:$Recurse -ErrorAction SilentlyContinue -ErrorVariable SearchError -File
        # Then try to copy.
        $sourceFiles | % { 
            if ($IncludeZip.IsPresent -or ($_.Name -notlike "$ZipNameTemplate*")) {
                # Construct the destination file full path by keeping the same folder structure
                # relative to the source root.
                $DestinationFile = $_.FullName.Replace($Path, $Destination) 
                $DestinationFolder = Split-Path -Path $DestinationFile -Parent
                if (-not (Test-Path -Path $DestinationFolder))
                {
                    # Create the destination folder.
                    New-Item -Path $DestinationFolder -Force -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
                }

                try {
                    # Copy the files one by one and catch and log the copy errors.
                    Copy-Item -Path $_.FullName -Destination $DestinationFile -Force -ErrorAction Stop
                }
                catch {
                    Write-LogError $_
                }
            }
        }
        
        # Process errors
        if ($SearchError) {
            Write-LogError 'File copy completed with failure. Failed to copy the following files.'
            Write-LogError $SearchError
        }
        else {
            Write-LogInfo 'File copy completed.'
        }
    }
    catch {
        Write-LogError "File copy failed. $_"
    }
}

<#
    .SYNOPSIS
        Exports a registry key into a .reg file.

    .DESCRIPTION
        Exports the specified registry key and its subkeys into a .reg file by reg.exe.

    .PARAMETER Path
        Registry key path.

    .PARAMETER Destination
        Full path of the exported key file.
#>
function Export-RegistryKey {
    param (
        $Path,
        $Destination
    )   

    # Exporting the key.
    try {
        Write-LogInfo "Exporting key $Path."
        
        $DestinationFolder = Split-Path -Path $Destination -Parent
        if (-not (Test-Path -Path $DestinationFolder))
        {
            # Create the destination folder.
            New-Item -Path $DestinationFolder -Force -ErrorAction SilentlyContinue -ItemType Directory | Out-Null
        }

        # reg.exe exports the registry key.
        $Cmd = 'reg.exe'
        $Param = @('EXPORT', """$Path""", """$Destination""", '/y', '/reg:64')
        $result = Start-Command -Command $Cmd -Argument $Param
        
        # Process errors.
        if (($result.ExitCode -eq 0) -and (Test-Path -Path $Destination)) {
            Write-LogInfo 'The registry key export completed.'
        }
        else {
            Write-LogError 'Unxpected return code found or could not find the exported key file. The export failed.'
        }

    }
    catch {
        Write-LogError "Failed to export the registry key. $_"
    }
}

<#
    .SYNOPSIS
        Exports the specified Windows NT event log into an .evtx file.

    .DESCRIPTION
      Exports the specified Windows NT event log into an .evtx file.
    
    .PARAMETER LogName
        Name of the Windows NT event log.

    .PARAMETER Path
        Full path of the exported event log.
#>
function Export-WindowsEvent {
    param(
        $LogName,
        $Path
    )
    
    try {
        Write-LogInfo "Exporting $LogName Windows eventlog  to $Path."

        New-Item -Path (Split-Path -Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

        # wevtutil exports the specified eventlog.
        $Cmd = 'wevtutil'
        $Param = 'export-log', """$LogName""", """$Path""", '/ow:true'

        $result = Start-Command -Command $Cmd -Argument $Param

        # Process errors.
        if (($result.ExitCode -eq 0) -and (Test-Path -Path $Path)) {
            Write-LogInfo "$LogName Windows eventlog export completed."
        }
        else {
            Write-LogError "Failed to export $LogName Windows eventlog."
        }
    }
    catch {
        Write-LogError "Failed to export Windows eventlog. $_"
    }
}

<#
    .SYNOPSIS
        Runs the specified executable.

    .DESCRIPTION
        Runs the specified executable and captures the text written to stdOut and stdErr channels
        and its return code. The errors needs to be handled outside this function.

    .PARAMETER Command
        Executable command.

    .PARAMETER Argumant
        Array of the command arguments.

    .OUTPUT
        Return code and the captured stdout/stderr output text of the executable.
#>
function Start-Command {
    param(
        $Command,
        $Argument,
        [switch]$NoOutputLog = $false
    )

    Write-LogInfo "Run application: $Command $($Argument -join ' ')"

    # Redirect the stdErr to stdOut to capture it together.
    # Join the lines and write it into the same log entry.
    $StdOut = (& $Command $Argument 2>&1) -join [environment]::NewLine
    
    # Store the exit code variable to make sure it won't change by other
    # cmdlets before this function returns with it.
    $CommandExitCode = $LASTEXITCODE
    Write-LogInfo "Return code: $CommandExitCode"

    if ((-not $NoOutputLog.IsPresent) -and $StdOut) {
        Write-LogInfo "Output:"
        Write-LogInfo $StdOut
    }

    @{
        ExitCode = $CommandExitCode
        Output = $StdOut
    }
}

<#
    .SYNOPSIS
        Runs the specified console application and captures its output.

    .DESCRIPTION
        Runs the specified executable and captures and saves the text written to stdOut and stdErr channels.

    .PARAMETER FriendlyName
        The name of the application. It used to easy to identify the application in log.

    .PARAMETER Command
        Executable command.

    .PARAMETER Argument
        Array of the command arguments.

    .PARAMETER Path
        The full path of the output file where the captured output text saved.

    .PARAMETER SuccessCode
        Array of all the success retrun codes.The default success exit code is 0, only need to use this parameter if 
        a success operation produce any other exit code as well.
        
    .PARAMETER NoOutputLog
        Do not write the captured output text into the log. If the export field the output text will be written
        into the log anyway.

    .PARAMETER DoNotCheckExitCode
        Skip the check of the exit code.
#>
function Export-ConsoleApp {
    param(
        $FriendlyName = 'application',
        $Command,
        $Argument,
        $Path,
        $SuccessCode = @(0),
        [switch]$NoOutputLog,
        [switch]$DoNotCheckExitCode
    )
    try {
        
        Write-LogInfo "Run $FriendlyName and export its output."

        
        # Run the application.
        $result = Start-Command -Command $Command -Argument $Argument -NoOutputLog:($NoOutputLog.IsPresent)
        
        # Process errors
        $ReturnCodeSuccess = $DoNotCheckExitCode.IsPresent -or ($result.ExitCode -in $SuccessCode)
        $OutputExist = $result.Output -ne ''

        if ($OutputExist) {
            #Create output folder.
            New-Item -Path (Split-Path -Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        
            #Record the output.
            $result.Output | Out-File -FilePath $Path -Encoding ascii
        }
        
        if ($ReturnCodeSuccess -and $OutputExist) {
            Write-LogInfo 'Export completed.'
        }
        else {
            Write-LogError "Failed to export $FriendlyName."
            if ($NoOutputLog.IsPresent -and $OutputExist) {
                Write-LogInfo "Output:"
                Write-LogInfo $result.Output
            }
            if (-not $ReturnCodeSuccess) {
                Write-LogError "The return code $($result.ExitCode) is unexpected."
            }
            if (-not $OutputExist) {
                Write-LogError "$FriendlyName has no output, nothing to export."
            }
        }

    }
    catch {
        Write-LogError "Failed to export the $FriendlyName. $_"
    }
}

<#
    .SYNOPSIS
        Runs the specified application and validates it output file exists.

    .DESCRIPTION
	    Runs the specified executable and validates the output file created by the application exists.
        It also captures and write into the log the stdout and stderr of the application - if it produced.

    .PARAMETER FriendlyName
        The name of the application. It used to easy to identify the application in log.

    .PARAMETER Command
        Executable command.

    .PARAMETER Argument
        Array of the command arguments.

    .PARAMETER Path
        The full path of the file where the output saved.

    .PARAMETER SuccessCode
        Array of all the success return codes.The default success exit code is 0, only need to use this parameter if 
        a success operation produce any other exit code as well.
        
    .PARAMETER NoOutputLog
        Do not write the captured output text into the log. If the export faild the output text will be written
        into the log anyway.

    .PARAMETER DoNotCheckExitCode
        Skip the check of the exit code.
#>
function Export-App {
    param(
        $FriendlyName = 'application',
        $Command,
        $Argument,
        $Path,
        $SuccessCode = @(0),
        [switch]$NoOutputLog,
        [switch]$DoNotCheckExitCode
    )
    try {
        Write-LogInfo "Run $FriendlyName export."

        for ($index = 0; $index -lt $Argument.length; $index++) {
            $Argument[$index] = $Argument[$index].replace('{Path}', $Path)
        }

        #Create output folder.
        New-Item -Path (Split-Path -Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

        # Run the application
        $result = Start-Command -Command $Command -Argument $Argument -NoOutputLog:$NoOutputLog.IsPresent
        

        # Process errors.
        $ReturnCodeSuccess = $DoNotCheckExitCode.IsPresent -or ($result.ExitCode -in $SuccessCode)
        $OutputExist = Test-Path -Path $Path

        if ($ReturnCodeSuccess -and $OutputExist) {
            Write-LogInfo 'Export completed.'
        }
        else {
            Write-LogError "Failed to export $FriendlyName."
            if ($NoOutputLog.IsPresent -and $result.Output) {
                Write-LogInfo "Output:"
                Write-LogInfo $result.Output
            }
            if (-not $ReturnCodeSuccess) {
                Write-LogError "The return code $($result.ExitCode) is unexpected."
            }
            if (-not $OutputExist) {
                Write-LogError "Cannot find the output file $Path."
            }
        }
    }
    catch {
        Write-LogError "$FriendlyName export failed. $_"
    }
}

<#
    .SYNOPSIS
        Exports all the WiFi profiles into a compressed archive (zip) file. The key information are removed
        from the profile xml files.

    .DESCRIPTION
        Exports the WiFi profiles into a compressed archive (zip) file.  The function use the netsh command to 
        export all the WiFi profiles,         removes the key information from the exported file and compress 
        they into a zip file.
	      
    .PARAMETER TempFolder
        The name of the application. It used to easy to identify the application in log.

    .PARAMETER Path
        The full path of the compressed WiFi profiles.
#>
function Export-WiFiProfile {
    param(
        $TempFolder,
        $Path
    )

    try {
        Write-LogInfo 'Export WiFi profiles.'

        if (Test-Path -Path $TempFolder) {
            try {
                # WLAN temp folder already exists. Delete its content.
                Get-ChildItem -Path $TempFolder | Remove-Item -Recurse -ErrorAction SilentlyContinue
            }
            catch {
                # Cannot clean up WLAN temp folder. Continue anyway.
                Write-LogError "Cannot clean up WLAN temp folder $TempFolder. Continue anyway. $_"
            }
        }
        else {
            # Create WLAN temp folder to export profiles by netsh.
            New-Item -Path $TempFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Export profiles.
        $result = Start-Command -Command 'netsh' -Argument @('wlan', 'export', 'profile', "folder=""$TempFolder""")
    
        Write-LogInfo 'Secure WiFi profiles.'
        Get-ChildItem $TempFolder | % { $name = $_.FullName; Get-Content $name | Where { (($_ -notlike "*keyMaterial*") -and ($_ -notlike "*randomizationSeed*")) } | Set-Content $name.Replace(".xml", ".txt")}

        Write-LogInfo 'Create archive from profiles.'
        New-Item -Path (Split-Path -parent $Path) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        Get-ChildItem -Path $TempFolder -Filter '*.txt' | Compress-Archive -DestinationPath $Path
    
        Write-LogInfo 'Remove temp data.'
        Get-ChildItem -Path $TempFolder | Remove-Item -Recurse -ErrorAction SilentlyContinue
        Get-Item -Path $TempFolder | Remove-Item -Recurse -ErrorAction SilentlyContinue

        Write-LogInfo 'WiFi profiles export completed.'
    }
    catch {
        Write-LogError "Failed to export Wifi profiles. $_"
    }
}

<#
    .SYNOPSIS
        Writes the computer information produced by the 'Get-ComputerInfo' cmdlet
        into a file.

    .DESCRIPTION
        Writes the computer information produced by the 'Get-ComputerInfo' cmdlet
        into a file.

    .PARAMETER Path
        Full path of the output file.
#>
function Export-ComputerInfo {
    param(
        $Path
    )

    try {
        Write-LogInfo "Exporting computer information to $Path"
        New-Item -Path (Split-Path $Path -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        Get-ComputerInfo | Out-File $Path
        if (Test-Path -Path $Path) {
            Write-LogInfo 'Computer info export completed.'
        }
        else {
            Write-LogError 'Failed to export computer information.'
        }
        
    }
    catch {
         Write-LogError "Failed to export computer information. $_"
    }
}

<#
    .SYNOPSIS
        Compresses a folder into a zip file.

    .DESCRIPTION
        Compresses the specified folder into .zip file.
        The 'Compress-Archive' cmdlet cannot handle if any source files errors, 
        cannot continue and delete the archive file. A custom function introduced.

    .PARAMETER Path
        Full path of the source folder to be compressed.

    .PARAMETER Destination
        Full path of the compressed file.
#>
function Compress-Folder {
    param(
        $Path,
        $Destination
    )
    
    try {
        # Progress bar variables.
        $ProgressActivity = "Archiving folder $Path"
        $ProgressId = 101

        Write-LogInfo "Archiving autopilot diagnostics logs from $Path to $Destination."
        New-Item -Path (Split-Path $Destination -Parent) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        
        # Enumerate all the files first.
        $SourceFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue -ErrorVariable ZipSearchError

        # Process errors.
        if ($ZipSearchError) {
            Write-LogError 'Failed to archive the following files.'
            $ZipSearchError | % { Write-LogError $_.ToString() }
        }

        try {
            $FileIndex = 0

            # Create archive and Walk through the enumerated files and add one by one to the archive.
            Add-Type -assembly 'System.IO.Compression'
            Add-Type -assembly 'System.IO.Compression.FileSystem'
            [System.IO.Compression.ZipArchive]$ZipFile = [System.IO.Compression.ZipFile]::Open($Destination, [System.IO.Compression.ZipArchiveMode]::Update)
            
            $SourceFiles | % {
                $DestinationFile = $_.FullName.Replace("$Path", "").TrimStart("\")
                try {
                    Write-Progress -Activity $ProgressActivity -PercentComplete ([int]$FileIndex / $SourceFiles.Count * 100) -Id $ProgressId
                    $FileIndex++
                    $CompressedFile = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($ZipFile, $_.FullName, $DestinationFile, [System.IO.Compression.CompressionLevel]::Optimal )
                    Write-LogInfo "File archived: $($_.FullName) <$($CompressedFile.Name)>"
                }
                catch {
                    Write-LogError "Failed to archive a file. $_"
                }
            }
        }
        catch {
            Write-LogError "Failed archive the autopilot diagnostics logs. $_"
        }
        finally {
            Write-LogInfo "Closing zip archive."

            If($null -ne $ZipFile)
            {
                $ZipFile.Dispose()
            }
        }
        
        Write-Progress -Activity $ProgressActivity -Id $ProgressId -Completed

        if (Test-Path -Path $Destination) {
            Write-LogInfo 'Archiving completed.'
        }
        else {
            Write-LogError 'Failed archive the autopilot diagnostics logs.'
        }
    }
    catch {
        Write-LogError "Failed archive the autopilot diagnostics logs. $_"
    }
}

<#
    .SYNOPSIS
        Deletes the folder and its content.

    .DESCRIPTION
        Deletes the folder and its content. Captures and logs the errors.

    .PARAMETER Path
        Full path of the folder needs to be deleted.
#>
function Delete-Folder {
    param(
        $Path
    )

    try {
        Write-LogInfo "Deleting temporary collection folder $Path"
        Remove-Item -Path $Path -Force -Recurse -Erroraction SilentlyContinue -ErrorVariable DeleteError
        if ($DeleteError) {
            Write-LogError 'Failed to remove the following files.'
            $DeleteError | % {Write-LogError $_.ToString()}
        }

        if (Test-Path -Path $Path) {
            Write-LogError 'Failed to delete the temporary collection folder.'
        }
        else {
            Write-LogInfo 'Temporary collection folder deleted.'
        }
    }
    catch {
        Write-LogError "Failed to delete the temporary collection folder. $_"
    }
}

<#
    .SYNOPSIS
        Shows progress bar and writes the progress text into log file and to the console.

    .DESCRIPTION
        Shows progress bar and writes the progress text into log file and to the console.
        It computes and shows the completed percentage as well.

    .PARAMETER Activity
        Status text.
#>
function Update-Progress {
    param(
        $Activity = "Collecting logs"
    )

    [int]$Progress = $CurrentStep / $StepCount * 100
    Write-Progress -Id 100 -Activity "Collecting Autopilot diagnostics logs" -Status "$Progress%  $Activity" -PercentComplete $Progress
    $script:CurrentStep++
    Write-LogInfo "===> $Activity"
    Write-Host $Activity
}

<#
    .SYNOPSIS
        Writes the log message into the log file.

    .DESCRIPTION
        Constructs the log line structure (datetime | user | severity | message) and append it to the log file.

    .PARAMETER Message
        Log message.

    .PARAMETER Severity
        Message severity (Info, Error, Waning)
#>
function Write-LogLine {
    param (
        $Message,
        $Severity
    )

    try {
        New-Item -Path $EYScriptLogFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        $DateTime = (Get-date).ToString("yyyy-MM-dd HH:mm:ss")
        $Line = "$DateTime | $($env:USERNAME) | $Severity | $Message"
        $Line | Out-File -FilePath $EYScriptLogFile -Append -Encoding unicode
    }
    catch {
        #Failed to write the log file, dump the message to the console.
        Write-Host $Message
    }
}

<#
    .SYNOPSIS
        Writes an info message into the log file.

    .DESCRIPTION
        Writes an info message into the log file.

    .PARAMETER Message
        Info message to write into the log file.
#>
function Write-LogInfo {
    param(
        $Message
    )

    Write-LogLine $Message 'Info'
}

<#
    .SYNOPSIS
        Writes an error message into the log file.

    .DESCRIPTION
        Writes an error message into the log file.

    .PARAMETER Message
        Error message to write into the log file.
#>
function Write-LogError {
    param(
        $Message
    )

    Write-LogLine $Message 'Error'
}

<#
    .SYNOPSIS
        Writes script startup header to the log.

    .DESCRIPTION
        Writes script startup header to the log.
#>
function Write-LogStart {
    Write-LogInfo ('*' * $EYSeparatorCharCount)
    Write-LogInfo "Starting Script"
    Write-LogInfo "Friendly Script Name: $EYFriendlyName"
    Write-LogInfo "Script Name: $($MyInvocation.ScriptName)"
    Write-LogInfo "Version: $EYScriptVersion"
    Write-LogInfo "Is x64 process: $([System.Environment]::Is64BitProcess)"
    Write-LogInfo "Is elevated: $(Test-Elevated)"
    Write-LogInfo "User name: $env:USERNAME"
    Write-LogInfo "Computer name: $env:COMPUTERNAME"
    $ProductName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName -ErrorAction SilentlyContinue).ProductName
    Write-LogInfo "OS Name: $ProductName"
    Write-LogInfo "OS Version: $([System.Environment]::OSVersion.Version)"
    Write-LogInfo "ZipName parameter: $ZipName"
    Write-LogInfo ('*' * $EYSeparatorCharCount)
}

<#
    .SYNOPSIS
        Displays the welcome message box.

    .DESCRIPTION
        Displays the welcome message box. The user can select to continue the script or
        stop the script.
#>
function Show-StartMessageBox {
    Write-LogInfo 'Show welcome dialog.'
    Add-Type -AssemblyName Microsoft.VisualBasic
    
    $ConfirmationText = "We will collect the log files and save them to a ZIP in the $ZipFilePath path. $($nl)Please wait for a message saying that this has been completed."
    Write-LogInfo "Show start message box."
    Write-LogInfo $ConfirmationText
    $MsgBoxResult = [Microsoft.VisualBasic.Interaction]::MsgBox($ConfirmationText,'SystemModal, Information, OkCancel','Collect Autopilot diagnostics logs')
    if ($MsgBoxResult -eq 'Cancel') {
        Write-LogInfo 'Cancel button clicked.'
        return $false
    }
    Write-LogInfo 'Ok button clicked.'
    $true
}

<#
    .SYNOPSIS
        Displays the completed message box.

    .DESCRIPTION
        Displays the completed message box.
#>
function Show-CompletedMessageBox {
    Write-LogInfo $CompletedMessage
    Add-Type -AssemblyName Microsoft.VisualBasic

    $CompletedMessage = "The autopilot logs have been saved to a ZIP file in $ZipFilePath"
    Write-LogInfo 'Show completed message box.'
    Write-LogInfo $CompletedMessage
    Write-Host $CompletedMessage
    [Microsoft.VisualBasic.Interaction]::MsgBox($CompletedMessage, 'SystemModal, Information, OkOnly', 'Collect Autopilot diagnostics logs') | Out-Null
}

<#
    .SYNOPSIS
        Test the zip file exists and logs its size.

    .DESCRIPTION
        Test the zip file exists and logs its size.

    .PARAMETER Path
        The path of the zip file.

    .OUTPUT
        True if the file exists.
#>
function Test-ZipFile {
    param (
        $Path
    )

    Write-LogInfo "Validating output .zip file $Path."
    $Result = Test-Path -Path $Path -PathType Leaf

    if ($Result) {
        Write-LogInfo "The file exists."
        try {
            $FileSize = (Get-Item -Path $Path).length
            Write-LogInfo "The file size is $FileSize bytes."
        }
        catch {
            # failed to get the file size, do nothing
        }
    }
    else {
        Write-LogInfo "The file does not exists."
    }

    $Result
}


<#
    .SYNOPSIS
        Check the script running with elevated rights.

    .DESCRIPTION
        Checks the script is running with elevated rights.

    .OUTPUT
        True if the script is running with elevated rights.
#>
function Test-Elevated {

    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}

<#
    .SYNOPSIS
        Displays the elevation request message box.

    .DESCRIPTION
        Displays the message box. The user can select to request elevation for the script or
        continue without elevation.
#>
function Show-ElevationMessageBox {
    
    Add-Type -AssemblyName Microsoft.VisualBasic
    
    $ConfirmationText = @"
It’s recommended to run this script with elevated user rights to collect as much information as possible.

If you select Yes, please allow elevation on the prompt that will come up next to allow all logs to be collected.

If you select No, some of the logs may not be collected.
"@
    Write-LogInfo 'Show request elevation dialog.'
    Write-LogInfo $ConfirmationText
    $MsgBoxResult = [Microsoft.VisualBasic.Interaction]::MsgBox($ConfirmationText,'SystemModal, Question, YesNo','Collect Autopilot diagnostics logs')
    if ($MsgBoxResult -eq 'Yes') {
        Write-LogInfo 'Yes button clicked.'
        return $true
    }
    Write-LogInfo 'No button clicked.'
    $false
}

<#
    .SYNOPSIS
        Starts a script with elevated rights.

    .DESCRIPTION
        Starts the same script with elevated rights and adds the -ZipName parameter.

    .PARAMETER Path
        Full path of the script File.
#>
function Start-Elevated {
    param (
        $Path
    )

    try {
        Write-LogInfo 'Re-start the script with elevated rights.'
        $PoshArg = @('-ExecutionPolicy', 'ByPass', '-File',('"{0}"' -f $Path), '-ZipName', ('"{0}"' -f $ZipFileName))
        Write-LogInfo ([String]::Join(' ', $PoshArg))
        Start-Process -FilePath 'powershell.exe'  -ArgumentList $PoshArg  -Verb RunAs
        Write-LogInfo 'Script had been restart.'
    }
    catch {
        Write-LogError "Failed to re-start the script with elevation. $_"
    }
}

<#
    .SYNOPSIS
        Copies the recently created log collection archive into a folder collected by Intune remote log collection.

    .DESCRIPTION
        Copies the log collection archive into a folder collected by Intune remote log collection.
        Deletes the existing archives to leave only the recent one in the folder.

    .PARAMETER Path
        Full path of Log collection archive File.

    .PARAMETER Destination
        Destination folder that collected by intune remotely log collection.
#>
function Update-IntuneLogCollection {
    param (
        $Path,
        $Destination
    )
    try {
        Write-LogInfo 'Make the generated log collection active can be collected by intune.'
        # Remove the existing log collections from Intune location.
        Try {
            Write-LogInfo "Remove the existing log collection achieves from $Destination."
            Get-ChildItem -Path $Destination -File -Filter "$ZipNameTemplate*.zip" | Remove-Item -ErrorAction SilentlyContinue -Recurse
        }
        catch {
            Write-LogError "Cannot remove existing log collection archive. Continue anyway. $_"
        }

        Write-LogInfo "Copy the recent log collection archive into $Destination ."
        # Copy new log collection into the Intune folder.
        $SourceFolder = Split-Path -Path $Path -Parent
        $SourceFileName = Split-Path -Path $Path -Leaf
        Copy-File -Path $SourceFolder -Destination $Destination -Filter $SourceFileName -IncludeZip
    }
    catch {
        Write-LogError "Failed to copy the diagnostic log collection archive into Intune log collection folder. $_"
    }
}

#################################################################################
# Main
#################################################################################
Write-LogStart

if ($ShowStartupDialog) {
    # Show welcome dialog box.
    if (-not (Show-StartMessageBox)) {
        Write-LogInfo 'Script finished.'
        return
    }
}

# Check whether already elevated and runs behind the ESP.
If (-not (Test-Elevated))
{
    Write-LogInfo 'The script is running behind the ESP without elevation.'
    if (Show-ElevationMessageBox) {
        Start-Elevated $MyInvocation.MyCommand.Path
        Write-LogInfo 'Script finished.'
        return
    }
}

# Start collecting diagnostic information.
Write-LogInfo ('*' * $EYSeparatorCharCount)
Write-LogInfo 'Start to collect the autopilot diagnostics information.'

#Collect diagnostics logs (START).
##################################################

# Files and folders.

Update-Progress -Activity 'Collecting maintenance logs'
Copy-FolderContent -Path 'C:\Maintenance\Logs' -Destination "$ZipTempFolder\Maintenance"

Update-Progress -Activity 'Collecting Intune logs'
Copy-File -Path "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs" -Destination "$ZipTempFolder\IntuneManagementExtension" -Recurse

Update-Progress -Activity 'Collecting Configuration Manager logs'
Copy-FolderContent -Path "$($env:windir)\CCM\Logs" -Destination "$ZipTempFolder\CCM"

Update-Progress -Activity 'Collecting Configuration install logs'
Copy-FolderContent -Path "$($env:windir)\ccmsetup\Logs" -Destination "$ZipTempFolder\CCMSetup"

Update-Progress -Activity 'Collecting O365 system logs'
Copy-File -Path "$($env:windir)\Temp" -Destination "$ZipTempFolder\O365.System" -Filter "$env:COMPUTERNAME*.log"
    
Update-Progress -Activity 'Collecting O365 user logs'
Copy-File -Path $env:TEMP -Destination "$ZipTempFolder\O365.User" -Filter "$env:COMPUTERNAME*.log" 

Update-Progress -Activity 'Collecting PC Setup Assistant status data'
Copy-FolderContent -Path "$($env:PUBLIC)\Documents\DoNotDelete" -Destination "$ZipTempFolder\PCSAStatus"

Update-Progress -Activity 'Collecting 1E client log'
Copy-File -Path "$($env:ProgramData)\1E\Client" -Destination "$ZipTempFolder\1E" -Filter '1E.Client.log'

Update-Progress -Activity 'Collecting 1E client config'
# %ProgramW6432% is an environment variable of C:\Program Files for both 32 and 64 bit.
Copy-File -Path "$($env:ProgramW6432)\1E\Client" -Destination "$ZipTempFolder\1E" -Filter '1E.Client.conf'

Update-Progress -Activity 'Collecting push button reset logs'
Copy-FolderContent -Path "$($env:windir)\logs\PBR" -Destination "$ZipTempFolder\PBR"

Update-Progress -Activity 'Collecting Windows install logs'
Copy-FolderContent -Path "$($env:windir)\Panther" -Destination "$ZipTempFolder\Panther"

Update-Progress -Activity 'Collecting Windows reset logs'
Copy-FolderContent -Path "$($env:SystemDrive)\`$sysreset\logs" -Destination "$ZipTempFolder\Sysreset"

Update-Progress -Activity 'Collecting service state file'
Copy-File -Path "$($env:windir)\ServiceState\wmansvc" -Destination "$ZipTempFolder\ServiceState" -Filter '*.json'

Update-Progress -Activity 'Collecting diagnostic CSP logs'
Copy-File -Path "$($env:ProgramData)\Microsoft\DiagnosticLogCSP\Collectors" -Destination "$ZipTempFolder\DiagnosticLogCSP" -Filter '*.etl'

# Registry exports.

Update-Progress -Activity 'Exporting session manager key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager' -Destination "$ZipTempFolder\RegistryExports\Session Manager.reg.txt"

Update-Progress -Activity 'Exporting Local Machine Run key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Destination "$ZipTempFolder\RegistryExports\Run Local Machine.reg.txt"

Update-Progress -Activity 'Exporting Local Machine RunOnce key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Destination "$ZipTempFolder\RegistryExports\RunOnce Local Machine.reg.txt"

Update-Progress -Activity 'Exporting Current User Run key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Destination "$ZipTempFolder\RegistryExports\Run Current User.reg.txt"

Update-Progress -Activity 'Exporting Current User RunOnce key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Destination "$ZipTempFolder\RegistryExports\RunOnce Current User.reg.txt"

Update-Progress -Activity 'Exporting Local Machine Active Setup 64 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup' -Destination "$ZipTempFolder\RegistryExports\Active Setup Local Machine 64Bit.reg.txt"

Update-Progress -Activity 'Exporting Local Machine Active Setup 32 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Active Setup' -Destination "$ZipTempFolder\RegistryExports\Active Setup Local Machine 32Bit.reg.txt"

Update-Progress -Activity 'Exporting Current User Active Setup 64 bit key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Active Setup' -Destination "$ZipTempFolder\RegistryExports\Active Setup Current User 64Bit.reg.txt"

Update-Progress -Activity 'Exporting Current User Active Setup 32 bit key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Wow6432Node\Microsoft\Active Setup' -Destination "$ZipTempFolder\RegistryExports\Active Setup Current User 32Bit.reg.txt"

Update-Progress -Activity 'Exporting Intune Management Extension key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension' -Destination "$ZipTempFolder\RegistryExports\IntuneManagementExtension.reg.txt"

Update-Progress -Activity 'Exporting Autopilot key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Autopilot' -Destination "$ZipTempFolder\RegistryExports\Autopilot.reg.txt"

Update-Progress -Activity 'Exporting OEM key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM' -Destination "$ZipTempFolder\RegistryExports\OEM.reg.txt"

Update-Progress -Activity 'Exporting Default User international key'
Export-RegistryKey -Path 'HKEY_USERS\.DEFAULT\Control Panel\International' -Destination "$ZipTempFolder\RegistryExports\International Default User.reg.txt"

Update-Progress -Activity 'Exporting Current User international key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\Control Panel\International' -Destination "$ZipTempFolder\RegistryExports\International Current User.reg.txt"

Update-Progress -Activity 'Exporting device manageability CSP key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\DeviceManageabilityCSP' -Destination "$ZipTempFolder\RegistryExports\DeviceManageabilityCSP.reg.txt"

Update-Progress -Activity 'Exporting EY 32 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Ernst & Young' -Destination "$ZipTempFolder\RegistryExports\EYKey 32Bit.reg.txt"

Update-Progress -Activity 'Exporting EY 64 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Ernst & Young' -Destination "$ZipTempFolder\RegistryExports\EYKey 64Bit.reg.txt"

Update-Progress -Activity 'Exporting Local Machine policies key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies' -Destination "$ZipTempFolder\RegistryExports\Policies Local Machine.reg.txt"

Update-Progress -Activity 'Exporting Current User policies key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Policies' -Destination "$ZipTempFolder\RegistryExports\Policies Current User.reg.txt"

Update-Progress -Activity 'Exporting Local Machine uninstall 64 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -Destination "$ZipTempFolder\RegistryExports\Uninstall Local Machine 64Bit.reg.txt"

Update-Progress -Activity 'Exporting Local Machine uninstall 32 bit key'
Export-RegistryKey -Path 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -Destination "$ZipTempFolder\RegistryExports\Uninstall Local Machine 32Bit.reg.txt"

Update-Progress -Activity 'Exporting Current User uninstall 64 bit key'
Export-RegistryKey -Path 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -Destination "$ZipTempFolder\RegistryExports\Uninstall Current User 64Bit.reg.txt"

# Windows event log exports.

Update-Progress -Activity 'Exporting System eventlog'
Export-WindowsEvent -LogName System -Path "$ZipTempFolder\System.evtx"

Update-Progress -Activity 'Exporting Setup eventlog'
Export-WindowsEvent -LogName Setup -Path "$ZipTempFolder\Setup.evtx"

Update-Progress -Activity 'Exporting Application eventlog'
Export-WindowsEvent -LogName Application -Path "$ZipTempFolder\Application.evtx"

Update-Progress -Activity 'Exporting AAD Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AAD/Operational' -Path "$ZipTempFolder\Aad-Operational.evtx"

Update-Progress -Activity 'Exporting Bitlocker API Management eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-BitLocker/BitLocker Management' -Path "$ZipTempFolder\BitlockerApi-Management.evtx"

Update-Progress -Activity 'Exporting Device Management Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin' -Path "$ZipTempFolder\DeviceManagement-Admin.evtx"

Update-Progress -Activity 'Exporting Device Management Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational' -Path "$ZipTempFolder\DeviceManagement-Operational.evtx"

# MDM Diagnostics tool export.

Update-Progress -Activity 'Exporting MDM diagnostics'
Export-App -FriendlyName 'MDM diagnostics' -Command 'mdmdiagnosticstool.exe' -Argument  @('-area', 'Autopilot', '-cab', """{Path}""") -Path  "$ZipTempFolder\autopilot.cab"

# Miscellaneous tool exports

Update-Progress -Activity 'Exporting Bitlocker encryption status'
Export-ConsoleApp -FriendlyName "Bitlocker encryption status" -Command 'manage-bde.exe' -Argument @('-status', 'c:')  -Path "$ZipTempFolder\BitlockerStatus.txt" -NoOutputLog

Update-Progress -Activity 'Exporting Computer info'
Export-ComputerInfo "$ZipTempFolder\ComputerInfo.txt"

Update-Progress -Activity 'Exporting Azure AD registration status'
Export-ConsoleApp -FriendlyName "Azure AD registration status" -Command 'Dsregcmd.exe' -Argument @('/status')  -Path "$ZipTempFolder\DsregcmdStatus.txt" -NoOutputLog -DoNotCheckExitCode

Update-Progress -Activity 'Exporting Certificate store'
Export-ConsoleApp -FriendlyName "Certificate store" -Command 'certutil' -Argument @('-store')  -Path "$ZipTempFolder\Certificates\CertsStore.txt" -NoOutputLog

Update-Progress -Activity 'Exporting Certificate my store'
Export-ConsoleApp -FriendlyName "Certificate my store" -Command 'certutil' -Argument @('-store', 'my')  -Path "$ZipTempFolder\Certificates\CertsMy.txt" -NoOutputLog

Update-Progress -Activity 'Exporting Certificate user my store'
Export-ConsoleApp -FriendlyName "Certificate user my store" -Command 'certutil' -Argument @('-store', '-silent', '-user', 'my')  -Path "$ZipTempFolder\Certificates\CertsUserMy.txt" -NoOutputLog

Update-Progress -Activity 'Exporting Boot configuration'
Export-ConsoleApp -FriendlyName "Boot configuration" -Command 'bcdedit' -Argument @('/enum')  -Path "$ZipTempFolder\BcdeditEnum.txt" -NoOutputLog

Update-Progress -Activity 'Exporting IP network configuration'
Export-ConsoleApp -FriendlyName "IP network configuration" -Command 'ipconfig' -Argument @('/all')  -Path "$ZipTempFolder\Ipconfig.txt" -NoOutputLog

Update-Progress -Activity 'Exporting WLAN information'
Export-WiFiProfile -TempFolder "$($env:TEMP)\WLanProfiles" -Path "$ZipTempFolder\WLanProfiles.zip"

Write-LogInfo 'Diagnostics information had been collected.'
Write-LogInfo ('*' * $EYSeparatorCharCount)

##################################################
#Collect diagnostics logs (END).

Update-Progress -Activity 'Creating zip archive'
Compress-Folder -Path $ZipTempFolder -Destination $ZipFilePath

Update-Progress -Activity 'Cleanup temp folder'
Delete-Folder -Path $ZipTempFolder

Update-Progress -Activity 'Update Intune log collection'
Update-IntuneLogCollection $ZipFilePath $IntuneLogCollectionFolder

Update-Progress "Completed"

# Show completed message box.
Show-CompletedMessageBox

# Open the zip output folder.
$ExplorerFolder = (Split-Path -Path $ZipFilePath -Parent)
Write-LogInfo "Open the zip archive's folder $ExplorerFolder in File Explorer."
explorer $ExplorerFolder

# All done, exit the script.
Write-LogInfo "Script finished."
