enum TextSizeEnum {
	Small = 96
	Medium = 120
	Large = 144
	ExtraLarge = 192
}

function Get-TextSize {
	$registryKey = "HKCU:\Software\Microsoft\Accessibility"
	$valueName = "TextScaleFactor"

	$sizeValue = Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName

	# Get Value from Enum
	$currentSize = [TextSizeEnum]::GetNames([TextSizeEnum]) | Where-Object { [TextSizeEnum]$_ -eq [TextSizeEnum]$sizeValue }	#Write-Host "CurrentSize:" $currentSize.Name

	return @{
		Size = $currentSize
	}
}


# function Set-TextSize {
# 	$registryKey = "HKCU:\Software\Microsoft\Accessibility"
# 	$valueName = "TextScaleFactor"
# 	#$sizeValue = [int][TextSizeEnum]::Parse([TextSizeEnum], $this.Size)
# 	[int]$sizeValue = 144
# 	if (!(Test-Path -Path $registryKey)) {
# 		New-Item -Path $registryKey -Force | Out-Null
# 	}
# 	Set-ItemProperty -Path $registryKey -Name $valueName -Value $sizeValue
# }

# & {
# 	#Get-TextSize

# 	[int][TextSizeEnum]::Parse([TextSizeEnum], "Large")

# 	#Get-TextSize
# 	#Set-TextSize
# 	#Get-TextSize
# }

$Size = "extralarge"
$Size = "small"
if ($Size -like "ExtraLarge".ToUpper()) {
	$Size = "ExtraLarge"
}
else {
	$Size = $Size.Replace($Size[0], $Size[0].ToString().ToUpper())
}
Write-Host $Size