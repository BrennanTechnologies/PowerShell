# Invoke-ADOcmd #

### Description ###
Invoke a .NET ADO Database Connection & Executes a SQL Query.

### Requirements ###
Requires the Abacus-SQL module.



```powershell
Import-Abacus-SQL
or
RequiredModules = @('Abacus-SQL')
```

### Syntax ###
```powershell
Invoke-ADOcmd
    [-ServerInstance <String>]
    -Database <String>
    -Query <String>
    [-Quiet <Switch>]
```
 [ ] = Optional Parameter
 
#### Example 1 ####
- Required parameters are -Database and -Query.
- Users the default: $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433" 


```powershell
Invoke-ADOcmd -Database $Database -Query $Query
```


#### Example 2 ####

 - Optionally specify a different database server and instance.

```powershell
Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query
```
#### Example 3 ####

- Use the -Quiet switch to suppress output.

```powershell
Invoke-ADOcmd -ServerInstance $ServerInstance -Database $Database -Query $Query -Quiet
```

### Parameters ###

##### -ServerInstance

A string that specifies the name of an instance of the Database Engine.

Example:  
` $ServerInstance = "nymgmtdodb01.management.corp\MSSQLSERVER,1433" `

  
##### -Database 

Specifies the name of a database. This cmdlet connects to this database in the instance that is specified in the ServerInstance parameter.

Example:  
` $Database = "DevOps" `
   
   
##### -Query

Specifies the SQL query that this cmdlet will run. 

Example 1:  Select  
    ```$Query = "Select * FROM [dbo].[$Table]" ```

Example 2:  Insert  
    ```$Query = "INSERT INTO [dbo].[$Table] ([FName],[LName]) VALUES ('$FName','$LName')" ```

Example 3:  Update  
    ```$Query = [string]" UPDATE [dbo].[$Table] SET [LName] = '$NewLName' WHERE ID ='$ID' " ```

Example 4:  Delete  
   ```$Query = [string]" DELETE FROM [dbo].[$Table] WHERE ID = '$ID' " ```  

##### -Quiet
Suppress console output.


### Author ###
Author: Chris Brennan

Date: 4-4-2020

### Support ###
**Known Bugs**

None

**Report Bugs**

bugs.devops@abacusgroupllc.com
