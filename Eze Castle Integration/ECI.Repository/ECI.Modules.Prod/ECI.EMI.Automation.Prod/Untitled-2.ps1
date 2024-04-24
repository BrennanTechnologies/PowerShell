<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER Site
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function test {
    Param(
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string]$Site
    )
}

