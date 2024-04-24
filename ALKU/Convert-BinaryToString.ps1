<#
https://truesecdev.wordpress.com/2016/03/15/embedding-exe-files-into-powershell-scripts/
#>

function Convert-BinaryToString {
	[CmdletBinding()] param (
		[string] $FilePath = "C:\Windows\WinSxS\wow64_microsoft-windows-robocopy_31bf3856ad364e35_10.0.22621.1635_none_b12e853e9c69d7e3\r\Robocopy.exe"
	)
	try {
		$ByteArray = [System.IO.File]::ReadAllBytes($FilePath);
	}
	catch {
		throw "Failed to read file. Ensure that you have permission to the file, and that the file path is correct.";
	}

	if ($ByteArray) {
		$Base64String = [System.Convert]::ToBase64String($ByteArray);
	}
	else {
 
		throw '$ByteArray is $null.';
	}
	Write-Output -InputObject $Base64String;
}

Convert-BinaryToString