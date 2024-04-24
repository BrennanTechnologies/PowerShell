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
1.7       2023.03.27  Gyorgy Nemesmagasi      Added automation of the SEE service startup when device is in ESP to avoid manual intervention.
                                              Added collection on additional logs to get in sync with the PC Setup Assistant v3.5.
                                              Disabled copy the output .zip to the IntuneManagementExtension\Logs folder.

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
  Export-WiFiProfile       Exports the sanitized Wifi profile Information.
  Export-LocalGroup        Exports the local group membership Information.
#>

param (
    [string]$ZipName
)

# Common script level variables.
$EYScriptVersion       = '1.7'
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
$StepCount = 77

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

        # Use reg.exe for export for compatibility with the PC Setup Assistant.
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

    # Supported EY WiFi networks. Its name and SSID remain visible in the profile.
    $supportedWiFi = @('EY Office Wi-Fi - Secondary',
                       'EY Office Wi-Fi - Secondary (A)',
                       'EY Office Wi-Fi - Secondary (C)',
                       'EY Office Wi-Fi - Preferred',
                       'EY Office Wi-Fi - Preferred (A)',
                       'EY Office Wi-Fi - Preferred (C)',
                       'EYguest',
                       'EYStaff')

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
        $result = Start-Command -Command 'netsh' -Argument @('wlan', 'export', 'profile', "folder=""$TempFolder""") -NoOutputLog
    
        Write-LogInfo 'Secure WiFi profiles.'

        $counter = 0
        Get-ChildItem $TempFolder -Filter '*.xml' | ForEach-Object { 
            $name = $_.FullName;

            $text = Get-Content $name
            $wifiName = $_.BaseName.TrimStart('WiFi-')
            
            # Check is it an EY WiFi.
            $isKnowWifi = ($wifiName -in $supportedWiFi)

            # Sanitize profile info.
            $text = $text | ForEach-Object {
                $line = $_
                if (-not  $isKnowWifi) {
                    $line = $line  -replace '(<Hex>)(.+)(</Hex>)', ('$1*****$3')
                    $line = $line.Replace($wifiName, '*****')
                    $line = $line -replace '(<Name>)(.+)(</Name>)', ('$1*****$3')
                }
                $line = $line  -replace '(<keyMaterial>)(.+)(</keyMaterial>)', ('$1*****$3')
                $line = $line  -replace '(<randomizationSeed>)(.+)(</randomizationSeed>)', ('$1*****$3')
                $line = $line -replace '(<ServerNames>)(.*?)(</ServerNames>)', ('$1*****$3')
                $line = $line -replace '(<TrustedRootCAHash>)(.*?)(</TrustedRootCAHash>)', '$1***$3'
                $line = $line -replace '(<TrustedRootCA>)(.*?)(</TrustedRootCA>)', '$1***$3'
                
                $line
            }

            # Sanitize file name.
            if (-not  $isKnowWifi) {
                $sanitizedName = "WiFi-Profile$counter"
                $name = $name.Replace($_.BaseName, $sanitizedName)
                $counter++
            }
            
            # Save the sanitized profile.
            $text | Set-Content $name.Replace(".xml", ".txt")
        }

        # Zip the profiles' info.
        Write-LogInfo 'Create archive from profiles.'
        New-Item -Path (Split-Path -parent $Path) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        Get-ChildItem -Path $TempFolder -Filter '*.txt' | Compress-Archive -DestinationPath $Path
        # Hide progress bar of the Compress-Archive. It is a fix of an issue where the progress bar remain visible 
        # even if the cmdlet completed.
        Write-Progress -Activity 'Compress-Archive' -Completed
        
        # Cleanup-
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
        $Activity = "Collecting logs",
        [switch]$Complete
    )

    if ($Complete.IsPresent) {
        [int]$Progress = 100
        Write-Progress -Id 100 -Activity "Collecting Autopilot diagnostics logs" -Status "$Progress%  $Activity" -PercentComplete $Progress -Completed
    }
    else {
        [int]$Progress = $CurrentStep / $StepCount * 100
        Write-Progress -Id 100 -Activity "Collecting Autopilot diagnostics logs" -Status "$Progress%  $Activity" -PercentComplete $Progress
    }

    
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

