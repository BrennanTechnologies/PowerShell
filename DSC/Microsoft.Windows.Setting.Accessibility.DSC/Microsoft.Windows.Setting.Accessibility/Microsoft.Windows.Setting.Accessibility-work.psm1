# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

#$ErrorActionPreference = "Stop"
#Set-StrictMode -Version Latest

enum Ensure {
	Absent
	Present
}

enum TextSizeEnum {
	Small = 96
	Medium = 120
	Large = 144
	ExtraLarge = 192
	Other
}

[DSCResource()]	
class TextSize {
	[DscProperty(Key)]
	[ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge', 'Other')]
	[string] $Size

	[TextSize] Get() {
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"

		if (Test-Path -Path $registryKey) {
			$sizeValue = Get-ItemProperty -Path $registryKey -Name $valueName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $valueName

			# Map the TextScaleFactor registry value to a valid Size value
			$sizeName = [TextSizeEnum]::GetName([TextSizeEnum], $sizeValue)

			if ($null -eq $sizeName) {
				#throw "Invalid TextScaleFactor value: $sizeValue"
				$sizeName = 'Other'
			}

			$this.Size = $sizeName
		}

		return @{
			Size = $this.Size
		}
	}

	[bool] Test() {
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"
		$currentSizeValue = Get-ItemProperty -Path $registryKey -Name $valueName -ErrorAction SilentlyContinue `
		| Select-Object -ExpandProperty $valueName

		if (Test-Path -Path $registryKey) {
			try {
				$currentSizeValue = Get-ItemProperty -Path $registryKey -Name $valueName -ErrorAction SilentlyContinue `
				| Select-Object -EpandProperty $valueName
				#$currentSizeValue = $this.Get()
			}
			catch	{
				return $false
			}

			# Map the TextScaleFactor registry value to a valid Size value
			$currentSize = [TextSizeEnum]::GetName([TextSizeEnum], $currentSizeValue)
			return $currentSize -eq $this.Size
		}
		else {
			return $false
		}
	}

	[void] Set() {
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"
		try {

			# Map the Size property to a valid TextScaleFactor value
			$sizeValue = [int][TextSizeEnum]::Parse([TextSizeEnum], $this.Size)

			if (! (Test-Path -Path $registryKey)) {
				New-Item -Path $registryKey -Force
			}
			Set-ItemProperty -Path $registryKey -Name $valueName -Value $sizeValue
		}
		catch {
			throw $_.Exception.Message
		}
	}
}

### Examples:
# Get-DscResource -Module Microsoft.Windows.Setting.Accessibility
# Invoke-DscResource -Name TextSize -ModuleName Microsoft.Windows.Setting.Accessibility -Method Get -Property @{Size = 'Medium' }
# Invoke-DscResource -Name TextSize -ModuleName Microsoft.Windows.Setting.Accessibility -Method Test -Property @{Size = 'Small' }
# Invoke-DscResource -Name TextSize -ModuleName Microsoft.Windows.Setting.Accessibility -Method Set -Property @{Size = "Small" }


#Get-ChildItem -File  | Unblock-File