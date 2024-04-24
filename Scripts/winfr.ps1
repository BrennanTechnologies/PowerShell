$path = "C:\Users\brenn\AppData\Local\Microsoft\WindowsApps"

$file = Get-ChildItem -Path "C:\Users\brenn\AppData\Local\Microsoft\WindowsApps\WinFR.exe"
Copy-Item $file.FullName -Destination "C:\Users\brenn\Documents\" -Force