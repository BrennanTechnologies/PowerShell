function Generate-RandomAlphaNumeric
{
    Param(
        [Parameter(Mandatory = $False)]
        [int]
        $Length
    )

    if(!$Length){[int]$Length = 15}

    ##ASCII
    #48 -> 57 :: 0 -> 9
    #65 -> 90 :: A -> Z
    #97 -> 122 :: a -> z

    for ($i = 1; $i -lt $Length; $i++) {

        $a = Get-Random -Minimum 1 -Maximum 4 

        switch ($a) 
        {
            1 {$b = Get-Random -Minimum 48 -Maximum 58}
            2 {$b = Get-Random -Minimum 65 -Maximum 91}
            3 {$b = Get-Random -Minimum 97 -Maximum 123}
        }

        [string]$c += [char]$b
    }

    Return $c
}
Generate-RandomAlphaNumeric