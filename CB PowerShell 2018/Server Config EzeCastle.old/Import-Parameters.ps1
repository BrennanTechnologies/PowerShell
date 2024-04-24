$File = "C:\scripts\Parameters.csv"


$Parameters = Import-CSV -path $File 

Foreach ($Parameter in $Parameters)
{
    $Parameter.Parameter
    $Parameter.Setting
}
