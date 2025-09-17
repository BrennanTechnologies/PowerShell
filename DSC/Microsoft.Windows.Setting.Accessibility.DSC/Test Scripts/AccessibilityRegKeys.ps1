
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


$Small = 96
$Medium = 120
$Large = 144
$ExtraLarge = 192


$textSize = $Medium

$registryKey = "HKCU:\Software\Microsoft\Accessibility"
$valueName = "TextScaleFactor"
Set-ItemProperty -Path $registryKey -Name $valueName -Value $textSize
Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -ExpandProperty $valueName