<#
.SYNOPSIS
Sends an email report withh all VM's without Veeam Restore Points.

.DESCRIPTION
Sends an email report withh all VM's without Veeam Restore Points.

.PARAMETER Report
[PSCustomObject] containing all servers with missing restore points.

.PARAMETER VMNameFilter
Filter used by Get-VM -Name $vmNameFilter.

.PARAMETER IncludeTagCategory
[array]  -- Array of Server Tag Assignments to Include.

.PARAMETER ExcludeTagName
[array] -- ### Array of Server Tag Assignments to Exclude.

.PARAMETER ServerRecordAge
# of Days until servers show up in the report.

.PARAMETER To
Email account(s) to send the Alert to.

.PARAMETER From
Email account the Alert is sent from

.PARAMETER Subject
Custom the error message.

.PARAMETER SMTPServer
Mail relay server to send message.

.PARAMETER DeveloperMode
Sets developer level settings for testing and debugging.

.EXAMPLE
Send-EmailReport @serverParams -Report $Report

.INPUTS
[PSCustomObject]$Report

.OUTPUTS
Sends an HTML Email Message via SMTP

#>

function Send-EmailReport {
    [CmdletBinding()]
    Param(
        ### PSObject with Report Data
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$ReportObject
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$To
        ,
        [Parameter(Mandatory = $false)]
        [string]$From = "no-reply@relay-ny.accessabacus.com"
        ,
        [Parameter(Mandatory = $false)]
        [string]$Subject
        ,
        [Parameter(Mandatory = $false)]
        [string]$SMTPServer = "relay-ny.accessabacus.com"
        ,
        [Parameter(Mandatory = $false)]
        [string]$Source
        ,
        ### Calling Script Name
        [Parameter(Mandatory = $false)]
        [string]$Script
        ,
        ### Calling Function Name
        [Parameter(Mandatory = $false)]
        [string]$Function
        ,
        ### Suppress Console & Log Output
        [Parameter(Mandatory = $false)]
        [switch]$Quiet
        ,
        [Parameter(Mandatory = $false)]
        [string]$DeveloperMode = $true

    )
    Begin {
        #Write-Log -LogString "Start : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray

        if($DeveloperMode -eq $true){
            $To = "cbrennan@abacusgroupllc.com"  ### <-- Testing/Development Report
        }

        ### HTML Head
        ###---------------------------------------------
        $htmlStyle  = "<style>"
        $htmlStyle += "body{font-family:Verdana,Arial,Sans-Serif; font-size:11px; font-color:black;}"
        $htmlStyle += "table{border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse; }" #width:800px; 
        $htmlStyle += "th{font-size:10px; border-width: 1px; padding: 3px; border-style: solid; border-color: gray; color:white; background-color:#00008B; text-align:center; }" #text-align:center background-color: darkblue;
        $htmlStyle += "th{font-size:10px; border-width: 1px; padding: 3px; border-style: solid; border-color: gray; color:black; background-color:#C0C0C0; text-align:center; }" #text-align:center background-color: darkblue;
        $htmlStyle += "td{font-size:10px; border-width: 1px; padding: 3px; border-style: solid; border-color: gray; color:black; background-color:White; text-align:center; }"
        $htmlStyle += "</style>"
    }
    Process {
        ### Message Body - Add Header
        ###---------------------------------------------
        $body  = $htmlStyle
        $body += "<body>"
        $body += "<i><font size='3';color='gray';>"      + "Abacus DevOps Report:"                                                         + "</font></i><br>"
        $body += "<b><font size='4';color='darkblue';>"                                                   + $Subject                       + "</font></b>"
        $body += "<br>"                                  + "Report Date: "                                + $(Get-Date)                    + "<br><br><br>"
        #$body += "<u><b>"                                + "Search Filters: "                                                              + "</b></u>"
        #$body += "<br>"                                  + "Server Name Filter : <b>"                     + $VMNameFilter.ToUpper()        + "</b></font>"
        #$body += "<br>"                                  + "Tag Include Filter :  <font color='green';>"  + $IncludeTagCategory.ToUpper()  + "</font>"
        #$body += "<br>"                                  + "Tag Exclude Filter :  <font color='red';>"    + $ExcludeTagName.ToUpper()      + "</font>"


        ### Expand Member Arrays
        ###---------------------------------------------
 <#
        #[PSCustomObject]$ReportObject = Get-Service | Select-Object -Property *
        $Report = @()
        foreach($Object in $ReportObject){
            [PSCustomObject]$Members = $ReportObject | Get-Member -MemberType NoteProperty
            foreach($Member in $Members){
                $ReportMembers =@()
                if($Object.($Member.Name)-is [array]){
                    [array]$ExpandedMember = $Object.($Member.Name) | Select-Object -ExpandProperty $Member.Name
                    #$ExpandedMember
                    $ReportMembers+= $ExpandedMember

                }
                else {
                    #$Member
                    $ReportMembers += $Member
                }
                $Report += $ReportMembers 
            }
        }
        $Report
#>
        [PSCustomObject]$ReportObject = Get-Service | Select-Object -Property *
        $Report = @()
        foreach($Object in $ReportObject){
            $Object
            $Report += $Object
        }


        ### Message Body - Add Report Data
        ###---------------------------------------------
        $body += $Report | ConvertTo-Html | Out-String
        #$body += $ReportObject | ConvertTo-Html | Out-String

        <#
        ### Message Body - Add Report Data
        ###---------------------------------------------
        foreach($ServerGroup in $VMNameFilter){
            Write-Host "Server Group: " $ServerGroup -ForegroundColor Cyan
            $body +=   "<br><b><font size='2';color='darkblue';>Server Group: " + $ServerGroup + "</font></b><br></font>"
            
            Write-Host ( $Report | Where-Object { $_.ServerName -like $ServerGroup } | Format-Table   | Out-String ) -ForegroundColor DarkCyan
            
            ### Expand Arrays - TagName & TagCategory
            ###------------------------------------------
            $ServersInGroup = $Report | Where-Object { $_.ServerName -like $ServerGroup } | `
                Select-Object vCenter, ServerName, `
                    @{ n = 'TagCategory' ; e = { ($_ | Select-Object -ExpandProperty TagCategory ) -join ", " } } , `
                    @{ n = 'TagName'     ; e = { ($_ | Select-Object -ExpandProperty TagName     ) -join ", " } } , `
                    VeeamRestorePoint, FirstSeen `
                    | ConvertTo-Html 
            if( $null -ne $ServersInGroup ){
                $body += $ServersInGroup 
            } 
            else {
                $ServersInGroup = New-Object PSObject -Property @{ Message = ( "No servers found with tags matching filters: " + $includeTagCategory.ToUpper() + " and " + $excludeTagName.ToUpper() )}
                $body += $ServersInGroup 
            }
        }
        #>

        ### Message Body - Add Footer
        ###---------------------------------------------        
        #$body += "<br><font color='gray';>Script Run Time: " + ($(Get-Date) - $ScriptStartTime) + "<br><br>"

        ### End Message Body <<<--- Must be Last
        ###---------------------------------------------        
        $body += "</body>"

        ## Display Report
        ###---------------------------------------------
        if(-Not $Quiet){
            Write-Host "To      : " $To         -ForegroundColor Cyan
            Write-Host "From    : " $From       -ForegroundColor Cyan
            Write-Host "Subject : " $Subject    -ForegroundColor Cyan
        }
        ### Send Email Message
        ###---------------------------------------------
        try {
            Write-Host "Emailing Report: " $Subject  -ForegroundColor Yellow
            Send-MailMessage `
                -SmtpServer $SMTPServer `
                -To         ($To -split ",") `
                -From       $From `
                -Body       $Body `
                -Subject    $Subject `
                -BodyAsHtml
        } 
        catch {
           # $ErrMsg = "ERROR: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message
           # Write-Log -LogString $ErrMsg -LogLevel Warning -LogObject $VeeamReportLog
        }
    }
    End {
        #if($DeveloperMode){Write-Log -LogString "End   : $((Get-PSCallStack)[0].Command)" -LogLevel Output -LogObject $VeeamReportLog -ForegroundColor DarkGray}
    }
}