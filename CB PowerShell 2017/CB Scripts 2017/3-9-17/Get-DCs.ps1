cls

# Import the ActiveDirectory module
Import-Module -Name ActiveDirectory

$Domains = (Get-ADForest).Domains

foreach ($Domain in $Domains)
{
    $Domain 
    $DC= Get-ADDomainController -filter *
    $DC.name
    
}


