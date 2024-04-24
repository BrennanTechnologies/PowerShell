
[xml]$rsopXML = (Get-Content -Path '.\baselineGPOReport.xml')

[xml]$rsopXML = Import-Clixml -Path '.\baselineGPOReport.xml'


$rsopXML.Rsop.ComputerResults.ExtensionData.Extension | Select-Object -ExpandProperty Name

/Rsop/ComputerResults/ExtensionData[77]/Extension/q12:Policy[81]/q12:State
<#
$rsopXML.Rsop.DataType

$rsopXML.Rsop.ComputerResults


#>


$rsopXML.Rsop.ComputerResults

$gpos = $rsopXML.Rsop.ComputerResults.GPO

$rsopXML.Rsop.ComputerResults.SecurityGroup.Name

$rsopXML.Rsop.ComputerResults.ExtensionStatus

### EventsDetails
$rsopXML.Rsop.ComputerResults.EventsDetails | Select-Object -ExpandProperty SinglePassEventsDetails

### ExtensionData
$rsopXML.Rsop.ComputerResults.ExtensionData
$rsopXML.Rsop.ComputerResults.ExtensionData.Name

$var = $rsopXML.Rsop.ComputerResults.ExtensionData.Extension
$var.type

$rsopXML.Rsop.ComputerResults.ExtensionData.Extension.GetAttributeNode()  #    | gm



q12:RegistrySettings

Select-XML -Path .\baselineGPOReport.xml -Namespace @{rsop = 'http://www.microsoft.com/GroupPolicy/Settings/Auditing' } -XPath '//Rsop:ComputerResults'

"http://www.microsoft.com/GroupPolicy/Settings/Base"
"http://www.microsoft.com/GroupPolicy/Types"


$xmlns = "http://www.w3.org/2001/XMLSchema-instance" 
#$xmlns = "http://www.microsoft.com/GroupPolicy/Rsop"
Select-XML -Path .\baselineGPOReport.xml -Namespace @{rsop = $xmlns } -XPath '//rsop:RegistrySettings'

Select-XML -Path .\baselineGPOReport.xml -Namespace @{rsop = "http://www.microsoft.com/GroupPolicy/Rsop" } -XPath '//rsop:Policy' | Select-Object -ExpandProperty Node #| Select-Object -ExpandProperty 'Group Policy Registry' # | Select-Object -ExpandProperty InnerXml | ConvertFrom-Xml | Select-Object -ExpandProperty Extension | Select-Object -ExpandProperty Name



#| Select-Object -ExpandProperty Node #| Select-Object -ExpandProperty InnerXml | ConvertFrom-Xml | Select-Object -ExpandProperty Extension | Select-Object -ExpandProperty Name