<#
    .SYNOPSIS
        Starts Symantec Endpoint Encryption (SEE) GUI application.

    .DESCRIPTION
        Starts Symantec Endpoint Encryption (SEE) GUI application if it is not running already and installed.
        It requires to copy the files with encryption to an external USB drive.
#>
function Start-SEEApplication {
    try {
        if (Get-Process -Name 'EERapplication' -ErrorAction SilentlyContinue) {
            Write-LogInfo 'Symantec Endpoint Encryption (SEE) GUI application (EERApplication.exe) already running.'
            return
        }

        $SeeServicePath = 'C:\Program Files\Symantec\Endpoint Encryption Clients\Removable Media Encryption\EERApplication.exe'
        if (Test-Path -Path $SeeServicePath) {
            Write-LogInfo 'Start Symantec Endpoint Encryption (SEE) GUI application (EERApplication.exe).'
            Start-Process -FilePath $SeeServicePath
        }
        else {
            Write-LogInfo 'Symantec Endpoint Encryption (SEE) hasn''t been installed. The files can be copied to an USB drive without encryption.'
        }
    }
    catch {
        Write-LogError "Failed to start the Symantec Endpoint Encryption (SEE) GUI application. $_"
    }
}

<#
    .SYNOPSIS
        Enumerates the local groups and its members and write it into an text output file.

    .DESCRIPTION
        Enumerates the local groups and its members and write it into an text output file.
        It translates the localized name of the well know groups or accounts to its English one if necessary.

    .PARAMETER OutFile
        Full path of the output file.        
