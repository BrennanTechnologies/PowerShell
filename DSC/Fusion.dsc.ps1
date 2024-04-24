# Desired State Configuration for Freedom Scientific Fusion
Configuration FusionDSC
{
	# Import the required DSC Resources
	Import-DscResource -ModuleName PSDesiredStateConfiguration
	Import-DscResource -ModuleName PackageManagement

	# Define the nodes to apply the configuration to
	Node localhost
	{
		# Install the PackageManagement module from the PowerShell Gallery
		PackageManagementSource PSGallery
		{
			Ensure             = "Present"
			Name               = "PSGallery"
			ProviderName       = "PowerShellGet"
			SourceLocation     = "https://www.powershellgallery.com/api/v2"
			InstallationPolicy = "Trusted"
		}

		# Install the Fusion package from the Freedom Scientific website
		PackageManagement Fusion
		{
			Ensure    = "Present"
			Name      = "Fusion"
			ProviderName= "msi"
			Source    = "https://support.freedomscientific.com/Downloads/Fusion/FusionInstaller"
			DependsOn = "[PackageManagementSource]PSGallery"
		}

		# Set the Fusion preferences
		Registry FusionPreferences {
			Ensure    = "Present"
			Key       = "HKCU:\Software\Freedom Scientific\Fusion\Preferences"
			ValueName = "Start Fusion Automatically when Windows starts"
			ValueData = "1"
			ValueType = "DWord"
			DependsOn = "[PackageManagement]Fusion"
		}
	}
}

# Apply the configuration
FusionDSC
Start-DscConfiguration -Path .\FusionDSC -Wait -Verbose -Force

<#
This DSC will install the Fusion package from the Freedom Scientific website and set the preference to start Fusion automatically when Windows starts. For more information about Fusion, you can visit the following links:

- [Getting Started with Fusion – Freedom Scientific](^1^)
- [Freedom Scientific Training - YouTube](^2^)
- [Fusion System Recommendations - Freedom Scientific](^3^)

I hope this helps you with your desired state configuration for Freedom Scientific Fusion. If you have any other questions, feel free to ask me.

Source: Conversation with Bing, 1/5/2024
(1) Getting Started with Fusion – Freedom Scientific. https://www.freedomscientific.com/training/fusion/getting-started/.
(2) Freedom Scientific Training - YouTube. https://www.youtube.com/freedomscientifictraining.
(3) Fusion System Recommendations - Freedom Scientific. https://support.freedomscientific.com/Downloads/Fusion/Fusion-System-Requirements.
(4) undefined. https://support.freedomscientific.com.
#>