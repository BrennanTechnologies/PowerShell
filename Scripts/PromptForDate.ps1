# Prompt the user for a date until a valid format is entered
do {
	$date = $null
	$today = Read-Host -Prompt ('Enter the Date. Format MM/dd/yyyy (e.g. {0}) ' -f (Get-Date -Format "MM/dd/yyyy"))

	try {
		$date = Get-Date -Date $today -Format "MM/dd/yyyy" -ErrorAction Stop
		'{0} is a valid date' -f $date
	}
	catch {
		'{0} is an invalid date' -f $today
	}
}
until ($date)

exit

# Prompt the user for a date until a valid format is entered
do {
	$inputDate = Read-Host "Enter a date (MM-DD-YYYY):"
	try {
		$inputDate = [DateTime]::Parse($inputDate)
		$IsValidDate = $true
	}
	catch {
		Write-Host "Invalid date format. Please enter a date in the format MM-DD-YYYY." -ForegroundColor Red
		$IsValidDate = $false
	}
} until ($IsValidDate)

Write-Host "Valid date entered: $inputDate" -ForegroundColor Green


# do {
# 	$InputDate = Read-Host -Prompt 'Enter a date' -ErrorAction SilentlyContinue
# 	try {
# 		$InputDate = [DateTime]::Parse($InputDate)
# 		$InputDate
# 		$valid = $true
# 		Write-Host "You entered: $InputDate" -ForegroundColor Green
# 	}
# 	catch {
# 		Write-Host 'Invalid date format. Please enter a valid date in the format MM/DD/YYYY.'
# 		$valid = $false
# 	}

# 	# if ($valid) {
# 	# 	IsDateOnOrAfterSecondTuesday -InputDate $InputDate
# 	# }
# } until ($valid)