#>    
function Export-LocalGroup {
    param (
        [Parameter(Mandatory)]
        $OutFile
    )

    # Relative identifier, RID (the last tag of the SID) to name table.
    # More info: https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
    #            https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups
    $RidToName = @{
        '500' = 'Administrator'
        '501' = 'Guest'
        '502' = 'KRBTGT'
        '512' = 'Domain Admins'
        '513' = 'Domain Users'
        '514' = 'Domain Guests'
        '515' = 'Domain Computers'
        '516' = 'Domain Controllers'
        '517' = 'Cert Publishers'
        '518' = 'Schema Admins'
        '519' = 'Enterprise Admins'
        '520' = 'Group Policy Creator Owners'
        '553' = 'RAS and IAS Servers'
    }

    
    # Well know SIDs table.
    # More info: https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
    #            https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups
    $SidToName = @{
            'S-1-0'         = 'Null Authority'
            'S-1-0-0'       = 'Nobody'
            'S-1-1'         = 'World Authority'
            'S-1-1-0'       = 'Everyone'
            'S-1-2'         = 'Local Authority'
            'S-1-2-0'       = 'Local'
            'S-1-2-1'       = 'Console Logon '
            'S-1-3'         = 'Creator Authority'
            'S-1-3-0'       = 'Creator Owner'
            'S-1-3-1'       = 'Creator Group'
            'S-1-3-2'       = 'Creator Owner Server'
            'S-1-3-3'       = 'Creator Group Server'
            'S-1-3-4'       = 'Owner Rights'
            'S-1-4'         = 'Non-unique Authority'
            'S-1-5'         = 'NT Authority'
            'S-1-5-1'       = 'Dialup'
            'S-1-5-2'       = 'Network'
            'S-1-5-3'       = 'Batch'
            'S-1-5-4'       = 'Interactive'
            'S-1-5-6'       = 'Service'
            'S-1-5-7'       = 'Anonymous Logon'
            'S-1-5-8'       = 'Proxy'
            'S-1-5-9'       = 'Enterprise Domain Controllers'
            'S-1-5-10'      = 'Principal Self'
            'S-1-5-11'      = 'Authenticated Users'
            'S-1-5-12'      = 'Restricted Code'
            'S-1-5-13'      = 'Terminal Server Users'
            'S-1-5-14'      = 'Remote Interactive Logon'
            'S-1-5-15'      = 'This Organization'
            'S-1-5-17'      = 'IUSR'
            'S-1-5-18'      = 'Local System'
            'S-1-5-19'      = 'Local Service'
            'S-1-5-20'      = 'Network Service'
            'S-1-5-32-544'  = 'Administrators'
            'S-1-5-32-545'  = 'Users'
            'S-1-5-32-546'  = 'Guests'
            'S-1-5-32-547'  = 'Power Users'
            'S-1-5-32-548'  = 'Account Operators'
            'S-1-5-32-549'  = 'Server Operators'
            'S-1-5-32-550'  = 'Print Operators'
            'S-1-5-32-551'  = 'Backup Operators'
            'S-1-5-32-552'  = 'Replicator'
            'S-1-5-32-554'  = 'Pre-Windows 2000 Compatible Access'
            'S-1-5-32-555'  = 'Remote Desktop Users'
            'S-1-5-32-556'  = 'Network Configuration Operators'
            'S-1-5-32-557'  = 'Incoming Forest Trust Builders'
            'S-1-5-32-558'  = 'Performance Monitor Users'
            'S-1-5-32-559'  = 'Performance Log Users'
            'S-1-5-32-560'  = 'Windows Authorization Access Group'
            'S-1-5-32-561'  = 'Terminal Server License Servers'
            'S-1-5-32-562'  = 'Distributed COM Users'
            'S-1-5-32-568'  = 'IIS_IUSRS'
            'S-1-5-32-569'  = 'Cryptographic Operators'
            'S-1-5-32-573'  = 'Event Log Readers'
            'S-1-5-32-574'  = 'Certificate Service DCOM Access'
            'S-1-5-32-575'  = 'RDS Remote Access Servers'
            'S-1-5-32-576'  = 'RDS Endpoint Servers'
            'S-1-5-32-577'  = 'RDS Management Servers'
            'S-1-5-32-578'  = 'Hyper-V Administrators'
            'S-1-5-32-579'  = 'Access Control Assistance Operators'
            'S-1-5-32-580'  = 'Remote Management Users'
            'S-1-5-32-581'  = 'System Managed Accounts Group'
            'S-1-5-32-582'  = 'Storage Replica Administrators'
            'S-1-5-32-583'  = 'Device Owners'
            'S-1-5-64-10'   = 'NTLM Authentication'
            'S-1-5-64-14'   = 'SChannel Authentication'
            'S-1-5-64-21'   = 'Digest Authentication'
            'S-1-5-80'      = 'NT Service'
            'S-1-5-80-0'    = 'All Services'
            'S-1-5-83-0'    = 'NT VIRTUAL MACHINE\Virtual Machines'
    }

    # The name translation does not work for AAD accounts. Use this hash table for Roles added by default to the local Administrators group.
    $EYAadSidToRoleName = @{
        #EYGS
        'S-1-12-1-2859024178-1255326055-3761374887-1041145935' = 'eygs\Global Administrator'
        'S-1-12-1-3401939450-1126121094-93717125-1093742948'   = 'eygs\Azure AD Joined Device Local Administrator'

        #EYQA
        'S-1-12-1-4231092684-1089425184-2727213503-2833536059' = 'eyqa\Global Administrator'
        'S-1-12-1-4235182311-1078900408-1133325480-1763127927' = 'eyqa\Azure AD Joined Device Local Administrator'

        #Tenant6
        'S-1-12-1-2024343024-1323182037-654116271-2008101666' = 'eytenant6\Global Administrator'
        'S-1-12-1-2015123014-1220601638-1130357901-368986449' = 'eytenant6\Azure AD Joined Device Local Administrator'
    }

    <#
        .SYNOPSIS
            Gets the English name of a localized group or account from its SID.

        .DESCRIPTION
            Gets the English name of a localized group or account from its SID.It returns en
            empty string if the name is already in English.

        .PARAMETER SID
            Account SID.

        .PARAMETER Name
            Name of the SID.

        .OUTPUT
            Returns the English name of a group or account from its SID. It returns en
            empty string if the name is already in English.
        
    #>
    function Get-WellKnownAccountEnglishName {
        param (
            [string]$Sid,
            [string]$Name
        )


        $EnglishName = $SidToName[$Sid]
        if (-not $EnglishName -and $Sid.LastIndexOf("-") -gt -1) {
            $RelativeSid = $Sid.Substring($Sid.LastIndexOf("-") + 1)
            $EnglishName = $RidToName[$RelativeSid]        
        }
    
        if (-not $EnglishName -or $Name.Replace("NT AUTHORITY\", "") -eq $EnglishName) {
            return ""
        }

        $EnglishName
    
    }

    <#
        .SYNOPSIS
            Gets type of a group member.
            e.g. "Local User", "Active Directory Group"

        .DESCRIPTION
            Gets type of a group member.
            e.g. "Local User", "Active Directory Group"

        .PARAMETER Member
        

        .OUTPUT
            Returns the object type.
            e.g. "Local User", "Active Directory Group"
    #>
    function Get-MemberType {
        param (
            $Member
        )

        try {
            # Unknown account
            if ($Member.PrincipalSource -ne 'Unknown') {
                return "{0} {1}" -f $Member.PrincipalSource, $Member.ObjectClass
            }
        
            # Local account
            if ($Member.Name.StartsWith('NT AUTHORITY')) {
                return "Local $($Member.ObjectClass)"
            }

            # Local Account 
            if ($SidToName[$Member.SID]) {
                return "Local $($Member.ObjectClass)"
            }
        }
        catch {
            # Suppress error.
        }

        # If it something else use the object class as a type
        $Member.ObjectClass
    }

    <#
        .SYNOPSIS
            Gets the user name part of an account if the fullname is in domain\username.

        .DESCRIPTION
            Gets the user name part of an account if the fullname is in domain\username.

        .PARAMETER Fullname
            Fullname of an account in domain\username format.

        .OUTPUT
            Returns the user name part of the full name.
        
    #>
    function Get-UserName {
        param (
            $FullName
        )

        $index = $FullName.IndexOf('\')
        $FullName.substring($index + 1)
    }

    <#
        .SYNOPSIS
            Constructs and writes a group member account information into the output file.

        .DESCRIPTION
            Constructs and writes a group member account information into the output file.
            "NT AUTHORITY\Authenticated Users (Local Group)"

        .PARAMETER Member
            Member account object.
        
    #>
    function Write-MemberInfo {
        param (
            $Member
        )

        try {
            # Get the account information.
            $Type = Get-MemberType -Member $Member
            $EnglishName = Get-WellKnownAccountEnglishName -Sid $Member.SID -Name $Member.Name
            $AccountName = Get-UserName -FullName $Member.Name
            # Select the output format.
            if ($EnglishName -and $AccountName -ne $EnglishName) {
                # The account name is localized, let's add the English name to the output.
                $Message = '    {0} [{2}] ({3}) - {1}'
            }
            else {
                # The account name is already in English.
                $Message = '    {0} ({3}) - {1}'
            }

            # e.g.
            # NT AUTHORITY\Authenticated Users (Local Group)
            Write-OutFile ($message -f $Member.Name, $Type, $EnglishName, $Member.Sid)
        }
        catch {
        }
    
    }

    <#
        .SYNOPSIS
            Writes a message line into the output file.

        .DESCRIPTION
            Writes a message line into the output file.

        .PARAMETER Message
            Message text to be written into the output file.
    #>
    function Write-OutFile {
        param (
            $Message
        )

        if ($EchoToHost) {
            Write-LogInfo $Message
        }

        try {
            $Message | Out-File -FilePath $OutFile -Encoding unicode -Append -Force

        }
        catch {
            # Suppress write errors.
        }
    }

    <#
        .SYNOPSIS
            Initialize a clean output file and folder.

        .DESCRIPTION
            Remove the existing output file or creates the output folder.
    #>
    function Initialize-OutFile {
        # Remove the existing output file.
        if (Test-Path -Path $OutFile ) {
            Remove-Item -Path $OutFile
        }

        # Create the output folder if it does not exists.
        $OutFolder = Split-Path $OutFile -Parent
        if (-not (Test-Path -Path $OutFolder -PathType Container)) {
            New-Item -Path $OutFolder -ItemType Directory -Force | Out-Null
        }
    }

    <#
        .SYNOPSIS
            Writes the group information into the output file.

        .DESCRIPTION
            Writes the group information into the output file.

        .PARAMETER Group
            Group object.
    #>
    function Write-GroupInfo {
        param (
            $Group
        )

        try {
            $GroupType = Get-MemberType -Member $Group
    
            $EnglishName = Get-WellKnownAccountEnglishName -Sid $Group.SID -Name $Group.Name
            if ($EnglishName) {
                $Message = '{0} [{1}]'
            }
            else {
                $Message = '{0}'
            }

            Write-OutFile ($Message -f $Group.Name, $EnglishName)
        }
        catch {
        }
    }

    <#
        .SYNOPSIS
            Identify the account source (Local, AzureAd, ActiveDirectory) from its SID string.

        .DESCRIPTION
            Identify the account source (Local, Azure AD, ActiveDirectory) from its SID string.
            The returns 

        .PARAMETER SID
            SID string of the account.

        .RETURN
            Returns the source of the account. e.g. Local
        
    #>
    function Get-SidSource {
        param (
            $SID
        )

        if ($SID.StartsWith($LocalComputerSid)) {
            return [Microsoft.PowerShell.Commands.PrincipalSource]::Local
        }

        if ($SID.StartsWith('S-1-12-1-')) {
            return [Microsoft.PowerShell.Commands.PrincipalSource]::AzureAD
        }

        if ($SID.StartsWith('S-1-5-21-')) {
            return [Microsoft.PowerShell.Commands.PrincipalSource]::ActiveDirectory
        }

        return [Microsoft.PowerShell.Commands.PrincipalSource]::Unknown
    }


    <#
        .SYNOPSIS
            Gets members from a local group via ADSI provider.

        .DESCRIPTION
            Gets members from a local group via ADSI provider. The Get-Get-LocalGroupMember fails if an AAD account is member of the group.
            https://github.com/PowerShell/PowerShell/issues/2996

        .PARAMETER Name
            Name of the group.

        .RETURN
            Returns member accounts of the group.
        
    #>
    function Get-LocalGroupMemberADSI {
        param (
            $Name
        )

        [ADSI]$AdsiGroup = "WinNT://$($env:COMPUTERNAME)/$($Group.Name),group"
        $Members = $AdsiGroup.invoke("Members")

        foreach ($member in $Members) {
            # The name is the SID string if the computer cannot translate the SID to its account name.
            $Name = $member.GetType().InvokeMember('Name', 'GetProperty', $Null, $member, $Null)
            $AdsPath = $member.GetType().InvokeMember('AdsPath', 'GetProperty', $Null, $member, $Null)
        
            # Get the SID string.
            $BinarySID = $member.GetType().InvokeMember('ObjectSid', 'GetProperty', $Null, $member, $Null)
            $TextSid = (New-Object System.Security.Principal.SecurityIdentifier($binarySID,0)).Value
        
            if ($Name -notlike "*$TextSid*") {
                # Get the domain\username from AdsPath.
                # https://learn.microsoft.com/en-us/windows/win32/adsi/winnt-adspath
                # e.g.
                # WinNT://EY/TESTPC/EYOnePass
                # WinNT://EY/Domain Users
                $Name = ($AdsPath -split '/', -2)[-2..-1] -join '\'
                $Name = $Name.Replace("$($env:COMPUTERNAME)\", '').Replace('NT AUTHORITY\', '')
            }

            $Class = $member.GetType().InvokeMember('Class', 'GetProperty', $Null, $member, $Null)
            $PrincipalSource = Get-SidSource -SID $TextSID
            if ($PrincipalSource -eq 'AzureAD' -and $EYAadSidToRoleName[$TextSID]) {
                $Name = $EYAadSidToRoleName[$Name]
            }
        

            @{
                Name = $Name
                SID = $TextSid
                ObjectClass = $Class
                PrincipalSource = $PrincipalSource
            }
        }
    }

    <#
        .SYNOPSIS
            Gets members from a local group in various ways.

        .DESCRIPTION
            Gets members from a local group in various ways. The Get-Get-LocalGroupMember fails if an AAD account is member of the group,
            in this case it tried to get the members via ADSI provider.
            https://github.com/PowerShell/PowerShell/issues/2996

        .RETURN
            Returns member accounts of the group.
    #>
    function Get-LocalGroupMemberSafe {
        param (
            $Name
        )
    
        try {
            $Error.Clear()
            $Members = Get-LocalGroupMember -Name $Name -ErrorAction SilentlyContinue
            if ($Error.Count -ne 0) {
                $Members = Get-LocalGroupMemberAdsi -Name $Group.Name
            }
            return $Members
        }
        catch {
            Write-LogError 'Failed to get group members.'  
        }
    }

    <#
        .SYNOPSIS
            Sets to English, saves and restores the culture of the current thread.

        .DESCRIPTION
            Sets to English, saves and restores the culture of the current thread.
    
        .PARAMETERS SaveAndSetEnglish
            Switch parameter to save the current thread culture and set it to English.

        .PARAMETERS Restore
            Switch parameter to restore the previously saved thread culture.
    #>
    function Set-Culture {
        param(
            [switch]$SaveAndSetEnglish,
            [switch]$Restore
        )

        if ($SaveAndSetEnglish.IsPresent) {
            $Script:SavedCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture 
            $Script:SavedUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture

            $EnglishCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $EnglishCulture 
            [System.Threading.Thread]::CurrentThread.CurrentUICulture = $EnglishCulture 
        
        }
        elseif ($Restore.IsPresent) {
            if ($Script:SavedCulture)  {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $SavedCulture
            }
            if ($Script:SavedUICulture) {
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $SavedUICulture 
            }
        }
    }

    # Start export.
        
    # Set to $true if the output needs to be written into the host as well.
    $EchoToHost = $false

    Write-LogInfo 'Start script.'

    Initialize-OutFile

    Write-OutFile "Enumerate the local group membership on $($env:COMPUTERNAME).`n"
    Write-OutFile ('-' * 80)

    Set-Culture -SaveAndSetEnglish

    $LocalGroups = Get-LocalGroup

    $LocalComputerSid = (Get-LocalUser | Select-Object -First 1 -ExpandProperty SID).AccountDomainSID.Value

    foreach ($Group in $LocalGroups) {
    
        Write-GroupInfo $Group

        $Members = Get-LocalGroupMemberSafe -Name $Group.Name
    
        if (-not $Members) {
            Write-OutFile '  No members found.'
        }
        else {
            Write-OutFile '  Members:'
        }

        foreach ($Member in $Members) {
            Write-MemberInfo -Member $Member
        }

        Write-OutFile ""
    }

    Write-OutFile ('-' * 80)
    Write-OutFile "`nNo more groups found."

    Set-Culture -Restore

    Write-LogInfo 'Script completed.'
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

# Start Symantec Endpoint Encryption (SEE) GUI application to copy the files with encryption to an external USB drive.
Start-SEEApplication

# Start collecting diagnostic information.
Write-LogInfo ('*' * $EYSeparatorCharCount)
Write-LogInfo 'Start to collect the autopilot diagnostics information.'

# Collect diagnostics logs (START).
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

Update-Progress -Activity 'Collecting PC Setup Assistant status'
Copy-FolderContent -Path "$($env:PUBLIC)\Documents\DoNotDelete" -Destination "$ZipTempFolder\PCSAStatus"

Update-Progress -Activity 'Collecting PC Setup Assistant data'
Copy-FolderContent -Path "$($env:ProgramData)\Ernst & Young\EYPCSetupAssistant\Data" -Destination "$ZipTempFolder\PCSAData"

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

Update-Progress -Activity 'Collecting Autopilot offline profile'
Copy-File -Path "$($env:windir)\Provisioning\Autopilot" -Destination "$ZipTempFolder\OfflineProfile" -Filter 'AutopilotConfigurationFile.json'

Update-Progress -Activity 'Collecting diagnostic CSP logs'
Copy-File -Path "$($env:ProgramData)\Microsoft\DiagnosticLogCSP\Collectors" -Destination "$ZipTempFolder\DiagnosticLogCSP" -Filter '*.etl'

Update-Progress -Activity 'Collecting WinGet logs'
Copy-File -Path "$($env:windir)\Temp\winget" -Destination "$ZipTempFolder\Winget" -Filter 'defaultstate*.log'

Update-Progress -Activity 'Collecting Microsoft Teams logs'
Copy-File -Path "$($env:LOCALAPPDATA)\SquirrelTemp" -Destination "$ZipTempFolder\Teams" -Filter '*.log'
Copy-File -Path "$($env:LOCALAPPDATA)\SquirrelTemp" -Destination "$ZipTempFolder\Teams" -Filter '*.json'
Copy-File -Path "$($env:LOCALAPPDATA)\SquirrelTemp" -Destination "$ZipTempFolder\Teams" -Filter 'SquirrelSetup.log'

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
Export-WindowsEvent -LogName System -Path "$ZipTempFolder\EventLogs\System.evtx"

Update-Progress -Activity 'Exporting Setup eventlog'
Export-WindowsEvent -LogName Setup -Path "$ZipTempFolder\EventLogs\Setup.evtx"

Update-Progress -Activity 'Exporting Application eventlog'
Export-WindowsEvent -LogName Application -Path "$ZipTempFolder\EventLogs\Application.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AAD/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AAD/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Aad-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-BitLocker/BitLocker Management eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-BitLocker/BitLocker Management' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Bitlocker-Management.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider-Admin.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Debug eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Debug' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider-Debug.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-ModernDeployment-Diagnostics-Provider-Admin.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Autopilot eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Autopilot' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-ModernDeployment-Diagnostics-Provider-Autopilot.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Diagnostics eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-ModernDeployment-Diagnostics-Provider/Diagnostics' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-ModernDeployment-Diagnostics-Provider-Diagnostics.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AppXDeployment/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AppXDeployment/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AppXDeployment-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AppXDeploymentServer/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AppXDeploymentServer/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AppXDeploymentServer-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AssignedAccess/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AssignedAccess/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AssignedAccess-Admin.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AssignedAccess/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AssignedAccess/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AssignedAccess-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AssignedAccessBroker/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AssignedAccessBroker/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AssignedAccessBroker-Admin.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-AssignedAccessBroker/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-AssignedAccessBroker/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-AssignedAccessBroker-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-Crypto-Ncrypt/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-Crypto-Ncrypt/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Crypto-Ncrypt-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-Provisioning-Diagnostics-Provider/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-Provisioning-Diagnostics-Provider/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Provisioning-Diagnostics-Provider-Admin.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-Provisioning-Diagnostics-Provider/AutoPilot eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-Provisioning-Diagnostics-Provider/AutoPilot' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Provisioning-Diagnostics-Provider-AutoPilot.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-Provisioning-Diagnostics-Provider/ManagementService eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-Provisioning-Diagnostics-Provider/ManagementService' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Provisioning-Diagnostics-Provider-ManagementService.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-Shell-Core/Operational eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-Shell-Core/Operational' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-Shell-Core-Operational.evtx"

Update-Progress -Activity 'Exporting Microsoft-Windows-User Device Registration/Admin eventlog'
Export-WindowsEvent -LogName 'Microsoft-Windows-User Device Registration/Admin' -Path "$ZipTempFolder\EventLogs\Microsoft-Windows-User Device Registration-Admin.evtx"

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

Update-Progress -Activity 'Exporting local group membership'
Export-LocalGroup -OutFile "$ZipTempFolder\LocalGroups.txt"

Write-LogInfo 'Diagnostics information had been collected.'
Write-LogInfo ('*' * $EYSeparatorCharCount)

##################################################
# Collect diagnostics logs (END).

Update-Progress -Activity 'Creating zip archive'
Compress-Folder -Path $ZipTempFolder -Destination $ZipFilePath

Update-Progress -Activity 'Cleanup temp folder'
Delete-Folder -Path $ZipTempFolder

# This feature had been disabled in v1.7.
#Update-Progress -Activity 'Update Intune log collection'
#Update-IntuneLogCollection $ZipFilePath $IntuneLogCollectionFolder

Update-Progress "Completed" -Complete

# Show completed message box.
Show-CompletedMessageBox

# Open the zip output folder.
$ExplorerFolder = (Split-Path -Path $ZipFilePath -Parent)
Write-LogInfo "Open the zip archive's folder $ExplorerFolder in File Explorer."
explorer $ExplorerFolder

# All done, exit the script.
Write-LogInfo "Script finished."
