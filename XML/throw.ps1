
#trap {
#	"Trapped Caught error"
#}



<##>
cls

for ($i = 0; $i -le 15; $i++) {
	for ($j = 0; $j -le 15; $j++) {
		Write-Host $i -ForegroundColor $i -BackgroundColor $j
	}
}

exit 
try {
	Get-Item "C:\BadPath" -ErrorAction Stop
	Write-Host "Path exists"
}
catch {
	$($Error[0].Exception.Message)
	#Write-Host "Error: " $Error[0].Exception.Message -ForegroundColor Red
	$errMsg = "This is an Error: $($Error[0].Exception.Message)"
	Write-Host "Error: " $_ -ForegroundColor Yellow
	throw #$errMsg
}
Write-Host "After throw" -ForegroundColor Green
#>

RunDll32.exe user32.dll, SetCursorPos 100 100

RunDll32.exe user32.dll, SetCursorPos(0x314159, 0x265358, "100 100", 1)