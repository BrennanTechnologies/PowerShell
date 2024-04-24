$arr = @(1,0,1,1,1,0,1,1)
$arr = @(1,0,1,1,1,1,1,0,1,1,1,0,1,1)

$sum = 0;
$max = 0;

for($i = 0; $i -lt $arr.Length; $i++){
	if($arr[$i] -eq 1){
		$sum++
	}else{
		$sum = 0
	}
	if($sum -gt $max){
		$max = $sum
	}
}
Write-Host "Max: " $max


<#
# is prime
$i = 4
#if( $i / $i -eq 1 -or $i / 1 -eq $i) 
if ($n % $d -eq 0)
{
	Write-Host $i "is prime"
}
else
{
	Write-Host $i "is not prime"
}

#>


