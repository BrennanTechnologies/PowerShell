function Test-Keys {
    param (
        $SENDKEYS,
        $WINDOWTITLE
    )
                    ### Host is OnLine
                ###---------------
$LogicSwitch = '( $Computer.PingIPAddress -ne $null ) -AND ( $Computer.ResolveDNS -ne $null ) -AND ( $Computer.TcpTestSucceeded -ne $true ) -AND ( $Computer.LastLogonTimestamp -lt  $(Get-Date).AddDays(-30) )'
    
    do {
        $wshell = New-Object -ComObject wscript.shell;
        IF ($WINDOWTITLE) {$wshell.AppActivate($WINDOWTITLE)}
        $t = 300
        Sleep $t
        IF ($SENDKEYS) {$wshell.SendKeys($SENDKEYS) | Out-Null}

        $i = $($i + 1)
        $y = ($i * $t)/60
        Write-Host "i: $i"
        Write-Host "Testing: $y mins"
        Test-Keys -SENDKEYS '%{1}' | Out-Null
    } until ($i -eq "5")
    
}
#Do-SendKeys -WINDOWTITLE Print -SENDKEYS '{TAB}{TAB}'
#Do-SendKeys -WINDOWTITLE Print
cls
$i = 0
Test-Keys -SENDKEYS '%{1}' | Out-Null 
