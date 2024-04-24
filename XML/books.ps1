#$booksXML2 = [xml](Get-Content -Path '.\books.xml')
#$booksXML2

[xml]$booksXML = (Get-Content -Path '.\books.xml')
#$booksXML | GM

#$booksXML.SelectNodes("//genre")


#$booksXML.catalog.book | FT

$books = $booksXML.catalog.book
foreach ($book in $books) {
	$book | gm
	#$book.ChildNodes | ForEach-Object {
	#	Write-Host $_.Name ": " $_.InnerText
	#}
	<#
	Write-Host "Title: " $book.title
	Write-Host "Author: " $book.author
	Write-Host "Year: " $book.year
	Write-Host "Price: " $book.price
	Write-Host "Genre: " $book.genre
	Write-Host "Description: " $book.description
	Write-Host "-----------------------------------"
	#>
}

exit

$booksXML.SelectNodes("//genre") | ForEach-Object {
	Write-Host "Name: " $_.Name
	Write-Host "InnerText: " $_.InnerText
}
