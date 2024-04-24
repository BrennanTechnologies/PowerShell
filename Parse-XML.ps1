<#
    .SYNOPSIS
        Appends a SynchronousCommand node to an Unattend XML file.
    .DESCRIPTION
        - Appends a SynchronousCommand node to the FirstLogonCommands node in an Unattend XML file.
        - The SynchronousCommand node is appended to the end of the FirstLogonCommands node.
        - The SynchronousCommand node contains the CommandLine, Description, and Order nodes.
        - The CommandLine node contains the command to be executed.
        - The Description node contains the description of the command.
        - The Order node contains the order of the command.
    .PARAMETER Path
        The path to the Unattend XML file.
    .PARAMETER Command
        The command to be executed.
    .PARAMETER Description
        The description of the command.
    .EXAMPLE
        PS> Append-ChildNode.ps1 -cmd $cmd -desc $desc
    .NOTES
        Update XML files using PowerShell:
        https://devblogs.microsoft.com/powershell-community/update-xml-files-using-powershell/

        Selecting attributes in xml using xpath in powershell:
        https://stackoverflow.com/questions/17583373/selecting-attributes-in-xml-using-xpath-in-powershell

        Author:
            Chris Brennan
            Axidio
            cbrennan@axidio.com, chr17070@tjx.com
            2-17-2024
#>

function Get-xmlCommandLine {
    <#
    .SYNOPSIS
        Gets the CommandLines from each SynchronousCommand node.
    .DESCRIPTION
        Gets each CommandLine from the SynchronousCommand nodes in the Unattend XML file.
    .PARAMETER SynchronousCommand
        The SynchronousCommand nodes from the Unattend XML file.
    .EXAMPLE
        PS> Get-xmlCommandLines -SynchronousCommand $SynchronousCommand
    .OUTPUTS
        - Returns the CommandLines from each SynchronousCommand node.
    .NOTES
        - The SynchronousCommand nodes are appended to the FirstLogonCommands node in the Unattend XML file.
        - The SynchronousCommand nodes are appended to the end of the FirstLogonCommands node.  
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$SynchronousCommand
    )
    begin {
    }
    process {
        <#
            Command Object Data Structure:
           
            PS> $SynchronousCommand | FL
                Order       : 1
                action      : add
                CommandLine : Powershell -EP BYPASS -f C:\Staging\Hide_P_Drive\Hide_P_Drive.ps1
                Description : Hide P Drive
        #>

        ### Get the CommandLines
        ###       --> from each SynchronousCommand node
        ### -----------------------------------
        [array]$CommandLines = @()
        foreach ($CommandLine in $SynchronousCommand) {

            Write-Debug "Order       : $($CommandLine.Order)"
            Write-Debug "Action      : $($CommandLine.Action)"
            Write-Debug "CommandLine : $($CommandLine.CommandLine)"
            Write-Debug "Description : $($CommandLine.Description)"

            ### Convert Order to Integer
            ### -----------------------------------
            try {
                $CommandLine.Order = [int]$CommandLine.Order
            }
            catch {
                $errMsg = "Error:  $($CommandLine.Order) is Not a [string] that can be converted to [int]"
                Write-Log $errMsg "ERROR"
            }

            ### Create a new command object
            ### -----------------------------------
            try {
                $CommandLine = [PSCustomObject]@{
                    Order       = [int]$CommandLine.Order ### Could fail if not an integer
                    Action      = $CommandLine.Action
                    CommandLine = $CommandLine.CommandLine
                    Description = $CommandLine.Description
                }
            }
            catch {
                Write-Log "Error:  $_" "ERROR"
            }

            Write-Verbose "CommandLine:  $CommandLine"
            $CommandLines += $CommandLine
        }
    }
    end {
        return $CommandLines
    }
}

function Add-SynchronousCommand {
    <#
    .SYNOPSIS
        Adds a SynchronousCommand node to an Unattend XML file.
    .DESCRIPTION
        Appends a new SynchronousCommand node to the FirstLogonCommands node in an Unattend XML file.
    .PARAMETER Command
        The command to be executed.
    .PARAMETER Description
        The description of the new command.
    .PARAMETER NextCommandOrder
        The order of the new command.
    .EXAMPLE
        PS> Add-SynchronousCommand -Command "cmd /c YourCommandHere" -Description "YourDescriptionHere" -NextCommandOrder 14
    .OUTPUTS
        - Return is [Void]$null
    .NOTES
        - The SynchronousCommand node is appended to the FirstLogonCommands node in the Unattend XML file.
        - The SynchronousCommand node is appended to the end of the FirstLogonCommands node.
    #>
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
        ### Create a new SynchronousCommand node
        ### -----------------------------------
        $newCommand = $xmlDoc.CreateElement("SynchronousCommand")
    }
    process {
        ### Add the wcm:action attribute
        ### -----------------------------------
        $actionAttribute = $xmlDoc.CreateAttribute("wcm:action")
        $actionAttribute.Value = "add"                          ### ??? <-- Will this always be "add"? - ask Lucas
        $newCommand.Attributes.Append($actionAttribute) | Out-Null

        ### Add the CommandLine, Description, and Order nodes
        ### -----------------------------------
        $commandLine = $xmlDoc.CreateElement("CommandLine")
        $commandLine.InnerText = $Command                       ### $commandLine.InnerText = "cmd /c YourCommandHere"
        $newCommand.AppendChild($commandLine) | Out-Null

        $desc = $xmlDoc.CreateElement("Description")
        $desc.InnerText = $Description                          ### $description.InnerText = "YourDescriptionHere"
        $newCommand.AppendChild($desc) | Out-Null

        $order = $xmlDoc.CreateElement("Order")
        $order.InnerText = $NextCommandOrder                    ### $order.InnerText = "14"
        $newCommand.AppendChild($order) | Out-Null
    }
    end {
        ### Add the new SynchronousCommand node to the FirstLogonCommands node
        ### -----------------------------------
        $firstLogonCommands.AppendChild($newCommand) | Out-Null

        return $null ### <--function is [void] - so return $null
    }
}

