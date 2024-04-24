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