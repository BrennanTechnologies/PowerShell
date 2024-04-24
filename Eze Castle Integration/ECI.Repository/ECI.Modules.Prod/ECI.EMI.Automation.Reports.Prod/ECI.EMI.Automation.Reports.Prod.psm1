function Report-ServerRequests
{
    ### ServerRequest
    ###-------------------------
    $Portal_DBConnectionString = "server=10.3.3.75;database=ECIPortal;User ID=portal_servermgmt;Password=lTo3ese4ve!r;"
    $ConnectionString =  $Portal_DBConnectionString
    $DateDiff = (Get-Date).AddHours(-24)
    Write-Host "Server Requests:"
    #$Query = "SELECT RequestID,RequestDateTime AS RequestDateTimeUTC,RequestServerRole,GPID,CWID,HostName,InstanceLocation,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,BackupRecovery,DisasterRecovery,DomainUserName,ClientDomain FROM ServerRequest WHERE RequestDateTime > '$DateDiff'"
    $Query = "SELECT RequestID,RequestDateTimeUTC,RequestServerRole,GPID,CWID,HostName,InstanceLocation,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,BackupRecovery,DisasterRecovery,DomainUserName,ClientDomain FROM ServerRequest WHERE RequestDateTimeUTC > '$DateDiff'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft

    $html += "<h5><font color='navy';>Servers Requests:</font></h5>"
    $html += "<b>Total Servers Requested:  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 
    $html +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><th>"+$dt.Columns[$i].ColumnName+"</th></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $html +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }
    $html += "</table>"
    $html += "<br>"
    
    $global:Report = $html
}

function Report-ServersProvisioned
{
    ### Servers Provisioned
    ###--------------------------------------------
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $DateDiff = (Get-Date).AddHours(-24)
    Write-Host "Servers Provisioned:"
    $Query = "SELECT ServerID,GPID,RecordDateTimeUTC,HostName,VMName,RequestID,InstanceLocation,VMID,ServerRole,BuildVersion,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,ClientDomain,DomainUserName,BackupRecovery,DisasterRecovery,RequestDateTime FROM Servers WHERE RecordDateTimeUTC > '$DateDiff'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
    $html += "<body>"
    $html += "<h5><font color='navy';>Servers Provisioned:</font></h5>"
    $html += "<b>Total Servers Provisioned:  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $html +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><th>"+$dt.Columns[$i].ColumnName+"</th></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $html +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }
    $html += "</table>"

    $global:Report = $html

}

function Report-ReadOnlyServers
{

    ### Servers - ReadOnly
    ###--------------------------------------------
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $DateDiff = (Get-Date).AddHours(-24)
    Write-Host "Read-Only Servers:"
    $Query = "SELECT * FROM [Servers-ReadOnly] WHERE RecordDateTimeUTC > '$DateDiff'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft

    $html += "<body>"
    $html += "<h5><font color='navy';>Read-Only Servers Provisioned:</font></h5>"
    $html += "<b>Total Read-Only Servers:  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $html +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><th>"+$dt.Columns[$i].ColumnName+"</th></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $html +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $str = $dt.Rows[$i][$j].ToString()
        
            if($str -like "*NotFound*")
            {
                $html += "<td><font color='red';>"+$dt.Rows[$i][$j].ToString() + "</font></td>"
            }
            else
            {
                $html += "<td>"+$dt.Rows[$i][$j].ToString() + "</td>"
            }
        }
        $html +="</tr>"
    }

    $html += "</table>"

    $global:Report = $html
}

function Report-ServerMgmtRequests
{
    ### Server Management Requests
    ###--------------------------------------------
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $DateDiff = (Get-Date).AddHours(-24)
    Write-Host "Server Management Operations:"
    $Query = "SELECT * FROM ServerMgmtRequest WHERE RequestDateTimeUTC > '$DateDiff'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft

    $html += "<body>"
    $html += "<h5><font color='navy';>Server Management Requests:</font></h5>"
    $html += "<b>Total Mgmt Requests:  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $html +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><th>"+$dt.Columns[$i].ColumnName+"</th></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $html +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $str = $dt.Rows[$i][$j].ToString()
        
            if($str -like "*NotFound*")
            {
                $html += "<td><font color='red';>"+$dt.Rows[$i][$j].ToString() + "</font></td>"
            }
            else
            {
                $html += "<td>"+$dt.Rows[$i][$j].ToString() + "</td>"
            }
        }
        $html +="</tr>"
    }

    $html += "</table>"

    $global:Report = $html
}

