function IsDateOnOrAfterSecondTuesday {
	param (
		[Parameter(Mandatory = $false)]
		[string]$InputDate
	)

	if (-not $InputDate) {
		# Prompt the user for a date until a valid format is entered
		do {
			$InputDate = Read-Host -Prompt ('Enter the Date. Format MM/dd/yyyy (e.g. {0}) ' -f (Get-Date -Format "MM/dd/yyyy"))
			try {
				$InputDate = Get-Date -Date $InputDate -Format "MM/dd/yyyy" -ErrorAction Stop
				Write-Host "$InputDate is a Valid date" -ForegroundColor Green
			}
			catch {
				Write-Host "$InputDate is a In-Valid date" -ForegroundColor Red
			}
		}
		until ($InputDate -is [DateTime])
	}
	# else {
	# 	try {
	# 		$InputDate = Get-Date -Date $InputDate -Format "MM/dd/yyyy" -ErrorAction Stop
	# 	}
	# 	catch {
	# 		Write-Host '{0} is an invalid date' -f $InputDate -ForegroundColor Red
	# 		return
	# 	}
	# }
	exit
	# Remove time component from InputDate
	$InputDate = [DateTime]::new($InputDate.Year, $InputDate.Month, $InputDate.Day)

	# Get the first day of the month
	$firstDayOfMonth = Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day 1

	# Get the INTEGER day of the week for the first day of the month
	$dayOfWeek = [int]$firstDayOfMonth.DayOfWeek

	# Calculate the number of days until the next Tuesday
	$daysUntilNextTuesday = (2 - $dayOfWeek + 7) % 7

	# Get the first Tuesday of the month
	$firstTuesday = $firstDayOfMonth.AddDays($daysUntilNextTuesday)

	# Get the second Tuesday of the month
	$secondTuesday = $firstTuesday.AddDays(7)

	# Remove time component from secondTuesday
	#$secondTuesday = [DateTime]::new($secondTuesday.Year, $secondTuesday.Month, $secondTuesday.Day)

	return [bool]$($InputDate -ge $secondTuesday)
}

IsDateOnOrAfterSecondTuesday
exit
# Test Cases
& {
	@('4/1/2024', '4/8/2024', '4/9/2024', '4/10/2024') | ForEach-Object {
		$InputDate = $_
		$Result = IsDateOnOrAfterSecondTuesday -InputDate $InputDate
		Write-Host "Is $InputDate on or after the second Tuesday? $Result"
	}
}