<#
        .SYNOPSIS
            - Appends a SynchronousCommand node to the FirstLogonCommands node in an Unattend XML file
        .DESCRIPTION
            - Create an XmlDocument Object & Load the XML File into the XmlDocument Object
            - Requires XmlNameSpaceManager Object & Add the NameSpace to the XmlNamespaceManager
            - Get the FirstLogonCommands node
                - from the XmlDocument Object
            - Get the SynchronousCommand nodes
            - Get the CommandLines
                - from the SynchronousCommand nodes
            - Get the next command order
            - Append New SynchronousCommand Node to the XML File
            - Save the XML file
        .PARAMETER Path
            The path to the Unattend XML file.
        .PARAMETER Command
            The command to be executed.
        .PARAMETER Description
            The description of the command.
        .OUTPUTS
            Save File.
        .NOTES
#>
### ---------------------------------------------------------------------------------------------------
### MAIN: Execute the script ==> Append-ChildNode.ps1 -Path "Unattend.xml" -Command "cmd /c YourCommandHere" -Description "YourDescriptionHere"
### ---------------------------------------------------------------------------------------------------
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
        ### Load the required modules
        ### ----------------------------------
        $module_path = "D:\CBrennan\Repos\ioi-image-automation\powershell\CBrennan\Modules"
        @(
            "$module_path\ioModule.psm1",
            "$module_path\Axidio.Core.psm1"
        ) | Import-Module -DisableNameChecking -Force #-Verbose

        Write-Log "Start of Script" HEAD
    }
    process {
        ### -----------------------------------
        ### 1. Open, Parse, & Append the XML File
        ### -----------------------------------

        ### Create an XmlDocument Object
        ### -----------------------------------
        $xmlDoc = New-Object System.Xml.XmlDocument

        ### Load the XML File into the XmlDocument Object
        ### -----------------------------------
        $xmlDoc.Load($Path)
        Write-Log "Unattend XML file loaded into the XmlDocument Object. `n`t Path:  $Path" INFO

        ### Create an XmlNameSpaceManager Object
        ###       - USING the XmlDocument Object name table
        ### -----------------------------------
        $nsManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)

        ### Add the NameSpace to the XmlNamespaceManager
        ### -----------------------------------
        $nsManager.AddNamespace("ns", "urn:schemas-microsoft-com:unattend")

        ### Get the FirstLogonCommands node
        ###       --> from the XmlDocument Object
        ### -----------------------------------
        $firstLogonCommands = $xmlDoc.SelectSingleNode("//ns:FirstLogonCommands", $nsManager)

        ### Get the SynchronousCommand nodes
        ###       --> from the FirstLogonCommands node
        ### -----------------------------------
        [array]$synchronousCommand = $firstLogonCommands.SynchronousCommand

        ### Get the CommandLines
        ###       --> from the SynchronousCommand nodes
        ### -----------------------------------
        [array]$commandLines = Get-xmlCommandLine -SynchronousCommand $synchronousCommand #-Verbose

        ### Get the next command order
        ### -----------------------------------
        [int]$lastCommandOrder = $commandLines[-1].Order
        [int]$nextCommandOrder = $lastCommandOrder + 1

        ### -----------------------------------
        ### 2. Append New SynchronousCommand Node to the XML File
        ### -----------------------------------
        $appendNewNode = [ordered]@{
            Command          = $Command
            Description      = $Description
            NextCommandOrder = $nextCommandOrder
        }
        Add-SynchronousCommand @appendNewNode   ### <-- Add-SynchronousCommand -Command $cmd -Description $desc -NextCommandOrder $nextCommandOrder
        Write-Log -Message "SynchronousCommand node added to the Unattend XML file. `n $($appendNewNode | Out-String)" "INFO"

        ### -----------------------------------
        ### 3. Save the XML file
        ### -----------------------------------
        Write-Log  "Saving the XML file...`n`t Path:  $Path" INFO
        #$xmlDoc.Save($Path)
    }
    end {
        Write-Log "End of Script" FOOT
    }
}