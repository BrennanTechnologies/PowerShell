
===
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/import-module?view=powershell-7


By default, when Import-Module cmdlet is called from the command prompt, script file, or scriptblock, all the commands are imported into the global session state.

When invoked from another module, Import-Module cmdlet imports the commands in a module, including commands from nested modules, into the calling module's session state.
Note:
You should avoid calling Import-Module from within a module. Instead, declare the target module as a nested module in the parent module's manifest. Declaring nested modules improves the discoverability of dependencies.
===

===
-MaximumVersion
Specifies a maximum version. This cmdlet imports only a version of the module that is less than or equal to the specified value. If no version qualifies, Import-Module returns an error.

-MinimumVersion
Specifies a minimum version. This cmdlet imports only a version of the module that is greater than or equal to the specified value. Use the MinimumVersion parameter name or its alias, Version. If no version qualifies, Import-Module generates an error.

To specify an exact version, use the RequiredVersion parameter. You can also use the Module and Version parameters of the #Requires keyword to require a specific version of a module in a script.

This parameter was introduced in Windows PowerShell 3.0.
===

====

Script Property - These are used to calculate property values.
Note Property - These are used for static property names.
Property Sets - These are like aliases that contain just what the name implies; sets of properties. For example, you have created a custom property called Specs for your Get-CompInfo function. Specs is actually a subset of the properties Cpu, Mem, Hdd, IP. The primary purpose of property sets is to provide a single property name to concatenate a group of properties.