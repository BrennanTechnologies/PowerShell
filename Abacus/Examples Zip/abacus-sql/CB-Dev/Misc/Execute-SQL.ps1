$ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
$ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=true;"
#$ConnectionString = "Server=$DBServer;Initial Catalog=$Database;Integrated Security=True;"

$Database = "DevOps"
$Table = "VeeamReportServers"
$Query = "Select * FROM [$Table]"

$Connection = New-Object System.Data.SqlClient.SqlConnection
$Connection.ConnectionString = $ConnectionString

$SQLCommand = New-Object System.Data.SqlClient.SqlCommand
$SQLCommand.Connection = $Connection
$SQLCommand.CommandText = $Query
$SQLCommand.CommandTimeout = 0

$Connection.Open()
$SQLCommand.ExecuteNonQuery()

$Connection.Dispose()
$SQLCommand.Dispose()
