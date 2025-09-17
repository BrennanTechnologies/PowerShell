    <#
    .SYNOPSIS
    Invoke a .NET ADO Database Connection & Runs a SQL Query.
    
    .DESCRIPTION
    Invoke a .NET ADO Database Connection & Runs a SQL Query.
    
    .PARAMETER ServerInstance
    A string that specifies the name of an instance of the Database Engine.
    
    .PARAMETER Database
    Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.
    
    .PARAMETER Query
    Specifies the SQL query that this cmdlet will run. 

    Example 1:  Select  
        $Query = "Select * FROM [dbo].[$Table]"

    Example 2:  Insert  
        $Query = "INSERT INTO [dbo].[$Table] ([FName],[LName]) VALUES ('$FName','$LName')"

    Example 3:  Update  
        $Query = [string]" UPDATE [dbo].[$Table] SET [LName] = '$NewLName' WHERE ID ='$ID' "

    Example 4:  Delete  
        $Query = [string]" DELETE FROM [dbo].[$Table] WHERE ID = '$ID' "
    
    .EXAMPLE
    Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query

    .PARAMETER Quiet
    Suppress console output.

    .OUTPUTS
    ExitCode: Success = $True
    ExitCode: Error = $False
    
    .NOTES
        DataSet Object      – the container for a number of DataTable objects.  This is the object the DataAdapter’s Fill method populates.
        DataTable Object    – allows you to examine data through collections of rows and columns.  The DataSet contains one or more DataTable objects based on the resultset of the Command executed in the DataAdapter Fill method.
        DataRow Object      – provides access to the DataTable’s Rows collection.
        DataColumn Object   – corresponds to a column in your table.
        Constraint Object   – defines and enforces column constraints.
        DataRelation Object – defines the relations between DataTables in the DataSet object.
        DataView Object     – allows you to examine DataTable data in different ways.
#>

function Invoke-ADOcmd {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [string]$ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
        ,
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Database
        ,
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Query
        ,
        [Parameter(Mandatory = $False)]
        [switch]$Quiet
        )
    Begin {    
        ### Create Database Connection String
        ###----------------------------------
        $ConnectionString = "Data Source=$ServerInstance;Initial Catalog=$Database;Integrated Security=true;"
        ### Open DB Connection
        ###----------------------------------
        $Connection = New-Object System.Data.SqlClient.SqlConnection
        $Connection.ConnectionString = $ConnectionString
        $Connection.Open()
        ### SQL Command
        ###----------------------------------
        $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
        $SQLCommand.Connection = $Connection
        $SQLCommand.CommandText = $Query
        # Create Exit Code Object 
        ###----------------------------------
        $Status = New-Object PSObject -Property @{ExitCode = ""}
        # Set Query Type
        ###----------------------------------
        if((($Query.ToUpper()).Trim()).StartsWith("SELECT")){
            $DateReader = $True
        }
        else{
            $DateReader = $False
        }
    }
    Process {
        if($DateReader){
            ### Execute Select SQL Queries
            ###----------------------------------
            try {
                $DataReader = $SQLCommand.ExecuteReader()
                $DataTable = New-Object 'System.Data.DataTable'
                $DataTable.Load($DataReader)
                $Status.ExitCode = $True
            } 
            catch {
                Write-Warning -Message ("ERROR EXECUTING SQL: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message) 
                $Status.ExitCode = $False
                return $Status.ExitCode
            }
            return $DataTable
        }
        else {
            ### Execute All Other SQL Queries
            ###----------------------------------
            try {
                $SQLCommand.ExecuteNonQuery() | Out-Null
                $Status.ExitCode = $True
            } 
            catch {
                Write-Warning -Message ("ERROR EXECUTING SQL: " + $((Get-PSCallStack)[0].Command) + "`n`r" + $global:Error[0].Exception.Message) 
                $Status.ExitCode = $False
            }
            if(-Not $Quiet){
                return $Status.ExitCode
            }
        }
    }
    End {
        ### Close DB Connection
        ###----------------------------------
        $Connection.Close()
    }
}
