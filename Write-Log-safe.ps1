### Write-Log.ps1
function Write-Log {
	[alias("Write-ScreenAndLog")]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false)]
		[alias("cat")]
		[string]
		$Category = "INFO"
		,
		[Parameter(Mandatory = $true)]
		[alias("msg")]
		[string]
		$Message
		,
		[Parameter(Mandatory = $false)]
		[alias("log")]
		[string]
		$LogFile = "$PSScriptRoot\logs\log_$(Get-Date -Format "MM.dd.yyyy_HH.mm.ss").txt"
		,
		[Parameter(Mandatory = $false)]
		[alias("color")]
		[System.ConsoleColor]
		$ForeGroundColor #= [System.Enum]::GetValues([System.ConsoleColor])
	)

	<#
		.SYNOPSIS
		Short description
		
		.DESCRIPTION
		Long description
		
		.PARAMETER Category
		Parameter description
		
		.PARAMETER Message
		Parameter description
		
		.PARAMETER LogFile
		Parameter description
		
		.PARAMETER Color
		Parameter description
		
		.EXAMPLE
		An example
		
		.NOTES

		ToDo:
		-----
			- Add a parameter to specify the log file name
			- Add a parameter to specify the log file path

		v11.20.20.0:
		-----------
			- 1st commit to git

		v11.20.21.0:
		-----------
			- Add support for logging to a file.
			- Add support for logging to a database.

		Notes:
		------
			- using System.IO;
			- Microsoft.Windows.PowerShell.Gui.Internal

	#>

	begin {
		
		### Enums
		###----------------
		Enum Category {
			INFO = 0
			WARN = 1
			ERROR = 2
		}
		
		$colors = [enum]::GetValues([System.ConsoleColor])
		

		### Set the $InformationAction Level
		###--------------------------
		###     InformationAction   : SilentlyContinue, Stop, Continue, Inquire, Ignore, Suspend, or Break
		###     Write-Log function  : INFO, WARN, PROMPT, ERROR, DEBUG, TRACE, or VERBOSE
		###--------------------------
		switch ($Category) {
			"INFO" {
				[int]$logLevel = 0
				$informationAction = "SilentlyContinue"
				if (!$ForeGroundColor) {
					$foreGroundColor = "White"
				}
			}
			"WARN" {
				[int]$logLevel = 1
				$informationAction = "Continue"
				if (!$ForeGroundColor) {
					$foreGroundColor = "DarkYellow"
				}
			}
			"PROMPT" {
				[int]$logLevel = 2
				$informationAction = "Inquire"
				if (!$ForeGroundColor) {
					$foreGroundColor = "Yellow"
				}
			}
			"ERROR" {
				[int]$logLevel = 3
				$informationAction = "Stop"
				if (!$ForeGroundColor) {
					$foreGroundColor = "Red"
				}
			}
			"DEBUG" {
				[int]$logLevel = 4
				$informationAction = "SilentlyContinue"
				if (!$ForeGroundColor) {
					$foreGroundColor = "White"
				}
			}
			default {
				[int]$logLevel = 0
				$informationAction = "SilentlyContinue"
				if (!$ForeGroundColor) {
					$foreGroundColor = "White"
				}
			}
		}
	}
	process {

		###===============
		### Write-host                                                                                      ### Write to Screen
		###===============
		<#
		 Notes:
		-------

			$InformationAction
			------------------
				- Introduced in PowerShell 5.0. 
				- Within the command or script in which it's used, the InformationAction common parameter overrides the value of the $InformationPreference preference variable, which by default is set to SilentlyContinue. 
				- When you use Write-Information in a script with InformationAction, Write-Information values are shown depending on the value of the InformationAction parameter. 
				- For more information about $InformationPreference, see about_Preference_Variables.

			Write-Host is a Wrapper
			-----------------------
				- Starting in Windows PowerShell 5.0, Write-Host is a wrapper for Write-Information 
				- This allows you to use Write-Host to emit output to the information stream. 
				- This enables the capture or suppression of data written using Write-Host while preserving backwards compatibility.
				- The $InformationPreference preference variable and InformationAction common parameter do not affect Write-Host messages. 
				- The exception to this rule is -InformationAction Ignore, which effectively suppresses Write-Host output. (see "Example 5")

			$InformationPreference
			----------------------
				- The $InformationPreference variable lets you set information stream preferences that you want displayed to users. 
				- Specifically, informational messages that you added to commands or scripts by adding the Write-Information cmdlet. 
				- If the InformationAction parameter is used, its value overrides the value of the $InformationPreference variable. 
				- Write-Information was introduced in PowerShell 5.0.

				The $InformationPreference variable takes one of the ActionPreference enumeration values: SilentlyContinue, Stop, Continue, Inquire, Ignore, Suspend, or Break.

				The valid values are as follows:

					Stop        :   Stops a command or script at an occurrence of the Write-Information command.
					Inquire     :   Displays the informational message that you specify in a Write-Information command, then asks whether you want to continue.
					Continue    :   Displays the informational message, and continues running.
									Suspend is only available for workflows which aren't supported in PowerShell 6 and beyond.
				SilentlyContinue:   (Default) No effect. The informational messages aren't displayed, and the script continues without interruption.
		#>



		### Test Color Settings
		#Write-Host "ForegroundColor: " $ForeGroundColor
		
		### InformationAction:								### -InformationPreference SilentlyContinue ???
		###=====================
		$__InformationAction = @(
			"SilentlyContinue"		### SilentlyContinue 	- no effect as the informational message aren't (Default) displayed, and the script continues without interruption.
			,
			"Stop"					### Stop 				- stops a command or script at an occurrence of the Write-Information command.
			,
			"Continue"				### Continue 			- displays the informational message, and continues running.
			,
			"Inquire"				### Inquire 			- displays the informational message that you specify in a Write-Information command, then asks whether you want to continue.
			,
			"Ignore"				### Ignore 				- suppresses the informational message and continues running the command. Unlike SilentlyContinue, Ignore completely forgets the informational message; it doesn't add the informational message to the information stream.
			,
			"Suspend"				### Suspend 			- isn't supported on PowerShell 6 and higher as it is only available for workflows.
			,
			"Break"					### Break 				- Enters the debugger at an occurrence of the Write-Information command.
		)
		
		### Test Values
		Write-Host "InformationAction	: " $informationAction 	-ForegroundColor DarkGray
		Write-Host "ForegroundColor		: " $ForegroundColor 	-ForegroundColor DarkGray
		Write-Host $Message -ForegroundColor $ForeGroundColor -InformationAction $informationAction 

		<#
		###===============
		### Write to Log
		###===============
		if ($logFile) {                                                                                     ### if $LogFile Parameter was used.
			try {
				### Build Log Record String
				###----------------------------------
				[string]$logString = "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss") - $category : $message"     ### Build Log Record String

				### Check if Log File & Path Exists, if not create it.
				###----------------------------------
				if( -not $(Test-Path -Path $logPath) ) {                                                    ### Check if log file exits
					try {
						New-Item -Path $logPath -ItemType File -Force                                       ### If Not, Create it
					} catch {
						Write-Warning -Message $global:Error[0].Exception.Message -ErrorAction Continue
					}
				}
				### Add Log Record
				###----------------------------------
				try {
					Add-Content -Path $logFile -Value $logString                                            ### Write Log Record to the $LogFile
				} catch {
					Write-Warning -Message $global:Error[0].Exception.Message -ErrorAction Continue
				}
			} catch {
				Write-Warning -Message $global:Error[0].Exception.Message -ErrorAction Continue
			}
		}
		#>
	}
	end {}
}