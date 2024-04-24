Function Get-EnumValues
{
 # get-enumValues -enum "System.Diagnostics.Eventing.Reader.StandardEventLevel"
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$Enum
	)
	Begin {}
	Process {
		$enumValues = @{}
		[enum]::getvalues([type]$Enum) |
		ForEach-Object { 
			$enumValues.add($_, $_.value__)
		}
		$enumValues
		}
	End {}
}


