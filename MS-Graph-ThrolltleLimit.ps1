###MS-Graph-MaxThrottleLimit.ps1



### Do massive calls to MS Graph API
### ------------------------------------------------------------



$request = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $headers -Method Get

while (request.response.Retry-After -lt 1 ) {


}

Retry-After

foreqach()reeuest in request

if 429 {}


if response = 429 = TooManyRequests {
	$retrYTime = response.Retry-After +1
	Retry-After =  10
}
Retry-After

Do+ { Retry-After }+While+429	
Retry-After: RETRY-Time
{}


function Invoke-MSGraphRequest {
	param (
		[string]$Url,
		[hashtable]$Headers,
		[int]$MaxRetries = 5
	)

	$baseDelay = 1  # Base delay in seconds
	$maxDelay = 60  # Max wait time
	$retries = 0

	while ($retries -lt $MaxRetries) {
		try {
			$response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
			return $response  # Success, return the data
		}
		catch {
			if ($_.Exception.Response.StatusCode.Value__ -eq 429) {
				# Handle throttling
				$retryAfter = $_.Exception.Response.Headers["Retry-After"]

				if ($retryAfter) {
					$delay = [int]$retryAfter
				}
				else {
					$delay = [math]::Min(($baseDelay * [math]::Pow(2, $retries)) + (Get-Random -Minimum 0 -Maximum 1), $maxDelay)
				}

				Write-Host "Throttled! Retrying after $delay seconds..."
				Start-Sleep -Seconds $delay
				$retries++
			}
			else {
				throw $_  # Re-throw non-throttling errors
			}
		}
	}

	throw "Max retries exceeded"
}

# Example usage
$accessToken = "YOUR_ACCESS_TOKEN"
$url = "https://graph.microsoft.com/v1.0/me"
$headers = @{
	"Authorization" = "Bearer $accessToken"
	"Content-Type"  = "application/json"
}

$data = Invoke-MSGraphRequest -Url $url -Headers $headers
$data | ConvertTo-Json -Depth 3
