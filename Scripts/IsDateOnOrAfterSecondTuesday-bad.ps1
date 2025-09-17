function IsDateOnOrAfterSecondTuesday1 {
	param (
		[Parameter(Mandatory = $true)]
		[DateTime]
		$InputDate
	)

	$secondTuesday = (Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day 1).AddDays((2 - [int](Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day 1).DayOfWeek + 7) % 7 + 7)

	return $InputDate -ge $secondTuesday
}
# IsDateOnOrAfterSecondTuesday1 -InputDate (Get-Date -Year 2021 -Month 1 -Day 1) # False
# IsDateOnOrAfterSecondTuesday1 -InputDate (Get-Date -Year 2021 -Month 1 -Day 5) # False
# IsDateOnOrAfterSecondTuesday1 -InputDate (Get-Date -Year 2021 -Month 1 -Day 12) # True
# IsDateOnOrAfterSecondTuesday1 -InputDate (Get-Date -Year 2021 -Month 1 -Day 19) # True
# IsDateOnOrAfterSecondTuesday1 -InputDate (Get-Date -Year 2021 -Month 1 -Day 12) # False

function IsDateOnOrAfterSecondTuesday2 {
	param (
		[Parameter(Mandatory = $true)]
		[DateTime]
		$InputDate
	)

	### Get the first day of the month
	$firstDayOfMonth = Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day 1
	
	### Get the day of the week for the first day of the month
	$dayOfWeek = [int]$firstDayOfMonth.DayOfWeek
	
	### Calculate the number of days until the next Tuesday
	$daysUntilNextTuesday = (2 - $dayOfWeek + 7) % 7
	
	### Get the first Tuesday of the month
	$firstTuesday = $firstDayOfMonth.AddDays($daysUntilNextTuesday)
	
	### Get the second Tuesday of the month
	$secondTuesday = $firstTuesday.AddDays(7)

	return $InputDate -ge $secondTuesday
}
#IsDateOnOrAfterSecondTuesday2 -InputDate 4/27/2021

# IsDateOnOrAfterSecondTuesday2 -InputDate (Get-Date -Year 2021 -Month 1 -Day 1) # False
# IsDateOnOrAfterSecondTuesday2 -InputDate (Get-Date -Year 2021 -Month 1 -Day 5) # False
# IsDateOnOrAfterSecondTuesday2 -InputDate (Get-Date -Year 2021 -Month 1 -Day 12) # True
# IsDateOnOrAfterSecondTuesday2 -InputDate (Get-Date -Year 2021 -Month 1 -Day 19) # True
# IsDateOnOrAfterSecondTuesday2 -InputDate (Get-Date -Year 2021 -Month 1 -Day 12) # False

function IsDateOnOrAfterSecondTuesday3 {
	param (
		[Parameter(Mandatory = $true)]
		[DateTime]$InputDate
	)

	# 	# Remove time component from InputDate
	# 	#$InputDate = Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day $InputDate.Day
	# 	$InputDate = Get-Date $InputDate

	# 	# Get the first day of the month
	# 	$firstDayOfMonth = Get-Date -Year $InputDate.Year -Month $InputDate.Month -Day 1

	# 	# Get the INTEGER day of the week for the first day of the month
	# 	$dayOfWeek = [int]$firstDayOfMonth.DayOfWeek

	# 	# Calculate the number of days until the next Tuesday
	# 	$daysUntilNextTuesday = (2 - $dayOfWeek + 7) % 7

	# 	# Get the first Tuesday of the month
	# 	$firstTuesday = $firstDayOfMonth.AddDays($daysUntilNextTuesday)

	# 	# Get the second Tuesday of the month
	# 	$secondTuesday = $firstTuesday.AddDays(7)

	# 	# Remove time component from secondTuesday
	# 	$secondTuesday = Get-Date -Year $secondTuesday.Year -Month $secondTuesday.Month -Day $secondTuesday.Day

	# 	return $InputDate -ge $secondTuesday
	# }

	IsDateOnOrAfterSecondTuesday3 -InputDate "04/26/2024"