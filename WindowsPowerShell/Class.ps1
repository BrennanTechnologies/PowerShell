Class Car {
    [string]$Vin
    [string]$Make
    [string]$Model
    [string]$Color
    static [int]$NumofWheels = 4
    [int16]$NumofDoors
}

$myCar = New-Object Car


$myCar.Model = "Camero"

$myCar | gm

#$myCar::NumofWheels
#$myCar::Model



$FName = "Chris"
$LName = "Brennan"
$H = "Hello {0} {1} !" -f $FName, $LName
$H

# ternary 
1 -gt 2 ? "Yes" : "No"