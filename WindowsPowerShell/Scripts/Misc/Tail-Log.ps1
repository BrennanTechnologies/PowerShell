function Tail-Log
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