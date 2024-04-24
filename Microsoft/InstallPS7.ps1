InstallPS7
Christopher Brennan (HCL Technologies Corporate Ser) <v-cbrennan@microsoft.com>
​
You
​
function InstallPS7 {

    if (!(Get-Command pwsh -ErrorAction SilentlyContinue)) {

        Write-Host "Installing PowerShell 7"

        $code = Invoke-RestMethod -Uri https://aka.ms/install-powershell.ps1

        $null = New-Item -Path function:Install-PowerShell -Value $code

        WithRetry -ScriptBlock {

            Install-PowerShell -UseMSI -Quiet

        } -Maximum 5 -Delay 100

        # Need to update the path post install

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        Write-Host "Done Installing PowerShell 7"

    }

    else {

        Write-Host "PowerShell 7 is already installed"

    }

}

 

