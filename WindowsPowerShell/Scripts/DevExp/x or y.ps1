
$x = $true
$y = $true
$($x -OR $y) -eq $( !( !($x) -AND !($y) ))

$x = $true
$y = $false
$($x -OR $y) -eq $( !( !($x) -AND !($y) ))

$x = $false
$y = $true
$($x -OR $y) -eq $( !( !($x) -AND !($y) ))

$x = $false
$y = $false
$($x -OR $y) -eq $( !( !($x) -AND !($y) ))