
function Greeting {
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$Start
	)
	$1grettinVar = "Greetings"
	sayHi
	
}

function sayHi {
	$1sayHiVar = "Hi"
	return "Hi!"
}

$Start = "Start"
 Greeting -Start $Start


