################
Get-Service | Get-Member 
 
$ReportObject = Get-Service | Select-Object -Property *



### Get Object Type (Class)
$ObjectTypeName = ($ReportObject | Get-Member).TypeName | Select-Object -Unique

### The allowed values of MemberType are AliasProperty, CodeProperty, Property, NoteProperty, ScriptProperty, Properties, PropertySet, Method, 
### CodeMethod, ScriptMethod, Methods, ParameterizedProperty, MemberSet, and All.
$ReportObjectMembers  = $ReportObject | Get-Member 
$ReportObjectMembers  = $ReportObject | Get-Member -MemberType NoteProperty 

#######################################
### Expand Member Arrays - Working
#######################################
[PSCustomObject]$ReportObject = Get-Service | Select-Object -Property *

$Report = @()
$Report = New-Object PSCustomObject

foreach($Object in $ReportObject){
    
    ## Get Members 
    [PSCustomObject]$Members = $ReportObject | Get-Member 
    
    foreach($Member in $Members){
        [string]$MemberName = $Member.Name
        $IsArray = $Object.($Member.Name) -is [array]
        Write-Host $Member.Name " - IsArray:" $IsArray -ForegroundColor Magenta

        if($Object.($Member.Name)-is [array]){
            #Write-Host $Member.Name "IsArray: " $IsArray -ForegroundColor Yellow
            [array]$ExpandedMember = $Object.($Member.Name) | Select-Object -ExpandProperty $Member.Name
           $ExpandedMember
           $Report += $ExpandedMember
        }
        else{
            #Write-Host $Member.Name "IsArray: " $IsArray -ForegroundColor Cyan
            $Member.Definition.Split("=")[1]
$Object = [PSCustomObject]@{
            $Report += $Member
        }
    }
}
#######################################



        #foreach($Member in ($ReportObject | Get-Member <#-MemberType NoteProperty#> )){
#foreach($Member in ($ReportObjectMembers | Where{$_.Name -like "ServicesDependedOn"})){
    #$Member.Definition | gm
    #$Member.GetType()
 #   $MemberName = $Member.Name
    #$MemberName

 #   $IsArray = $ReportObject.$MemberName -is [array]
    
 #   Write-Host $MemberName $IsArray
}



    foreach($Member in $ReportObjectMembers){
    #foreach($Member in ($ReportObjectMembers | Where{$_.Name -like "ServiceType"}) ){
        #$Member | GM
        #$Member.GetType()
        $MemberName = $Member.Name
        $MemberName 
        $ReportObject.$MemberName -is [array]
        #$MemberType = (($Member.Name).GetType()).Name
        #$Member.GetType()
        #$MemberType
<#
        if($ReportObject.$MemberName -is [array]){
            #$IsArray    = $ReportObject.$MemberName -is [array]
            #Write-Host $MemberName $IsArray -ForegroundColor Cyan
            Write-Host "MemberArray: " $MemberName -ForegroundColor Yellow
            #$MemberArray = $ReportObject.$MemberName | Select-Object -ExpandProperty $MemberName
            #$MemberArray

            #$ExpanedMember = ( $ReportObject.$MemberName | @{ n = $MemberName ; e = { ($_ | Select-Object -ExpandProperty $MemberName )}} )
            #$ExpanedMember
        }
        else{
            $MemberName = $Member.Name
            $MemberType = ($Member.Name).GetType()
            Write-Host "MemberName: " $MemberName -ForegroundColor Magenta
            Write-Host "MemberType: " $MemberName -ForegroundColor Magenta
            #$Report | Add-Member -MemberType NoteProperty -Name $Member.Name -Value $Member.Name
        }
#>
    }


$ServersInGroup = $Report | Where-Object { $_.ServerName -like $ServerGroup } | `
Select-Object vCenter, ServerName, `
    @{ n = 'TagCategory' ; e = { ($_ | Select-Object -ExpandProperty TagCategory ) -join ", " } } , `
    @{ n = 'TagName'     ; e = { ($_ | Select-Object -ExpandProperty TagName     ) -join ", " } } , `
    VeeamRestorePoint, FirstSeen `
    | ConvertTo-Html 

##########        


$ReportObject.DependentServices
($ReportObject.DependentServices).GetType()

#$ReportObject | Get-Member -MemberType Property,NoteProperty
$Columns = ($ReportObject | Get-Member -MemberType Property,NoteProperty).Name
#Columns = ($ReportObject | Get-Member -MemberType NoteProperty).Name # NoteProperties Only
foreach($Column in $Columns){

}
foreach ($Object in $ReportObject){
    $Column = ($Object | Get-Member -MemberType Property,NoteProperty).Name
    $Object.$Column
}
e#xit

$ReportObject | Get-Member | select -Property *        
$Columns = ($ReportObject | Get-Member -MemberType Property,NoteProperty).Name
foreach($Column in $Columns){
    Write-Host "Column: " $Column -NoNewline
    Write-Host "Reoprt.Column: " $Report.$Column -NoNewline
    #Write-Host "`t`tIsArray: " $($Column -is [array]) -NoNewline
    #Write-Host "`tType: " $Column.GetType()
}

#foreach( $Column in $($ReportObject | Get-Member -MemberType Property,NoteProperty).Name ){
#    Write-Host "Column: " $Column
#}
Exit