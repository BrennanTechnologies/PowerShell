# Invoke-ADODataUpdate #

### Description ###
Invoke a .NET ADO Database Connection & Runs a SQL Query to Update a record.

### Requirements ###
Requires the Abacus-SQL module.

```powershell
Import-Abacus-SQL
or
RequiredModules = @('Abacus-SQL')
```

### Syntax ###
```powershell
Invoke-ADODataUpdate
    [-ServerInstance <String>]
    [-Database <String>]
    [-Query <String>]
```

### Example ###
```powershell
Invoke-ADODataUpdate -ServerInstance $ServerInstance -Database $Database -Query $Query
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
$Query = [string]" UPDATE [dbo].[$Table] SET [LName] = '$NewLName' WHERE ID ='$ID' "


### Author ###
Author: Chris Brennan

Date: 4-4-2020

### Support ###
**Known Bugs**

None

**Report Bugs**

bugs.devops@abacusgroupllc.com
