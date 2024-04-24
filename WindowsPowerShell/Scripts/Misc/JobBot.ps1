function Do-JobBot {
    param (
        $SENDKEYS,
        $WINDOWTITLE
    )
    $wshell = New-Object -ComObject wscript.shell;
    if ($WINDOWTITLE) {$wshell.AppActivate($WINDOWTITLE)}
        $t = 30
        Sleep $t
        $i = $($i + 1)
        $y = ($i * $t)/60
    if ($SENDKEYS) {$wshell.SendKeys($SENDKEYS)}
        Write-Host "Testing: $y mins"
        Do-JobBot -SENDKEYS '%{1}'
}
#Do-SendKeys -WINDOWTITLE Print -SENDKEYS '{TAB}{TAB}'
#Do-SendKeys -WINDOWTITLE Print
cls
Do-JobBot -SENDKEYS '%{1}' 
