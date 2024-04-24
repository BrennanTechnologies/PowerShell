$Logfile = "C:\PS\Logs\proc_$env:computername.log"
function Write-Log
{
	[CmdletBinding()]
	param (
		[Parameter()]
		[DateTime]
		$TimeStamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
		,
		[Parameter()]
		[String]
		$Message
		,
		[Parameter()]
		[String]
		$Logfile = $Logfile
		,
		[Parameter()]
		[String]
		$LogLevel = "Info"
		,
		[Parameter()]
		[String]
		$LogType = "Console"
		,
		[Parameter()]
		[String]
		$LogCategory = "General"

	)
	Begin {
		### Enums
		###----------------
		Enum Category
		{
			INFO    = 0
			WARN    = 1
			ERROR   = 2
		}

		### Get Console Colors
		###-------------------
		$colors = [enum]::GetValues([System.ConsoleColor])
	}
	Process {
		$LogMessage = "$Stamp $LogString"
		Add-content $LogFile -value $LogMessage

	}	

	End {}

}