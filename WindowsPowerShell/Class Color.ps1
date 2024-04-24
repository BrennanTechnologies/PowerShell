class myColor
{
    [string]$Color
    [string]$Hex

    myColor( [string]$Color, [string]$Hex)
    {
        $this.Color = $Color
        $this.Hex = $Hex
    }

    [string]ToString()
    {
        return $this.Color + ":" + $this.Hex
    }
}

$Red = [myColor]::New("Red","#FF0000")
$Red