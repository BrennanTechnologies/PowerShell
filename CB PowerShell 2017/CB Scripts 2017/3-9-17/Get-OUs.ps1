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



    #Perform AD search. The quotes "" used in $SearchLoc is essential 
    #Without it, Export-ADUsers returuned error 
                  Get-ADUser -server $ADServer -searchbase "$SearchLoc" -Properties * -Filter * |  
                  Select-Object @{Label = "First Name";Expression = {$_.GivenName}},  
                  @{Label = "Last Name";Expression = {$_.Surname}}, 
                  @{Label = "Display Name";Expression = {$_.DisplayName}}, 
                  @{Label = "Logon Name";Expression = {$_.sAMAccountName}}, 
                  @{Label = "Full address";Expression = {$_.StreetAddress}}, 
                  @{Label = "City";Expression = {$_.City}}, 
                  @{Label = "State";Expression = {$_.st}}, 
                  @{Label = "Post Code";Expression = {$_.PostalCode}}, 
                  @{Label = "Country/Region";Expression = {if (($_.Country -eq 'GB')  ) {'United Kingdom'} Else {''}}}, 
                  @{Label = "Job Title";Expression = {$_.Title}}, 
                  @{Label = "Company";Expression = {$_.Company}}, 
                  @{Label = "Description";Expression = {$_.Description}}, 
                  @{Label = "Department";Expression = {$_.Department}}, 
                  @{Label = "Office";Expression = {$_.OfficeName}}, 
                  @{Label = "Phone";Expression = {$_.telephoneNumber}}, 
                  @{Label = "Email";Expression = {$_.Mail}}, 
                  @{Label = "Manager";Expression = {%{(Get-AdUser $_.Manager -server $ADServer -Properties DisplayName).DisplayName}}}, 
                  @{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement# replaces $_.Enabled 
                  @{Label = "Last LogOn Date";Expression = {$_.lastlogondate}} |  
                   
                  #Export CSV report 
                  Export-Csv -Path $csvreportfile -NoTypeInformation 


$reportdate = Get-Date -Format ssddmmyyyy 

$csvreportfile = $path + "\ALLADUsers_$reportdate.csv"




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