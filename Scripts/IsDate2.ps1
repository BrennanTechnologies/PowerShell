function IsDateOnOrAfterSecondTuesday {
	param (
		[Parameter(Mandatory = $true)]
		[DateTime]
		$InputDate
	)

	# Remove time component from InputDate
	$date = Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day $InputDate.Day

	# Get the day of the week for the given date
	$dayOfWeek = $date.DayOfWeek
	Write-Host "Day of the week: " $dayOfWeek
	Write-Host "Day: " $date.Day

	# Check if it's Tuesday and if it's after the 8th day of the month (second Tuesday)
	if ($dayOfWeek -eq 'Tuesday' -and $date.Day -ge 8) {
		return $true
	}
	else {
		return $false
	}
}

# Example usage:
#$dateToCheck = Get-Date '2024-04-9'  # Replace with your desired date
#$result = 
IsDateOnOrAfterSecondTuesday 4/19/2024
#Write-Host "Is $dateToCheck on or after the second Tuesday? $result"