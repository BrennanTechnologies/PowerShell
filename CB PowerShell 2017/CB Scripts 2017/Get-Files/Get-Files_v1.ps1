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

cls
$Report = @()

$error.clear() # Clear the Error Array
Remove-Variable * -ErrorAction SilentlyContinue # Clear all variables


### Script Start/Stop times for calulating toal run time.
$StartTime = Get-Date


  
############################
# Set Error Action
############################
$ErrorActionPreference =  "Stop" # Set to Stop to catch non-terminating errors with Try-Catch blocks
$ErrorActionPreference = “SilentlyContinue”
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference =  "Inquire"
#$ErrorActionPreference =  "Ignore"



############################
# Set Path to Search
############################
$Path = "\\col-file01\shared"
#$Path = "\\col-file01\Shared\Worksmart"
#$Path = "\\col-file01\Shared\1-Chicago\_WorkSmart Training Folder"
#$Path = "\\col-file01\Shared\CBrennan"
$Path = "\\col-file01\Shared\A"

#$Path = "\\col-file01\Shared\Catawba College\"

############################
# Get-Files Function
############################

$AgeDate = (Get-Date).AddYears(-3)

Write-Host "Recursing Folders in: " $Path -ForegroundColor Yellow
$RootFolders = get-childitem $Path -Directory -Recurse #-Depth 0 #| Where-Object {$_.name -Like "*Worksmart*"} 


$FolderCounter = $null

foreach ($Folder in $RootFolders)
{
    $FolderCounter += 1

    try
    {
        #$Folders  = Get-Childitem $Folder.FullName -Recurse -Depth 0 -Directory
        $AllFiles  = Get-Childitem $Folder.FullName -Recurse -Depth 0 -File
    }
    catch
    {
        write-host "ERROR: " $Folder $Error[0].Exception -foregroundColor Red
        $Error[0].Exception
    }

    $AgedFiles     = $AllFiles  | Where-Object {$_.LastWriteTime -lt $AgeDate} 

    $FolderName    = $Folder.FullName
    #$FolderCount  = $Folders.Count
    $AllFileCount  = $AllFiles.Count
    $AgedFileCount = $AgedFiles.Count

    #$AllFolderCounter += $FolderCount
    $AllFileCounter    += $FileCount
    $AgedFileCounter   += $AgedFileCount

    if ($AllFileCount -eq $AgedFileCount)
    {
        $ArchiveFolder  = $FolderName
        write-host "Archive" $ArchiveFolder -ForegroundColor Red
    }
    else
    {
        write-host "No-Archive" $FolderName -ForegroundColor cyan
    }

    ############################
    # Build Hash Table
    ############################

    $hash = [ordered]@{            

        ArchiveFolderName  = $ArchiveFolder
        AllFileCount       = $AllFiles.Count
        AgedFileCount      = $AgedFiles.Count
    }                           
    
    ###$PSObject  =  New-Object PSObject -Property $hash
    $Report   += New-Object PSObject -Property $hash
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
$Path = "c:\reports\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Shares_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile