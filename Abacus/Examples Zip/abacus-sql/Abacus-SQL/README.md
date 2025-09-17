# Abacus-SQL #

### Overview ###
This module provides functionality for integrating database connectivity with PowerShell.

### Requirements ###
Requires the Abacus-SQL module.

```powershell
Import-Abacus-SQL
or
RequiredModules = @('Abacus-SQL')
```

### Commands ###

##### Invoke-ADOcmd ####

Invoke a .NET ADO Database Connection & Runs a SQL Query.

### SQL Query Examples ###
Example 1:  Select  
    ```$Query = "Select * FROM [dbo].[$Table]" ```

Example 2:  Insert  
    ```$Query = "INSERT INTO [dbo].[$Table] ([FName],[LName]) VALUES ('$FName','$LName')" ```

Example 3:  Update  
    ```$Query = [string]" UPDATE [dbo].[$Table] SET [LName] = '$NewLName' WHERE ID ='$ID' " ```

Example 4:  Delete  
   ```$Query = [string]" DELETE FROM [dbo].[$Table] WHERE ID = '$ID' " ```  



### Support for Module ###

Author: cbrennan

Contact: devops.all@abacusgroupllc.com
