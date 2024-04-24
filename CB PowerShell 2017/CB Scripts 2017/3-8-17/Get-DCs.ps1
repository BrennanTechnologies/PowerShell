cls

# Import the ActiveDirectory module
Import-Module -Name ActiveDirectory

$Domains = (Get-ADForest).Domains

foreach ($Domain in $Domains)
{
    $DC= Get-ADDomainController -filter *
    $DC.name
    
}


