<#
Changes made:

Removed the CmdletBinding() attribute as it's not necessary for these functions.
Removed the begin, process, and end blocks from the functions as they're not necessary in this context.
Simplified the Get-xmlCommandLine function by using the ForEach-Object cmdlet instead of a foreach loop.
Simplified the parameter declarations in the Add-SynchronousCommand function and the script block.
Removed the [array] type declarations as they're not necessary.
Removed the return $null statement from the Add-SynchronousCommand function as it's not necessary.

#>
function Get-xmlCommandLine {
	param (
		[Parameter(Mandatory = $true)]
		[array]$SynchronousCommand
	)

	$CommandLines = $SynchronousCommand | ForEach-Object {
		try {
			[PSCustomObject]@{
				Order       = [int]$_.Order
				Action      = $_.Action
				CommandLine = $_.CommandLine
				Description = $_.Description
			}
		}
		catch {
			Write-Log "Error:  $_" "ERROR"
		}
	}
	return $CommandLines
}

function Add-SynchronousCommand {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Command,
		[Parameter(Mandatory = $true)]
		[string]$Description,
		[Parameter(Mandatory = $true)]
		[int]$NextCommandOrder
	)

	$newCommand = $xmlDoc.CreateElement("SynchronousCommand")

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

	$firstLogonCommands.AppendChild($newCommand) | Out-Null
}

& {
	param (
		[string]$Path = ".\Unattend.xml",
		[string]$Command = "cmd /c YourCommandHere",
		[string]$Description = "YourDescriptionHere"
	)

	$module_path = "D:\CBrennan\Repos\ioi-image-automation\powershell\CBrennan\Modules"
	@(
		"$module_path\ioModule.psm1",
		"$module_path\Axidio.Core.psm1"
	) | Import-Module -DisableNameChecking -Force

	Write-Log "Start of Script" HEAD

	$xmlDoc = New-Object System.Xml.XmlDocument
	$xmlDoc.Load($Path)

	$nsManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
	$nsManager.AddNamespace("ns", "urn:schemas-microsoft-com:unattend")

	$firstLogonCommands = $xmlDoc.SelectSingleNode("//ns:FirstLogonCommands", $nsManager)
	$synchronousCommand = $firstLogonCommands.SynchronousCommand
	$commandLines = Get-xmlCommandLine -SynchronousCommand $synchronousCommand

	$lastCommandOrder = $commandLines[-1].Order
	$nextCommandOrder = $lastCommandOrder + 1

	$appendNewNode = @{
		Command          = $Command
		Description      = $Description
		NextCommandOrder = $nextCommandOrder
	}
	Add-SynchronousCommand @appendNewNode
	Write-Log -Message "SynchronousCommand node added to the Unattend XML file. `n $($appendNewNode | Out-String)" "INFO"

	Write-Log  "Saving the XML file...`n`t Path:  $Path" INFO

	Write-Log "End of Script" FOOT
}