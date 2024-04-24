cls
function Start-LogFiles
{
    $script:TimeStamp    = Get-Date -format "MM_dd_yyyy_hhmmss"
   
    # Create the Log Folder.
    $LogPath = $ScriptPath + "\Logs" 
    if(!(Test-Path -Path $LogPath)) {New-Item -ItemType directory -Path $LogPath | out-null}
     
    # Create Custom Error Log File
    $ErrorLogName = "ErrorLog_" + $TimeStamp + ".log"
    $script:ErrorLogFile = $LogPath + "\" + $ErrorLogName
    
    Write-Log "*** OPENING LOG FILE at: $StartTime" white

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
        write-log "TRANSCRIPT LOG: Script is running from the ISE.. No Transcript Log will be generated" magenta
    }

}

function Write-Log($string,$txt,$color) 
{


    ### Write Error-Trap messages to the console & the log file.
write-host "string: " $string
write-host "txt: " $txt
write-host "color: " $color

    if ($txt -eq $null) {$txt = "-ForegroundColor "}
    if ($color -eq $null) {$color = "magenta"}

#write-host "string: " $string
#write-host "txt: " $txt
#write-host "color: " $color
    
    #write-host $string -foregroundcolor $color
    #write-host $string $txt $color
    #"`n`n"  | out-file -filepath $ErrorLogFile -append
    #$string | out-file -filepath $ErrorLogFile -append
}

write-log "Test w FG" ForegroundColor Blue
#write-log "Test without" Green