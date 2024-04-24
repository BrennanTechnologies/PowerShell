$x = Get-Random
$y = Get-Random

Write-Host "x = " $x
Write-Host "y = " $y


if  ( 
        ($x -and $y) -AND ($x -and !$y)  `
            -OR 
        ($x -or $y) -OR ($x -or !$y) ) 
    { Return $True }