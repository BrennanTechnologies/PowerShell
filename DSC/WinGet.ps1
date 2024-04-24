winget settings --list
winget --info

$jaws = winget search jaws

winget search nvda

winget.exe show nvda

winget search 7zip
winget show 7zip

nuget

https://github.com/microsoft/vscode/blob/main/.configurations/configuration.dsc.yaml

https://github.com/microsoft/devhome/blob/main/.configurations/configuration.dsc.yaml

$url = "https://www.7-zip.org/a/7z2301-x64.msi"
wingetcreate new $url

# https://github.com/microsoft/winget-create
winget install wingetcreate