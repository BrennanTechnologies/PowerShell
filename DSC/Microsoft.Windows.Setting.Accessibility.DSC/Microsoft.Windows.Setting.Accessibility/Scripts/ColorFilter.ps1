# ### 5 Set: Color Filter Settings
# ### -------------------------------------
# - resource: Microsoft.Windows.Developer/ColorFilterSettings
#   directives:
#     description: Set color filter settings
#     allowPrerelease: true
#   settings:
#     FilterType: "Grayscale" # Set the type of color filter
#     Intensity: 50 # Set the intensity of the color filter
  
<#
Active 0 1
FilterType 
0 = Grayscale
1 = Inverted
2 = Grayscale Inverted
3 = Red-Green (green weak, deuteranopia)
4 = Green-Red (red weak, protanopia)
5 = Blue-Yellow (tritanopia)



#>
enum ColorFilterActive {
	Active = 1
	Inactive = 0
}

enum ColorFilterType {
	Grayscale = 0
	Inverted = 1
	GrayscaleInverted = 2
	RedGreen = 3
	GreenRed = 4
	BlueYellow = 5
}

$registryKey = "HKCU:\Software\Microsoft\ColorFiltering"
if (-not $(Test-Path -Path $registryKey)) {
	New-Item -Path $registryKey -Force
}

if (-not $(Get-ItemProperty -Path $registryKey -Name $valueName -ErrorAction SilentlyContinue)) {
	Set-ItemProperty -Path $registryKey -Name $valueName -Value 1
}
Get-Process -Name explorer | Stop-Process -Force -ErrorAction SilentlyContinue
exit


#$valueName = "ColorFilterState"
$valueName = "Active"
Test-Path -Path $key

Get-ItemProperty -Path $registryKey -Name $valueName | Select-Object -Property Active 
Set-ItemProperty -Path $registryKey -Name $valueName -Value 1


