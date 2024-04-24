cls

### User Properties
###--------------------------------------------------------------
#[array]$ADProperties = @("sAMAccountName", "name")                            # Test Properties
[array]$ADProperties = @(                                          # Production Properties
                        "sAMAccountName",
                        "Enabled",
                        "givenName",
                        "sn",
                        "displayName",
                        "description",
                        "department",
                        "company",
                        "mail",
                        "distinguishedName",
                        "extensionAttribute1",
                        "extensionAttribute2",
                        "extensionAttribute3",
                        "extensionAttribute4",
                        "extensionAttribute5",
                        "extensionAttribute6",
                        "extensionAttribute7",
                        "extensionAttribute8",
                        "extensionAttribute9",
                        "pwdLastSet",
                        "passwordNeverExpires",
                        "msDS-UserPasswordExpiryTimeComputed"
                        )
$ADFilter = "*"
$SearchBase = "OU=All.Users,DC=bjc-nt,DC=bjc,DC=org"
#$SearchBase = "OU=Privileged,OU=All.Users,DC=bjc-nt,DC=bjc,DC=org"

Write-Host "Getting AD Users . . . " -ForegroundColor Yellow

$ADUserObjects = Get-ADUser -SearchBase $SearchBase -Filter $ADFilter -Properties $ADProperties | 
                    Select-Object $ADProperties |
                    Where-Object { $_.Company -like '*110*' -or $_.Company -like '*304*' -or $_.Company -like 'BHC (DEP)*'}


#        $ADUsers += Get-ADUser -Identity $Member -Properties sAMAccountName, description, distinguishedName, objectClass, company | `
#            Select-Object -Property SamAccountName, description, distinguishedName, objectClass, company | `
#            Where-Object { $_.Company -like '*110*' -or $_.Company -like '*304*' -or $_.Company -like 'BHC (DEP)*'}
        
$ADUsers = @()
foreach ($User in $ADUserObjects) {

Write-Host "sAMAccountName: " $User.sAMAccountName -ForegroundColor Cyan
                
    ### Need to Conver Date Time 
    [DateTime]$pwdLastSet = [DateTime]::FromFileTime($User.pwdLastSet).ToString('MM/dd/yyyy')
    $pwdLastSet = $pwdLastSet.ToString('MM/dd/yyyy')

    try {
        $UserPasswordExpiryTimeComputed =  [DateTime]::FromFileTime($User.'msDS-UserPasswordExpiryTimeComputed')
        $UserPasswordExpiryTimeComputed = $UserPasswordExpiryTimeComputed.ToString('MM/dd/yyyy')
    } catch {
        Write-Host "msDS-UserPasswordExpiryTimeComputed: " $User.'msDS-UserPasswordExpiryTimeComputed' -ForegroundColor Yellow
        Out-File -FilePath "$PSSCriptRoot\Errors.txt" -InputObject $User.'msDS-UserPasswordExpiryTimeComputed' -Force
    }

    $User = [PSCustomObject]@{
        sAMAccountName         = $User.sAMAccountName
        Enabled                = $User.Enabled
        givenName              = $User.givenName
        sn                     = $User.sn
        displayName            = $User.displayName
        description            = $User.description
        department             = $User.department
        company                = $User.company
        mail                   = $User.mail
        distinguishedName      = $User.distinguishedName
        extensionAttribute1    = $User.extensionAttribute1  # HR Hire Date
        JobeCode               = $User.extensionAttribute2  # Job Code (aka Position Code, aka Title Number)
        extensionAttribute3    = $User.extensionAttribute3  # manager employee number
        CompanyNumber          = $User.extensionAttribute4  # Company Number
        DepartmentNumber       = $User.extensionAttribute5  # Department Number (aka Cost Center)
        extensionAttribute6    = $User.extensionAttribute6
        EmployeeTypeCode       = $User.extensionAttribute7  # employee type code
        extensionAttribute8    = $User.extensionAttribute8  # friendly Name
        extensionAttribute9    = $User.extensionAttribute9  # Student Status (I'm guessing JCN
        #pwdLastSet             = $User.pwdLastSet
        pwdLastSet             = $pwdLastSet
        passwordNeverExpires   = $User.passwordNeverExpires 
        UserPasswordExpiryTimeComputed =  $UserPasswordExpiryTimeComputed
    }
    $ADUsers += $User
}

$ExportPath = "$PSScriptRoot\BooneADUsers.csv"
$ADUsers | Export-Csv -Path $ExportPath -NoTypeInformation
Start-Process $ExportPath 


