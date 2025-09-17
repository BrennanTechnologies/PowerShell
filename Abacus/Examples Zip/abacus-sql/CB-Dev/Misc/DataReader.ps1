config
$svr = "serverName"
$db = "databaseName"

# connection
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection
$sqlConnection.ConnectionString = "Server=$svr;Database=$db;Integrated Security=True"
$sqlConnection.Open()

# command A - text
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sqlConnection
$sqlCmd.CommandText = "SELECT name AS TABLE_NAME FROM sys.tables"

# command B - stored procedure
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand
$sqlCmd.Connection = $sqlConnection
$sqlCmd.CommandText = "sys.sp_tables"
$sqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
$sqlCmd.Parameters.Add("@table_owner", "dbo")

# execute A - data reader
$reader = $sqlCmd.ExecuteReader()
$tables = @()
while ($reader.Read()) {
    $tables += $reader["TABLE_NAME"]
}
$reader.Close()

# execute B - data adapter
$dataTable = New-Object System.Data.DataTable
$sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$sqlAdapter.SelectCommand = $sqlCmd
$sqlAdapter.Fill($dataTable)
$sqlConnection.Close()