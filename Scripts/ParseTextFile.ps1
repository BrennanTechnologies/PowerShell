cls
#$rsop = GPRESULT /R
#$rsop | Out-File -FilePath .\temp.txt
$rsop = Get-Content -Path .\temp.txt

$startStr = "Applied Group Policy Objects"
$startStr = "USER SETTINGS"
$start = ($rsop | Select-String -Pattern $startStr | Select-Object LineNumber).LineNumber
#$rsop | Select-Object -Skip $start -Last $start+3
Write-Host "Start: " $start -ForegroundColor Magenta

$endStr = "The following GPOs were not applied because they were filtered out"
$endStr = "Applied Group Policy Objects"
$end = ($rsop | Select-String -Pattern $endStr | Select-Object LineNumber).LineNumber
$end 


$text = $rsop | Select-Object -Index ( $($start + 1)..$($end - 2)) 
$text


### Select Carriage Return
$rsop = Get-Content -Path .\temp.txt
$rsop |  Select-String -Pattern $([char]32) | Select-Object LineNumber
Write-Host $([char]34) -ForegroundColor Magenta

$rsop |  Select-String -Pattern $([char]'`n') | Select-Object LineNumber


$CR = [char]13
$LF = [char]10
$CRLF = $CR + $LF
Write-Host $CR-ForegroundColor Magenta
Write-Host $LF -ForegroundColor Magenta
Write-Host $CRLF -ForegroundColor Magenta

($rsop | Select-String -Pattern $CRLF ).Count
($rsop | Select-String -Pattern $CR ).Count
($rsop | Select-String -Pattern $LF ).Count
($rsop | Select-String -Pattern " " ).Count

($rsop | Select-String -Pattern $CRLF | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern $CR | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern $LF | Select-Object LineNumber).LineNumber

Get-Content -Path ".\temp.txt" | Select-String -Pattern `r`n | Select-Object LineNumber

($rsop | Select-String -Pattern "`r`n" | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern `n | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern `r | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern `0 | Select-Object LineNumber).LineNumber
($rsop | Select-String -Pattern `t | Select-Object LineNumber).LineNumber
#($rsop | Select-String -Pattern 'The' | Select-Object LineNumber).LineNumber

$txt = Get-Content -Path ".\temp.txt" 
$i = 0
foreach ($line in $txt) {
	$i++
	Write-Host $i ":" $line.Length 
} 