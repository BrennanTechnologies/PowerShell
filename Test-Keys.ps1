### Test keys

function Test-Keys {
    param (
        $SENDKEYS,
        $WINDOWTITLE
    )

    do {
        $wshell = New-Object -ComObject wscript.shell;
        IF ($WINDOWTITLE) {$wshell.AppActivate($WINDOWTITLE)}
        Sleep 1
        IF ($SENDKEYS) {$wshell.SendKeys($SENDKEYS) | Out-Null}

        $i = $($i + 1)
        $y = ($i * $t)/60
        Write-Host "i: $i"
        Write-Host "Testing: $y mins"

        $t = 300
        Sleep $t

    } until ($i -eq "-1")
}

cls
Write-Host "Starting Test-Keys"
Start-Process Calc.exe
$i = 0
#Test-Keys -SENDKEYS '%{1}' WINDOWTITLE 'Calculator'| Out-Null
Test-Keys -SENDKEYS '%{}' WINDOWTITLE 'Calculator'| Out-Null


<#
explorer ms-settings:display;
Start-Sleep -Seconds 2;
$WshShell = New-Object -ComObject WScript.Shell;
Start-Sleep -Milliseconds 500;
$WshShell.SendKeys("{TAB 2}{UP 5}");
Start-Sleep -Milliseconds 500;
$WshShell.SendKeys("%{F4}");
#>
