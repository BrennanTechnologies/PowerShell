function funline ($strIN)
{
 $num = $strIN.length
 for($i=1 ; $i -le $num ; $i++)
  { $funline += “=” }
    Write-Host -ForegroundColor yellow $strIN 
    Write-Host -ForegroundColor darkYellow $funline
}