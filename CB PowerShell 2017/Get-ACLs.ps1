cls
$report =@()

### Script Start/Stop times for calulating toal run time.
$script:StartTime = Get-Date
write-host "Start Time: " $StartTime

#$path = "S:\New Wellington Financial"
$path = "S:\NNJ"


write-host "Getting Folders . . . "  -ForegroundColor cyan
$folders = @()
#$folders = Get-ChildItem -path $path -force -recurse 
#$folders = Get-ChildItem -path $path -force -recurse | Where {$_.PSIsContainer}
$folders = Get-ChildItem -path $path -force -recurse -Directory 
#$folders = Get-ChildItem -path $path -force -recurse -Directory | Measure-Object -Property length -Minimum -Maximum -Average

For($i = 1; $i -le $folders.count; $i++)
{
    Write-Progress -Activity “Collecting files” -status “Finding file $i” -percentComplete ($i / $folders.count*100)
}

###
#$StartDate = ((Get-Date).AddYears(-3))
#$EndDate = Get-Date
#Get-ChildItem -path $directory -Recurse  | where { $_.lastaccesstime -ge [datetime]$startDate -and $_.lastaccesstime -lt [datetime]$endDate} #| select fullname | Export-CSV -Path $outPutFile


ForEach ($folder in $folders)
{
    #Convert Powershell Provider Folder Path to standard folder path
    $PSPath = (Convert-Path $folder.pspath)

    # Get attributes of folders
    # $Folder | Get-Member

    ###write-host "Folder: " $Folder
    #write-host "Root: "$folder.Root
    write-host "PSPath: " $PSPath -ForegroundColor Yellow
    #write-host "Name: "$folder.Name
    #write-host "FulleName: "$folder.FullName    
    #write-host "Attributes: "$folder.Attributes
    #write-host "Created: "$folder.CreationTime
    #write-host "LastAccess: "$folder.LastAccessTime
    #write-host "LastWriteTime: "$folder.LastWriteTime
    #write-host "IsFolder: "$folder.PSIsContainer
    
    #write-host "BseName: "$folder.BaseName
    #write-host "Parent: "$folder.Parent
    write-host `n`n

    ############################
    # Build Hash Table
    ############################

    $hash = [ordered]@{            

        Root           = $folder.Root
        PSPath         = $PSPath
        Name           = $folder.Name
        FullName       = $folder.FullName         
        Attributes     = $folder.Attributes
        PSIsContainer  = $folder.PSIsContainer         
        CreationTime   = $folder.CreationTime         
        LastAccessTime = $folder.LastAccessTime
        LastWriteTime  = $folder.LastWriteTime              
    }                           

    $PSObject =  New-Object PSObject -Property $hash
    $Report   += $PSObject   

    #Get-Acl -path $PSPath | Format-List #-property AccessToString | Out-File -append "C:\Powershell\Results\$filename"
}


############################
# mEASURE sCRIPT
############################
$StopTime = Get-Date
$ElapsedTime = ($StopTime-$StartTime) -f $nts
write-host `n`n
write-host "Script ended at $StopTime" white
#write-log "Elapsed Time: $(($StopTime-$StartTime).totalminutes) minutes"
write-host "Elapsed Time: $ElapsedTime" white



############################
# Export & Show the File
############################
$Path = "c:\reports\"
$ReportDate = Get-Date -Format ddmmyyyy
$ReportFile = $Path + "\Shares_$reportdate.txt"

$Report | Export-Csv -Path $ReportFile -NoTypeInformation 
start-process $ReportFile
