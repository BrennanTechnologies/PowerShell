$Modules = @( 
  "MicrosoftPowerBIMgmt",
  "ReportingServicesTools"
)
foreach($Module in $Modules){
  if( -Not $(Get-Module -Name $Module) ){
      Write-Host "Importing Module: " $Module
      Import-Module -Name $Module
  }
}