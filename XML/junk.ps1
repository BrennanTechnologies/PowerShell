$SB = {
	[CmdletBinding()]
	param (
		[Parameter()]
		[string]
		$ParameterName
	)
	$DebugPreference = 'Continue'
	$VerbosePreference = 'Continue'
	$srv = Get-Service -Name 'WinRM' -ErrorAction SilentlyContinue
	Write-Debug "WinRM service status: $($srv.Status)"
	Write-verbose "WinRM service status: $($srv.Status)"
}
&$SB