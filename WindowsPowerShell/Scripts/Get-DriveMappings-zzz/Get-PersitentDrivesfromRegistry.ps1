# Query the registry to get persistent drives
[long]$Hive = 2147483651


#Get-WmiObject -Class win32_computersystem -ComputerName $env:COMPUTERNAME -Property * 
#Get-CimInstance –ComputerName . –ClassName Win32_ComputerSystem | Select-Object UserName
$User = (Get-WmiObject -Class win32_computersystem -ComputerName $env:COMPUTERNAME).UserName

$User.sid
exit


#$RegProv = Get-WmiObject -List -Namespace "root\default" -ComputerName $Computer -Credential $Credential | Where-Object {$_.Name -eq 'StdRegProv'}
$RegProvider = Get-WmiObject -List -Namespace "root\default" -ComputerName $env:COMPUTERNAME | Where-Object {$_.Name -eq 'StdRegProv'}

$DriveList = $RegProvider.EnumKey($Hive, "$($User.SID)\Network")


if ($DriveList.sNames.count -eq 0) {
    Write-Warning "No persistent drives for $($User.UserName) on $env:COMPUTERNAME"
    Continue
}
foreach ($Drive in $DriveList.sNames) {
    $Path = $($RegProv.GetStringValue($Hive, "$($User.SID)\Network\$($Drive)", 'RemotePath')).sValue
    $MappedDrive = [pscustomobject]@{
        Letter       = $Drive
        Path         = $Path
        UserName     = $User.UserName
        ComputerName = $User.ComputerName
    }
    $MappedDrive.PSObject.TypeNames.Insert(0, 'MappedDrive')
    $MappedDrive
}