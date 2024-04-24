Param([Parameter(Mandatory = $True,Position=0)][string]$Env)


### Import ECI Modules
### --------------------------------------------------
function Import-ECI.Root.ModuleLoader
{
    Param([Parameter(Mandatory = $True)][string]$Env)

    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Cyan

    ### Set Repository Name Space
    ###-------------------------------------
    if ($Env -eq "Dev")          {$Environment = "Development"}
    if ($Env -eq "Prod")         {$Environment = "Production"}
    if ($Env -eq "Development")  {$Environment = "Development"}
    if ($Env -eq "Production")   {$Environment = "Production"}

    ######################################
    ### Bootstrap Module Loader
    ######################################

    ### Connect to the Repository & Import the ECI.ModuleLoader
    ### ----------------------------------------------------------------------
    $AcctKey         = ConvertTo-SecureString -String "VSRMGJZNI4vn0nf47J4bqVd5peNiYQ/8+ozlgzbuA1FUnn9hAoGRM9Ib4HrkxOyRJkd4PHE8j36+pfnCUw3o8Q==" -AsPlainText -Force
    $Credentials     = $Null
    $Credentials     = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\eciscripts", $AcctKey
    $RootPath        = "\\eciscripts.file.core.windows.net\clientimplementation"
    
    New-PSDrive -Name X -PSProvider FileSystem -Root $RootPath -Credential $Credentials -Scope Global

    . "\\eciscripts.file.core.windows.net\clientimplementation\Root\$Env\ECI.Root.ModuleLoader.ps1" -Env $Env
}

& {
    BEGIN
    {
        Write-Host "ECI EMI Atiomation Reports" -ForegroundColor Magenta
        Import-ECI.Root.ModuleLoader -Env $Env
        $global:DevOps_ConnectionString  =  "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;” # <-- Need to Encrypt Password !!!!!!
        Get-ECI.EMI.Automation.SystemConfig -Env $Env -DevOps_ConnectionString $DevOps_ConnectionString 
    }

    PROCESS
    {
        ### Email Constants
        ###---------------------
        $From    = "cbrennan@eci.com"
        #$From    = $SMTPFrom
        $To      = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
        #$To    = "cbrennan@eci.com"
        $SMTP    = "alertmx.eci.com"
        #$SMTP    = $SMTPServer
        $Subject = "Daily Server Automation Reports:  $(Get-Date -f MM-dd-yyy)"

        Write-Host $Subject -ForegroundColor Cyan

        $Message = $Null

        ### Report Header
        ###-------------------------
        $Header = "
            <!DOCTYPE html>
            <html><head>
            <style>
            #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
            BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
    
            TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;table-layout:fixed;}
        
            TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color: white}
    
            TD {border-width: 1px; padding: 1px; border-style: solid; border-color: black;white-space: nowrap;}

            </style>
            </head>
        "
        $Header += "<body>"
        $Header += "<font size='2';color='gray';>ECI EMI Server Automation</font>"
        $Header += "<h3><font color='navy';>$Subject</font></h3>"
        $Header += "<font size='3';color='gray';>Last 24 Last Hours: $(Get-Date) UTC to $DateDiff UTC</font>"

        $Message += $Header

        Report-ServerRequests
        $Message += $Report
        Report-ServersProvisioned
        $Message += $Report
        Report-ReadOnlyServers
        $Message += $Report
        Report-ServerMgmtRequests
        $Message += $Report
        Report-ServerMgmtOperations
        $Message += $Report

        ### End HTML
        $Message += "</body></html>"

        ### Send Email
        ###--------------
        Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP
    }
    END {}

}


