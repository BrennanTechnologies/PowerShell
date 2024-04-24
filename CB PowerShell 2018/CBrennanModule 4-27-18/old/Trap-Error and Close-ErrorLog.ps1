# https://kevinmarquette.github.io/2017-04-10-Powershell-exceptions-everything-you-ever-wanted-to-know/
# https://www.gngrninja.com/script-ninja/2016/6/5/powershell-getting-started-part-11-error-handling

cls
$Error.Clear()
function Trap-Error
{
    #write-host "TRY-CATCH: *** FAILURE *** executing function: $FunctionName" red 
    Write-Host "Error Thrown In: $((Get-PSCallStack)[1].Command) "  -ForegroundColor Yellow
    write-host "InvocationInfo.Line : " $Error[0].InvocationInfo.Line -ForegroundColor Yellow
    write-host "Exception.Message: " $Error[0].Exception.Message -ForegroundColor Red
    write-host "ScriptStackTrace: " $Error[0].ScriptStackTrace -ForegroundColor DarkRed

    # Write Custom Error Messages
    if ($CustomErrMsg)
    {
        write-log $CustomErrMsg gray
    }
}

function Close-ErrorLog
{
    ###############################################
    ### Remember: Clear All Errors at top of Script
    ### $Error.Clear()
    ###############################################
    
    write-Host "Outputting Error Stack to Error Log" -ForegroundColor Cyan
    write-host "Total ErrorCount:" $Error.Count -ForegroundColor Yellow
    write-host "`n"

    if ($Error.Count -ne 0)
    {
        foreach ($Err in $Error)
        {
           write-host "Error Thrown In: $((Get-PSCallStack)[1].Command) "  -ForegroundColor Yellow
           write-host "Error Stack Index:" ([array]::indexof($Error,$Err)) -ForegroundColor Gray
           write-host "InvocationInfo.Line : " $error[0].InvocationInfo.Line -ForegroundColor DarkYellow
           write-host "Exception.Message: " $Err.Exception.Message -ForegroundColor Red
           write-host "ScriptStackTrace: " $Err.ScriptStackTrace -ForegroundColor DarkRed
        }
    }
    if ($Error.Count -eq 0)
    {
        write-host "No Errors Found!" -ForegroundColor Green
    }
}


#########################

$Cmds = @()
$CMDs += "Bad-Command"
$CMDs += "Get-ChildItem -Path 'z:\badDir' # -ErrorAction SilentlyContinue"

function Throw-Errors
{

    foreach ($Cmd in $Cmds)
    {
        try
        {
            # Create a failure for Test-Connection
             Invoke-Expression $Cmd
        }
        catch
        {
            Trap-Error
        }
    }
}

#############################



Throw-Errors
Close-ErrorLog

