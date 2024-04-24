cls
# DeMorgans Law.ps1
# !(a || b) == (!a && !b)

$a = $true
$b = $true
Write-Host "Set 1: $a / $b" -ForegroundColor Yellow

$result = !($a -or $b) -eq (!$a -and !$b)		# not (A or B) = (not A) and (not B)
Write-Host "Result1:"  $result
$result = !($a -and $b) -eq (!$a -or !$b)		# not (A and B) = (not A) or (not B)
Write-Host "Result1:"  $result

$a = $false
$b = $false
Write-Host "Set 2: $a / $b" -ForegroundColor Yellow

$result = !($a -or $b) -eq (!$a -and !$b)		# not (A or B) = (not A) and (not B)
Write-Host "Result1:"  $result
$result = !($a -and $b) -eq (!$a -or !$b)		# not (A and B) = (not A) or (not B)
Write-Host "Result1:"  $result

$a = $true
$b = $false
Write-Host "Set 3: $a / $b" -ForegroundColor Yellow

$result = !($a -or $b) -eq (!$a -and !$b)		# not (A or B) = (not A) and (not B)
Write-Host "Result2:"  $result
$result = !($a -and $b) -eq (!$a -or !$b)		# not (A and B) = (not A) or (not B)
Write-Host "Result3:"  $result

$a = $false
$b = $true
Write-Host "Set 4: $a / $b" -ForegroundColor Yellow

$result = !($a -or $b) -eq (!$a -and !$b)		# not (A or B) = (not A) and (not B)
Write-Host "Result3:"  $result
$result = !($a -and $b) -eq (!$a -or !$b)		# not (A and B) = (not A) or (not B)
Write-Host "Result3:"  $result
