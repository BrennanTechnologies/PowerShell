# Invoke-ADODataDelete #

### Description ###
Invoke a .NET ADO Database Connection & Runs a SQL Query to Delete a record.

### Requirements ###
Requires the Abacus-SQL module.

```powershell
Import-Abacus-SQL
or
RequiredModules = @('Abacus-SQL')
```

### Syntax ###
```powershell
Invoke-ADODataDelete
    [-ServerInstance <String>]
    [-Database <String>]
    [-Query <String>]
```

### Example ###
```powershell
Invoke-ADODataDelete -ServerInstance $ServerInstance -Database $Database -Query $Query
```

### Parameters ###

`-ServerInstance`

A string that specifies the name of an instance of the Database Engine.

Example:  
$ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433"
  
  
`-Database`  

Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

Example:  
$Database = "DevOps"
   
   
`-Query`

Specifies the SQL query that this cmdlet will run. 

Example:  
$Query = [string]" DELETE FROM [dbo].[$Table] WHERE ID = '$ID' "


### Author ###
Author: Chris Brennan

Date: 4-4-2020

### Support ###
**Known Bugs**

None

**Report Bugs**

bugs.devops@abacusgroupllc.com
