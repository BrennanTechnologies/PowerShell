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