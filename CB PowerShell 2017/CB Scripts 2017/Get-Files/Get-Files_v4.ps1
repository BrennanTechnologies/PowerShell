cls

# Clear all variables
$error.clear() # Clear the Error Array
Remove-Variable * -ErrorAction SilentlyContinue # Clear all variables
$Report = @()

############################
# Set Path to Search
############################
$Path = "\\col-file01\shared"
#$Path = "\\col-file01\Shared\Worksmart"
#$Path = "\\col-file01\Shared\1-Chicago\_WorkSmart Training Folder"
#$Path = "\\col-file01\Shared\CBrennan"
#$Path = "\\col-file01\Shared\Catawba College\"
#$Path = "\\col-file01\Shared\1-Chicago\1-Chicago D&O\"
#$Path = "\\col-file01\Shared\A"


############################
# Set Error Action
############################
$ErrorActionPreference =  "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
$ErrorActionPreference = “SilentlyContinue”
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference =  "Inquire"
#$ErrorActionPreference =  "Ignore"


#$script:ScriptPath  = $PSScriptRoot # Requires PS 3.0
$script:ScriptPath  = split-path -parent $MyInvocation.MyCommand.Definition # Required for PS 2.0

### Script Start/Stop times for calulating toal run time.
$script:StartTime = Get-Date


function Write-Log($string,$color) 
{
    ### Write Error-Trap messages to the console & the log file.
    if ($Color -eq $null) {$color = "magenta"}
    write-host $string -foregroundcolor $color
    "`n`n"  | out-file -filepath $ErrorLogFile -append
    $string | out-file -filepath $ErrorLogFile -append
}

function Start-LogFiles
{
    $script:TimeStamp    = Get-Date -format "MM_dd_yyyy_hhmmss"
   
    # Create the Log Folder.
    $LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}
     
    # Create Error Log File
    $ErrorLogName = "ErrorLog_" + $TimeStamp + ".log"
    $script:ErrorLogFile = $LogPath + "\" + $ErrorLogName
    
    Write-Log "*** OPENING LOG FILE at: $StartTime" Blue

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
        write-log "TRANSCRIPT LOG: Script is running from the ISE.. No Transcript Log will be generated" Blue
    }

}
Start-LogFiles


############################
# File-Attributes
############################
<#
[enum]::GetNames("system.io.fileattributes")
    ReadOnly
    Hidden
    System
    Directory
    Archive
    Device
    Normal
    Temporary
    SparseFile
    ReparsePoint
    Compressed
    Offline
    NotContentIndexed
    Encrypted
#>


############################
# Get-Files Function
############################

Write-Host "Recursing Folders in: " $Path -ForegroundColor Yellow
$RootFolders = get-childitem $Path -Directory -Recurse -Depth 0 #| Where-Object {$_.name -ne "1-Chicago" -or $_.name -ne "NNJ" -or $_.name -ne "CBrennan"} #| Where-Object {$_.name -Like "*Worksmart*"} 

foreach ($SubFolder IN $RootFolders)
{
    If (Test-Path StubFolder:) {Remove-PSDrive StubFolder} 
    #New-PSDrive -Name "X" -PSProvider FileSystem -Root $SubFolder.fullname | Out-null
    #$SubFolder = New-PSDrive -Name "X" -PSProvider FileSystem -Root $SubFolder.fullname | Out-null
    New-PSDrive -Name "StubFolder" -PSProvider "FileSystem" -Root $SubFolder.fullname | Out-null

    #$AllFiles= Get-ChildItem -path $SubFolder.fullname -recurse -File 

    try
    {
        $AllFiles= Get-ChildItem -path $SubFolder.fullname  -recurse -File #-ErrorAction SilentlyContinue
        #$AllFiles = Get-ChildItem -path "A" -recurse -File 
    }
    catch
    {
        write-log "ERROR IN FOLDER: $SubFolder" white
        write-log $AllFiles.DirectoryName[0] red
        write-log $AllFiles.Name[0] Red
        $Error[0].Exception
    }

    # Get All Files
    $AllFilesSize  = ($AllFiles | Measure-Object -Sum Length).Sum / 1KB
    $AllFilesSize  = [math]::Round($AllFilesSize)
    $AllFilesCount  = $AllFiles | Measure-Object | %{$_.Count}

    # Get Aged Files    
    $AgeDate = (Get-Date).AddYears(-3)
    $AgedFiles      = $AllFiles  | Where-Object {$_.LastWriteTime -lt $AgeDate} 
    $AgedFilesCount = $AgedFiles | Measure-Object | %{$_.Count}

    # Find Folders with only Aged files (AllFiels = AgedFiles)
    if ($AllFilesCount -eq $AgedFilesCount -and $AllFilesCount -ne 0)
    {
        $ArchiveFolder  = $True
        write-host "Archive:" $SubFolder.Name "All-Files:"$AllFilesCount "Aged:"$AgedFilesCount "Size:"$AllFilesSize -ForegroundColor Magenta 
    }
    elseif ($AllFilesCount -eq 0)
    {
        $ArchiveFolder  = "AccessDenied"
        write-log "Empty or Access Denied: $SubFolder" Yellow
    }
    else
    {
        $ArchiveFolder  = $False
        write-host "Live:" $SubFolder.Name "All-Files:"$AllFilesCount "Aged:"$AgedFilesCount "Size:"$AllFilesSize -ForegroundColor Green
    }

    ############################
    # Build Hash Table
    ############################

    $hash = [ordered]@{            

        ArchiveFolder      = $ArchiveFolder
        ArchiveFolderName  = $SubFolder.Name
        AllFilesCount      = $AllFilesCount
        AgedFilesCount     = $AgedFilesCount
        AllFilesSize(KB)   = $AllFilesSize
    }                           
    
    $PSObject =  New-Object PSObject -Property $hash
    $Report   += $PSObject
}


############################
# Measure-Script
############################
$StopTime = Get-Date
$ElapsedTime = ($StopTime-$StartTime)
write-host `n`n
write-host "Script ended at $StopTime" 
#write-log "Elapsed Time: $(($StopTime-$StartTime).totalminutes) minutes"
write-host "Elapsed Time: $ElapsedTime"


############################
# Export & Show the File
############################
$ReportDate = Get-Date -Format ddmmyyyy
$ReportPath = $ScriptPath + "\Reports"
$ReportFile = $ReportPath + "\Shares_$reportdate.csv"
$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process notepad.exe $ReportFile


############################
# Open Error Log
############################
start-process notepad.exe $ErrorLogFile