# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
	Absent
	Present
}

enum TextSizeEnum {
	Small = 96
	Medium = 120
	Large = 144
	ExtraLarge = 192
}
[DSCResource()]
class TextSize {
	[DscProperty(Key)]
	[ValidateSet('Small', 'Medium', 'Large', 'ExtraLarge')]
	[string] $Size

	[TextSize] Get() {
		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"

		### Get Value from Registry
		$sizeValue = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName
		Write-Verbose "Get Size Value: $sizeValue"

		### Get Value from Enum
		$currentSize = [TextSizeEnum]::GetNames([TextSizeEnum]) | Where-Object { [TextSizeEnum]$_ -eq [TextSizeEnum]$sizeValue }	#Write-Host "CurrentSize:" $currentSize.Name
		Write-Verbose "Get Current Size: $currentSize"

		return @{
			#Size = $sizeValue
			Size = $currentSize
		}
	}

	[bool] Test() {
		# $currentSize = $this.Get().Size
		# Write-Verbose "Test Current Size: $currentSize"
		# $result = $currentSize -eq $this.Size
		# Write-Verbose "Test Result: $result"
		# return $result
		return $false
	}

	[void] Set() {
		# make new file in temp directory
		$tempFile = [System.IO.Path]::GetTempFileName()
		Write-Verbose "Temp File: $tempFile"

		$registryKey = "HKCU:\Software\Microsoft\Accessibility"
		$valueName = "TextScaleFactor"

		$sizeValue = [TextSizeEnum]::Parse($this.Size)
		Write-Verbose "Set Size: $this.Size"
		Write-Verbose "Set Size Value: $sizeValue"

		if (!(Test-Path -Path $registryKey)) {
			New-Item -Path $registryKey -Force | Out-Null
		}
		Set-ItemProperty -Path $registryKey -Name $valueName -Value $sizeValue -Force
	}
}
# Get-DscResource -Module Microsoft.Windows.Setting.Accessibility
# Invoke-DscResource -Name TextSize -ModuleName Microsoft.Windows.Setting.Accessibility -Method Set -Property @{HiddenFiles = 'Show' }
#Invoke-DscResource -Name TextSize -ModuleName Microsoft.Windows.Setting.Accessibility -Method Get -Property @{Size = 'Show' }