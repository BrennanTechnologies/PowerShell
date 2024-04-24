function Write-Log {
	[CmdletBinding()]
	param (
		[Parameter( Position = 0,
			Mandatory = $true)]
		[Alias("msg")]
		[String]
		$Message
		,
		[Parameter( Position = 1,
			Mandatory = $false)]
		[Alias("cat", "Level")]
		[ValidateSet("INFO", "HEADER", "FOOTER", "WARN", "ERROR", "SUCCESS", "DEBUG", "VERBOSE", "TRACE", "FATAL")]
		[String]
		$Category = "INFO"
		#,
		#[Parameter()]
		#[String]
		#$LogFile #= $script:LogFile
		,
		[Parameter()]
		[Alias("Q", "S", "Quite")]
		[Switch]
		$Silent
		,
		[Parameter()]
		[Alias("fg", "COL")]
		[String]
		$Color
		#,
		#[Parameter()]
		#[Alias("bg")]
		#[String]
		#$Args
	)
	begin {
		### Create Log File:
		### ------------------
		if ( -not $(Test-Path -Path $LogFile)) {
			New-Item -Path $LogFile -ItemType File -Force | Out-Null
			Add-Content -Path $LogFile -Value "LOG-ENTRY-DATETIME `t CAT: `t MSG:"
		}
	}
	process {
		switch ($Category) {
			"INFO" { 
				$ForegroundColor = "Gray" #"Cyan" 
				$strCategory = "INFO   "
			}
			"HEADER" {
				$ForegroundColor = "Cyan" #"Magenta" 
				$strCategory = "HEADER "
			}
			"FOOTER" {
				$ForegroundColor = "DarkGray"
				$strcategory = "FOOTER "
			}
			"WARN" {
				$ForegroundColor = "Yellow" 
				$strCategory = "WARN   "
			}
			"SUCCESS" { 
				$ForegroundColor = "Green" 
				$strCategory = "SUCCESS"
			}
			"ERROR" { 
				$ForegroundColor = "Red" 
				$strCategory = "ERROR  "
			}
			default { 
				$ForegroundColor = "White" 
				$strCategory = ""
			}
		}

		if ($Color) {
			$foregroundColor = $Color
		}

		### Build Log String:
		### ------------------
		$logString = "$(Get-Date -Format "MM/dd/yyyy HH:mm:ss") `t $($strCategory.ToUpper()) `t $message"

		### Add Log Record:
		### ------------------
		try {
			Add-Content -Path $LogFile -Value $logString
		}
		catch {
			Write-Log "Error: $($_.Exception.Message)" -Category Error
		}
		if (-not $Silent.IsPresent) {
			### Original
			### ------------
			#Write-Host $logString -ForegroundColor $foregroundColor
			
			### New
			### ------------
			Write-Host $(Get-Date -Format "MM/dd/yyyy HH:mm:ss") -ForegroundColor White -NoNewline
			Write-Host  `t $($strCategory.ToUpper()) -ForegroundColor White -NoNewline
			Write-Host `t $message -ForegroundColor $foregroundColor

		}
	}
	end {}
}

Write-Log "Test: " -Colors Green 