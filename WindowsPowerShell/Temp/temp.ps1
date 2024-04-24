cls
#Write a Powershell function which gives the sum of the max consecutive 1s in the following array

$sum = 0

#$arr = @(1,0,1,1,0,1,1,1)
$arr = @(1,0,1,1,0,1,1,1,0,1,1,1,1,1,1,1)
#$arr = @(0,1,0,1,1,0,1,1)

foreach ( $i in $arr ){
	if ($i -eq 1){
		$sum += $i
	}
	else{
		$sum = 0
	}
}
Write-Host "Sum:" 	$sum -ForegroundColor Yellow
