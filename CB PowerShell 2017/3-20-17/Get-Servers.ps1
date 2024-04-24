$objSearcher = New-Object System.DirectoryServices.DirectorySearcher

$objSearcher.Filter = '(OperatingSystem=Window*Server*)'
"Name","canonicalname","distinguishedname" | Foreach-Object {$null = $objSearcher.PropertiesToLoad.Add($_) }

$objSearcher.FindAll() | Select-Object @{n='Name';e={$_.properties['name']}},@{n='ParentOU';e={$_.properties['distinguishedname'] -replace '^[^,]+,'}},@{n='CanonicalName';e={$_.properties['canonicalname']}},@{n='DN';e={$_.properties['distinguishedname']}}