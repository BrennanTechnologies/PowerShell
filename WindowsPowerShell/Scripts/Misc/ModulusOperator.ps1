function Get-ModulusOperator ([int]$count) {
    for($i=1;$i -le $count;$i++) {  
        [PSCustomObject]@{
            Number=$i
            Even = $i % 2  -eq 0
            Odd  = $i % 2  -eq 1
            x3   = $i % 3  -eq 0
            x5   = $i % 5  -eq 0
            x15  = $i % 15 -eq 0
        }
    }
}

Get-ModulusOperator 15 | ft -Auto