function Report-ServerMgmtOperations
{

    ### Server Management Operations
    ###--------------------------------------------
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    $DateDiff = (Get-Date).AddHours(-24)
    Write-Host "Server Management Operations:"
    $Query = "SELECT * FROM ServerMgmtOperations WHERE OperationDateTimeUTC > '$DateDiff'"
    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft

    $html += "<body>"
    $html += "<h5><font color='navy';>Server Management Operations:</font></h5>"
    $html += "<b>Total Server Operations:  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $html +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><th>"+$dt.Columns[$i].ColumnName+"</th></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $html +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $str = $dt.Rows[$i][$j].ToString()
        
            if($str -like "*NotFound*")
            {
                $html += "<td><font color='red';>"+$dt.Rows[$i][$j].ToString() + "</font></td>"
            }
            else
            {
                $html += "<td>"+$dt.Rows[$i][$j].ToString() + "</td>"
            }
        }
        $html +="</tr>"
    }

    $html += "</table>"

    $global:Report = $html
}


################################################################################################################################################################
################# OLD CODE - delete?
################################################################################################################################################################

function Get-ECI.EMI.Automation.ServerRequests
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerRequest"
    $Portal_DBConnectionString = "server=10.3.3.75;database=ECIPortal;User ID=portal_servermgmt;Password=lTo3ese4ve!r;"
    $ConnectionString =  $Portal_DBConnectionString
    #$Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $DateDiff = (Get-Date).AddHours(-24)
    #$DateDiff = (Get-Date -f yyyy-MM-dd).AddDays(-1)
    Write-Host "ServerRequests Date Range: $(Get-Date -f yyyy-MM-dd) and $DateDiff "
    #$Query = "SELECT * FROM ServerRequest WHERE RequestDateTime > '$DateDiff'"
    $Query = "SELECT RequestID,RequestDateTime AS RequestDateTimeUTC,RequestServerRole,GPID,CWID,HostName,InstanceLocation,IPv4Address,SubnetMask,DefaultGateway,PrimaryDNS,SecondaryDNS,BackupRecovery,DisasterRecovery,DomainUserName,ClientDomain FROM ServerRequest WHERE RequestDateTime > '$DateDiff'"
    
   

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Subject = "Server Requests on:  $(Get-Date -f MM-dd-yyy)"
    $html = "
        <!DOCTYPE html>
        <html><head>
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
        </head>
    "
    $html += "<body>"
    $html += "<h4>$Subject</h4>"
    $html += "<h5>Server Requested in Last 24 Last Hours: $(Get-Date) UTC to $DateDiff UTC</h5>"
    $html += "<b>Total Servers :  " + ($dt.Rows.Count) + "</b><br><br>"
    
    #$html += "<font size='6';>Test 6</font><br><br>"
    
    $html += "<table border='1'>" 

    $hmtl +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><td>"+$dt.Columns[$i].ColumnName+"</td></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $hmtl +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }

    $html += "</table></body></html>"

    $Message = $html

    ### Send without HTML
    ###--------------
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Get-ECI.EMI.Automation.Servers
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray

    $DataSetName = "ServerRequest"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    #$Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $DateDiff = (Get-Date).AddHours(-24)
    #$DateDiff = (Get-Date -f yyyy-MM-dd).AddDays(-1)
    Write-Host "Date Range: $(Get-Date -f yyyy-MM-dd) and $DateDiff "
    $Query = "SELECT * FROM Servers WHERE RecordDateTimeUTC > '$DateDiff'"
   

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Subject = "New Servers Provisioned on: $(Get-Date -f MM-dd-yyy)"
    $html = "
        <!DOCTYPE html>
        <html><head>
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
        </head>
    "

    $html += "<body>"
    $html += "<h4>$Subject</h4>"
    $html += "<h5>Server Provisioned in Last 24 Last Hours: $(Get-Date) to $DateDiff </h5>"
    $html += "<b>Total Servers :  " + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $hmtl +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><td>"+$dt.Columns[$i].ColumnName+"</td></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $hmtl +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        { 
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }

    $html += "</table></body></html>"
    
    $Message = $html

    ### Send without HTML
    ###--------------
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Get-ECI.EMI.Automation.DesiredState
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    $DataSetName = "ServerRequest"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    #$Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $DateDiff = (Get-Date).AddHours(-24)
    #$DateDiff = (Get-Date -f yyyy-MM-dd).AddDays(-1)
    Write-Host "Date Range: $(Get-Date -f yyyy-MM-dd) and $DateDiff "
    $Query = "SELECT * FROM ServerDesiredState WHERE ServerID = '$ServerID'"
   

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Subject = "$DataSetName  $(Get-Date -f MM-dd-yyy)"
    $html = "
        <!DOCTYPE html>
        <html><head>
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
        </head>
    "

    $html += "<body>"
    $html += "<h4>$Subject</h4>"
    $html += "<h5>Server Requested in Last 24 Last Hours: $(Get-Date) to $DateDiff </h5>"
    $html += "<b>Total Servers :" + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $hmtl +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><td>"+$dt.Columns[$i].ColumnName+"</td></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $hmtl +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }

    $html += "</table></body></html>"
    
    $Message = $html

    ### Send without HTML
    ###--------------
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}

