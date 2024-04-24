  
# Write a function which gives the sum of the max consecutive 1s in the following array
#$arr = (1,0,1,1,0,1,1,1)

$arr = (1,0,1,1,1,1,0,0,1,1)

`




$arr = (1,0,1,1,0,1,1,1)
$arr = (1,0,1,1,1,1,1,1,1,0,1,1,0,1,1,1)
#$arr = (1,0,1,1,1,1,0,0,1,1)

function Get-Sum (){
	[CmdletBinding()]
	param (
		[Parameter()]
		[array]
		$arr
	)

	$sum = 0
	$max = 0
	for($i = 0;$i -lt $arr.Length;$i++){
		if($arr[$i] -eq 1){
			$sum++
		}else{
			$sum = 0
		}
		if($sum -gt $max){
			$max = $sum
		}
	}
	Return $max
} 

$max = Get-Sum -arr $arr
Write-Host $max -ForegroundColor Magenta

#>