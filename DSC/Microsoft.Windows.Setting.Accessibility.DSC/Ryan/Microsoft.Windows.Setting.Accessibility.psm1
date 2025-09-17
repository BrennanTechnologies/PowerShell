# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

[DSCResource()]
class TextSize {
	[DscProperty(Key)]
	[string] $Size

	[DscProperty(Mandatory)]
	[string] $Value

	[DscProperty(Mandatory)]
	[string] $Ensure

	[TextSize] Get() {
		return @{
			Size = "Small"
		}
	}
	
	[bool] Test() {
		return $false
	}

	[void] Set() {
	}
}
