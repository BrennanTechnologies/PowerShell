
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
Test-Keys -SENDKEYS '%{~}' WINDOWTITLE 'Calculator'| Out-Null 
