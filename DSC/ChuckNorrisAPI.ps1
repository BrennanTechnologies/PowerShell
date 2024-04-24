$apiURL = "https://api.chucknorris.io/jokes/random"
$apiURL2 = "https://api.chucknorris.io/jokes/random?category=dev"
$apiURL3 = "https://api.chucknorris.io/jokes/random?category=movie"
$apiURL4 = "https://api.chucknorris.io/jokes/random?category=food"

$response = Invoke-RestMethod -Uri $apiURL4 -Method Get
$response #.value

$response