Import-Module -Name Abacus-Reporting -Force

#$Status = New-Object PSObject -Property @{ExitCode = ""}
$Services = Get-Service | Select-Object -Property * | Get-Member #-MemberType NoteProperty

$Report = @()


[PSCustomObject]$ReportObject = Get-Service | Select-Object -Property *

foreach($Service in $Services) {
    $Object = [PSCustomObject]@{
        Status            = $Service.Status
        Name              = $Service.Name
        DisplayName       = $Service.DisplayName
        ComputerName      = $env:COMPUTERNAME
        DependentServices = $Service.DependentServices
    }
    $Report += $Object
}

#$Services | %{Write-Host $_.Name}
#$ReportObject  = $Services
$ReportObject  = $Report
$To            = "cbrennan@abacusgroupllc.com"
$Subject       = "Test Report"


Abacus-Reporting\Send-EmailReport -ReportObject $ReportObject -To $To -Subject $Subject