function Get-ECI.EMI.Automation.CurrentState
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    $DataSetName = "ServerRequest"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    #$Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $DateDiff = (Get-Date).AddHours(-24)
    #$DateDiff = (Get-Date -f yyyy-MM-dd).AddDays(-1)
    Write-Host "Date Range: $(Get-Date -f yyyy-MM-dd) and $DateDiff "
    $Query = "SELECT * FROM ServerCurrentState WHERE ServerID = '$ServerID'"
   

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Subject = "$DataSetName  $(Get-Date -f MM-dd-yyy)"
    $html = "
        <!DOCTYPE html>
        <html><head>
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
        </head>
    "

    $html += "<body>"
    $html += "<h4>$Subject</h4>"
    $html += "<h5>Server Requested in Last 24 Last Hours: $(Get-Date) to $DateDiff </h5>"
    $html += "<b>Total Servers :" + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $hmtl +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><td>"+$dt.Columns[$i].ColumnName+"</td></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $hmtl +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }

    $html += "</table></body></html>"
    
    $Message = $html

    ### Send without HTML
    ###--------------
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}


function Get-ECI.EMI.Automation.ConfigLog
{
    $FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `r`n('-' * 75)`r`n "EXECUTING FUNCTION: " $FunctionName `r`n('-' * 75) -ForegroundColor Gray
    
    $DataSetName = "ServerRequest"
    $ConnectionString = "Server=automate1.database.windows.net;Initial Catalog=DevOps;User ID=devops;Password=JKFLKA8899*(*(32faiuynv;"
    #$Query = "SELECT * FROM ServerRequest WHERE RequestID = '$RequestID'"
    $DateDiff = (Get-Date).AddHours(-24)
    #$DateDiff = (Get-Date -f yyyy-MM-dd).AddDays(-1)
    Write-Host "Date Range: $(Get-Date -f yyyy-MM-dd) and $DateDiff "
    $Query = "SELECT * FROM ServerConfigLog WHERE ServerID = '$ServerID'"
   

    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $ConnectionString 
    $Connection.Open() 
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $DataTable = New-Object System.Data.DataTable
    $DataTable.Load($Reader)
    $dt = $DataTable
    $dt | ft
        
    $Subject = "$DataSetName $(Get-Date -f MM-dd-yyy)"
    $html = "
        <!DOCTYPE html>
        <html><head>
        <style>
        #BODY{font-family: Lucida Console, Consolas, Courier New, monospace;font-size:9;font-color: #000000;text-align:left;}
        BODY{font-family: Verdana, Arial, Helvetica, sans-serif;font-size:9;font-color: #000000;text-align:left;}
        TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
        #TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
        TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: #D2B48C}
        TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
        </style>
        </head>
    "

    $html += "<body>"
    $html += "<h4>$Subject</h4>"
    $html += "<h5>Server Requested in Last 24 Last Hours: $(Get-Date) to $DateDiff </h5>"
    $html += "<b>Total Servers :" + ($dt.Rows.Count) + "</b><br><br>"
    $html += "<table border='1'>" 

    $hmtl +="<tr>"
    for($i = 0;$i -lt $dt.Columns.Count;$i++)
    {
        $html += "<b><td>"+$dt.Columns[$i].ColumnName+"</td></b>"  
    }
    $html +="</tr>"

    for($i=0;$i -lt $dt.Rows.Count; $i++)
    {
        $hmtl +="<tr>"
        for($j=0; $j -lt $dt.Columns.Count; $j++)
        {
            $html += "<td>"+$dt.Rows[$i][$j].ToString()+"</td>"
        }
        $html +="</tr>"
    }

    $html += "</table></body></html>"
    
    $Message = $html

    ### Email Constants
    ###---------------------
    $From  = "cbrennan@eci.com"
    #$To    = "cbrennan@eci.com,sdesimone@eci.com,wercolano@eci.com,rgee@eci.com"
    $To    = "cbrennan@eci.com"
    #$CC   = "sdesimone@eci.com"
    $SMTP = "alertmx.eci.com"
    #$SMTP  = $SMTPServer

    ### Email Parameters
    ###---------------------
    $EmailParams = @{
        From       = $From
        To         = $To 
        #CC        = $CC
        SMTPServer = $SMTP
    }

    ### Send without HTML
    ###--------------
    #Send-MailMessage @EmailParams -Body $html -Subject $Subject -BodyAsHtml 
    Send-MailMessage -To ($To -split ",") -From $From -Body $Message -Subject $Subject -BodyAsHtml -SmtpServer $SMTP

    Write-Host `r`n('-' * 50)`r`n "END FUNCTION:" $FunctionName -ForegroundColor DarkGray
}



