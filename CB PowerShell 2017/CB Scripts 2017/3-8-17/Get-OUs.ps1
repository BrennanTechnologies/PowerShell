cls

# Import the ActiveDirectory module
Import-Module -Name ActiveDirectory

$Domains = (Get-ADForest).Domains

foreach ($Domain in $Domains)
{
    # Show OU Properties
    #Get-ADOrganizationalUnit -Filter * -Properties *| Get-Member


    # Get OU properties
    $OUs =  Get-ADOrganizationalUnit -Filter * -Properties *

    foreach ($OU in $OUs)
    {
        #Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * -Properties * | Select-Object -Property Name, CanonicalName, createTimeStamp, OU, gPLink, Description, DisplayName, DistinguishedName #| ft
        #Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * -Properties * | Select-Object -Property Name, CanonicalName, Description, DisplayName, DistinguishedName #| ft
        Get-ADOrganizationalUnit -SearchBase $OU -SearchScope Subtree -Filter * -Properties * | Select-Object -Property Name, Description, DisplayName #| ft
    }
    
}
<#
Name
CanonicalName
createTimeStamp
OU
gPLink
Description                     : 
DisplayName                     : 
DistinguishedName

#>