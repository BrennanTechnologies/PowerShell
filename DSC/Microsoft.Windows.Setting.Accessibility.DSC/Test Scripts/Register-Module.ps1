
### Add the module path to the PSModulePath environment variable
### 
$path = "C:\Repo\azure-devcenter-customizations-tests\Microsoft.Windows.Setting.Accessibility"
$env:PSModulePath += ";$path"
$env:PSModulePath.Split(";")

#Get-PSRepository
Get-Module -ListAvailable -Name Microsoft.Windows.Setting.Accessibility


$parameters = @{
	Name               = "Microsoft.Windows.Setting.Accessibility"
	SourceLocation     = $path
	PublishLocation    = $path
	InstallationPolicy = 'Trusted'
}
Register-PSRepository @parameters

Get-PSRepository -Name "Microsoft.Windows.Setting.Accessibility" 

Find-Module -Repository "Microsoft.Windows.Setting.Accessibility" 
Get-Module -ListAvailable -Name Microsoft.Windows.Setting.Accessibility | Import-Module

Get-WinGetConfiguration -File "C:\Repo\azure-devcenter-customizations-tests\Microsoft.Windows.Setting.Accessibility\Accessibility.dsc.yaml" | Invoke-WinGetConfiguration -Verbose


Get-DscResource -Name Accessibility