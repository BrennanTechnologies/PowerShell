# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[DscResource()]	
class TextSize {
	[DscProperty(Key)]
	[string] $Size

	[DscProperty(Mandatory)]
	[ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge')]
	[string] $Value

	[DscProperty(Mandatory)]
	[string] $Ensure

	[void] Set() {

		# Define the text size. Common values are:
		# Small  - 96
		# Medium - 120
		# Large  - 144
		# Extra Large - 192

		# enum textSize {
		# 	Small = 96
		# 	Medium = 120
		# 	Large = 144
		# 	ExtraLarge = 192
		# }
		# $textSize = [textSize]::Medium

		# Define the registry key and value name
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"

		# Define the text size values
		$Small = 96
		$Medium = 120
		$Large = 144
		$ExtraLarge = 192
		$textSize = $Medium

		# Define the text size values
		# $textSizes = @{
		# 	'Small'      = 96
		# 	'Medium'     = 120
		# 	'Large'      = 144
		# 	'ExtraLarge' = 192
		# }

		Set-ItemProperty -Path $registryKey -Name $valueName -Value $textSize
		Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

		# Sign out and sign back in for the changes to take effect
		#shutdown.exe /l
	}

	[bool] Test() {
		# Define the registry key and value name
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"

		# Define the text size values
		$textSizes = @{
			'Small'      = 96
			'Medium'     = 120
			'Large'      = 144
			'ExtraLarge' = 192
		}

		# Get the current text size
		$currentTextSize = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

		# Return $true if the current text size matches the desired text size, and $false otherwise
		return $currentTextSize -eq $textSizes[$this.Value]
	}

	[TextSize] Get() {
		# Define the registry key and value name
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"


		# Define the text size values
		$textSizes = @{
			'Small'      = 96
			'Medium'     = 120
			'Large'      = 144
			'ExtraLarge' = 192
		}

		# Get the current text size
		$currentTextSize = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

		# Map the current text size to one of the predefined text size values
		$currentTextSizeName = $textSizes.GetEnumerator() | Where-Object { $_.Value -eq $currentTextSize } | Select-Object -ExpandProperty Name

		# If a matching text size was found, return a new instance of this class with the current text size
		if ($currentTextSizeName) {
			return [TextSize]::new($currentTextSizeName)
		}

		# If no matching text size was found, return a new instance of this class with a default text size
		else {
			return [TextSize]::new('Medium')
		}
	}
}

### TextSize: 
### This class represents the DSC resource for setting the text size.
### --------------------------------------------------------------------------
# [DscResource()]	
# class TextSize {
# 	[DscProperty(Key)]
# 	[string] $Size

# 	[DscProperty(Mandatory)]
# 	[ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge')]
# 	[string] $Value

# 	[DscProperty(Mandatory)]
# 	[string] $Ensure

# 	[void] Set() {
# 		# Add the logic to set the text size here.
# 		# Define the registry key and value name
# 		$registryKey = "HKCU:\Control Panel\Desktop"
# 		$valueName = "LogPixels"

# 		# Define the text size. Common values are:
# 		# Small  - 96
# 		# Medium - 120
# 		# Large  - 144
# 		# Extra Large - 192
# 		$textSize = 120

# 		# Set the text size
# 		Set-ItemProperty -Path $registryKey -Name $valueName -Value $textSize

# 		# Sign out and sign back in for the changes to take effect
# 		shutdown.exe /l
# 	}

# 	[bool] Test() {
# 		# Define the registry key and value name
# 		$registryKey = "HKCU:\Control Panel\Desktop"
# 		$valueName = "LogPixels"

# 		# Define the text size values
# 		$textSizes = @{
# 			'Small'      = 96
# 			'Medium'     = 120
# 			'Large'      = 144
# 			'ExtraLarge' = 192
# 		}

# 		# Get the current text size
# 		$currentTextSize = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

# 		# Return $true if the current text size matches the desired text size, and $false otherwise
# 		return $currentTextSize -eq $textSizes[$this.Value]
# 	}

# 	[TextSize] Get() {
# 		# Define the registry key and value name
# 		$registryKey = "HKCU:\Control Panel\Desktop"
# 		$valueName = "LogPixels"

# 		# Define the text size values
# 		$textSizes = @{
# 			'Small'      = 96
# 			'Medium'     = 120
# 			'Large'      = 144
# 			'ExtraLarge' = 192
# 		}

# 		# Get the current text size
# 		$currentTextSize = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

# 		# Map the current text size to one of the predefined text size values
# 		$currentTextSizeName = $textSizes.GetEnumerator() | Where-Object { $_.Value -eq $currentTextSize } | Select-Object -ExpandProperty Name

# 		# If a matching text size was found, return a new instance of this class with the current text size
# 		if ($currentTextSizeName) {
# 			return [TextSize]::new($currentTextSizeName)
# 		}

# 		# If no matching text size was found, return a new instance of this class with a default text size
# 		else {
# 			return [TextSize]::new('Medium')
# 		}
# 	}
# }

### MousePointerSize: 
### This class represents the DSC resource for setting the mouse pointer size.
### --------------------------------------------------------------------------
# [DscResource()]
# class MousePointerSize {
# 	[DscProperty(Key)]
# 	[string] $Size

# 	[DscProperty(Mandatory)]
# 	[ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge')]
# 	[string] $Value

# 	[MousePointerSize] Get() {
# 		$currentSize = # Add the logic to get the current mouse pointer size here.

# 		return @{
# 			Size  = $this.Size
# 			Value = $currentSize
# 		}
# 	}

# 	[bool] Test() {
# 		$currentSize = # Add the logic to get the current mouse pointer size here.

# 		return $currentSize -eq $this.Value
# 	}

# 	[void] Set() {
# 		# Add the logic to set the mouse pointer size here.
# 	}
# }