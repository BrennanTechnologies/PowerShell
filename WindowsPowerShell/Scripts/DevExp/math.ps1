cls
Write-Host "[System.Math]:" -ForegroundColor Yellow
[System.Math] | Get-Member -Static -MemberType All
Write-Host "[Math]:" -ForegroundColor Yellow
[Math] | Get-Member -Static -MemberType All


[Math]::Abs(-5)

#[Math]::Exp(2)
[Math]::Sqrt(2)