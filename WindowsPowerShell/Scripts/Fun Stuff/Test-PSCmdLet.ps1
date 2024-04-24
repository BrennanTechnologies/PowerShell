function Test-PsCmdlet
{
    [CmdletBinding()]
    param()

    Write-Host -ForegroundColor RED “Interactively explore `$PsCmdlet .  Copied `$PsCmdlet to `$p ”
    Write-Host -ForegroundColor RED ‘Type “Exit” to return’
    $p = $pscmdlet
    function Prompt {“Test-PsCmdlet> “}
    $host.EnterNestedPrompt()
}
Test-PsCmdlet