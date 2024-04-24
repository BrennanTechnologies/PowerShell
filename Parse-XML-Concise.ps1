function Get-xmlCommandLine {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[array]$SynchronousCommand
	)

	process {
		[array]$CommandLines = @()
		foreach ($CommandLine in $SynchronousCommand) {
			try {
				$CommandLine.Order = [int]$CommandLine.Order
				$CommandLine = [PSCustomObject]@{
					Order       = [int]$CommandLine.Order
					Action      = $CommandLine.Action
					CommandLine = $CommandLine.CommandLine
					Description = $CommandLine.Description
				}
			}
			catch {
				Write-Log "Error:  $_" "ERROR"
			}
			$CommandLines += $CommandLine
		}
	}
	end {
		return $CommandLines
	}
}

function Add-SynchronousCommand {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Command
		,
		[Parameter(Mandatory = $true)]
		[string]
		$Description
		,
		[Parameter(Mandatory = $true)]
		[int]
		$NextCommandOrder
	)

	begin {
		$newCommand = $xmlDoc.CreateElement("SynchronousCommand")
	}
	process {
		$actionAttribute = $xmlDoc.CreateAttribute("wcm:action")
		$actionAttribute.Value = "add"
		$newCommand.Attributes.Append($actionAttribute) | Out-Null

		$commandLine = $xmlDoc.CreateElement("CommandLine")
		$commandLine.InnerText = $Command
		$newCommand.AppendChild($commandLine) | Out-Null

		$desc = $xmlDoc.CreateElement("Description")
		$desc.InnerText = $Description
		$newCommand.AppendChild($desc) | Out-Null

		$order = $xmlDoc.CreateElement("Order")
		$order.InnerText = $NextCommandOrder
		$newCommand.AppendChild($order) | Out-Null
	}
	end {
		$firstLogonCommands.AppendChild($newCommand) | Out-Null
		return $null
	}
}

& {
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$Path = ".\Unattend.xml"
		,
		[Parameter()]
		[string]
		$Command = "cmd /c YourCommandHere"
		,
		[Parameter()]
		[string]
		$Description = "YourDescriptionHere"
	)

	begin {
		$module_path = "D:\CBrennan\Repos\ioi-image-automation\powershell\CBrennan\Modules"
		@(
			"$module_path\ioModule.psm1",
			"$module_path\Axidio.Core.psm1"
		) | Import-Module -DisableNameChecking -Force

		Write-Log "Start of Script" HEAD
	}
	process {
		$xmlDoc = New-Object System.Xml.XmlDocument
		$xmlDoc.Load($Path)

		$nsManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
		$nsManager.AddNamespace("ns", "urn:schemas-microsoft-com:unattend")

		$firstLogonCommands = $xmlDoc.SelectSingleNode("//ns:FirstLogonCommands", $nsManager)
		[array]$synchronousCommand = $firstLogonCommands.SynchronousCommand
		[array]$commandLines = Get-xmlCommandLine -SynchronousCommand $synchronousCommand

		[int]$lastCommandOrder = $commandLines[-1].Order
		[int]$nextCommandOrder = $lastCommandOrder + 1

		$appendNewNode = [ordered]@{
			Command          = $Command
			Description      = $Description
			NextCommandOrder = $nextCommandOrder
		}
		Add-SynchronousCommand @appendNewNode
		Write-Log -Message "SynchronousCommand node added to the Unattend XML file. `n $($appendNewNode | Out-String)" "INFO"

		Write-Log  "Saving the XML file...`n`t Path:  $Path" INFO
	}
	end {
		Write-Log "End of Script" FOOT
	}
}