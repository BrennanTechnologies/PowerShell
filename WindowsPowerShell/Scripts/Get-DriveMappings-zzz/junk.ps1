function Get-MappedDrive {
    [CmdletBinding()]
    Param (
        # Computer name
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]$ComputerName,

        # Domain admin credentials
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )
    Begin {
        [long]$Hive = 2147483651
    }
    Process {
        Foreach ($Computer in $ComputerName) {
            $LoggedOnUsers = GetLoggedOnUsers -ComputerName $Computer -Credential $Credential
            Foreach ($User in $LoggedOnUsers) {
                # Registry only picks up persistent drives so get homedrive from AD
                $ADUser = Get-ADUser $User.UserName.split('\')[-1] -Properties HomeDirectory, HomeDrive
                $HomeDrive = [pscustomobject]@{
                    Letter       = $ADUser.HomeDrive[0]
                    Path         = $ADUser.HomeDirectory
                    UserName     = $User.UserName
                    ComputerName = $User.ComputerName
                }
                $HomeDrive.PSObject.TypeNames.Insert(0, 'MappedDrive')
                $HomeDrive

                # Query the registry to get persistent drives
                $RegProv = Get-WmiObject -List -Namespace "root\default" -ComputerName $Computer -Credential $Credential | Where-Object {$_.Name -eq 'StdRegProv'}
                $DriveList = $RegProv.EnumKey($Hive, "$($User.SID)\Network")
                if ($DriveList.sNames.count -eq 0) {
                    Write-Warning "No persistent drives for $($User.UserName) on $Computer"
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
            }
        }
    }
    End {}