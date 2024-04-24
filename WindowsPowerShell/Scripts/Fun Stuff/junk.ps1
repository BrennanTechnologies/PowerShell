$array = @("a", "b", "c")

for ($i = 0; $i -lt $array.Count; $i++) {
	Write-Host $i $array[$i]
}