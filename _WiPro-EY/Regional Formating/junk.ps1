
function my-function {
    try{
        gci -Path "c:\badirectory" -ErrorAction Stop
    }
    catch{
        $nl = "`n"
        Write-Host "An error occurred in $($MyInvocation.MyCommand.Name). $nl `t $_" -ForegroundColor Cyan
    }
}
cls
my-function
