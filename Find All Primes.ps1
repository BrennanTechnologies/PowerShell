
function isEvenorOdd {
	$uBound = 10000

	for ($i = 0; $i -lt $uBound; $i++) {
		if( $i % 2 -eq 0 ) {
			Write-Host "Even :" $i
	
		}else{
			Write-Host "Odd  :" $i
		}
	}
}

	
function isPalondrome {

	$str = "cbrennan"

	#[System.Object]$splitArr = $str.ToCharArray()
	[array]$splitArr = $str.ToCharArray()
	#[array]$splitArr = $str.Split()
	foreach($i in $splitArr){
		Write-Host "i:" $i[$i-$i.Length] -forgroundcolot yellow
		#Write-Host $i[1-$i.Length]
	}

	
	#foreach(){
	#	$revStr = $revStr + $splitArr[$i]
	#}
	# -CharType Word

	Return $splitArr
}

function isPrime {
	$uBound = 100
	#$prime = 1
	$primeIndex = 0

	for ($i = 2; $i -lt $uBound; $i++) {
		#$prime = 1
		for ($j = 2; $j -lt $i; $j++) {
			if( $i % $j -eq 0 ) {
				$prime = 0
				$primeIndex++
				break
			}
		}
		if( $prime -eq 1 ) {
			Write-Host "IsPrime: " $i "PrimeIndex: " $primeIndex
		}
	}
}

& {
	Begin {}
	Process {
		#isPrime
		$splitArr = isPalondrome
		write-host $splitArr 
		$splitArr -is [array]
		$splitArr -is [string]
		$splitArr.Count
	}
	End {}
	
}
