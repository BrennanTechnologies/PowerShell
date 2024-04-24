
[xml]$rsopXML = (Get-Content -Path '.\baselineGPOReport.xml')

$rsop = Select-Xml -Xml $rsopXML -Namespace @{Rsop = "http://www.microsoft.com/GroupPolicy/Rsop" } -XPath "//Rsop:ComputerResults" | Select-Object -ExpandProperty Node # | ForEach-Object { $_.Node.Innerxml } #| Select-Object -ExpandProperty Node #
$rsop.ExtensionData.Name 
Exit

$extenstions = $rsop.ExtensionData.Extension
foreach ($extenstion in $extenstions) {
	$extenstion.Innerxml | Where { $_ -like "Allow users*" }
}
#$XPath = '/Rsop' #/RegistrySettings/Policy
#$data = Select-Xml -Path $Path -XPath $Xpath  | Select-Object -ExpandProperty Node
