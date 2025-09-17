$env:PSModulePath = "C:\Repo\azure-devcenter-customizations-tests\Microsoft.Windows.Setting.Accessibility\Microsoft.Windows.Setting.Accessibility;" + $env:PSModulePath
$env:PSModulePath.Split(";")
Get-DscResource -Module Microsoft.Windows.Setting.Accessibility