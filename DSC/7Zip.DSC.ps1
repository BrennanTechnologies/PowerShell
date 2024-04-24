
# Desired State Configuration for 7-Zip

#Find-Module -Name PackageManagement -Repository PSGallery | Install-Module -Force
#Get-Module -Name PackageManagement -ListAvailable | where { $_.Version -eq "1.0.0.1" } #| Uninstall-Module -Force
#Find-Module -Name PSDesiredStateConfiguration -Repository PSGallery | Install-Module -Force

Configuration ZipDSC {
	# Import the required DSC Resources
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	#Import-DscResource -ModuleName PackageManagement -ModuleVersion  '1.4.8.1'

	# Define the nodes to apply the configuration to
	Node localhost {
		# Install the PackageManagement module from the PowerShell Gallery
		<#
		PackageManagementSource PSGallery {
			Ensure             = "Present"
			Name               = "PSGallery"
			ProviderName       = "PowerShellGet"
			SourceLocation     = "https://www.powershellgallery.com/api/v2"
			InstallationPolicy = "Trusted"
		}
		#>
		# Install the 7-Zip package from the Chocolatey repository
		PackageManagement 7Zip {
			Ensure       = "Present"
			Name         = "7zip"
			ProviderName = "Chocolatey"
			Source       = "https://chocolatey.org/api/v2/"
			#DependsOn    = "[PackageManagementSource]PSGallery"
		}
	}
}
# Apply the configuration
ZipDSC -OutputPath .\Mofs
Start-DscConfiguration -Path .\Mofs -Wait -Verbose -Force


<#
This DSC will install the 7-Zip package from the Chocolatey repository using the PackageManagement module. For more information about 7-Zip, you can visit the following links:

- [7-Zip](https://www.7-zip.org/)
- [7-Zip - Chocolatey Software](https://community.chocolatey.org/packages/7zip)
- [7-Zip Command-Line Examples](https://sevenzip.osdn.jp/chm/cmdline/index.htm)

#>