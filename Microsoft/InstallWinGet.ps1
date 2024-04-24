function InstallWinGet 
Christopher Brennan (HCL Technologies Corporate Ser) <v-cbrennan@microsoft.com>
​
You
​
function InstallWinGet {

    $actionTaken = $false

 

    $psInstallScope = "CurrentUser"

    $whoami = whoami.exe

    if ($whoami -eq "nt authority\system") {

        $psInstallScope = "AllUsers"

    }

 

    Write-Host "Installing powershell modules in scope: $psInstallScope"

 

    # check if the Microsoft.Winget.Client module is installed

    if (!(Get-Module -ListAvailable -Name Microsoft.Winget.Client)) {

        Write-Host "Installing Microsoft.Winget.Client"

        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope $psInstallScope

        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

 

        Install-Module Microsoft.WinGet.Client -Scope $psInstallScope

 

        Write-Host "Done Installing Microsoft.Winget.Client"

        $actionTaken = $true

    }

    else {

        Write-Host "Microsoft.Winget.Client is already installed"

    }

 

    # check if the Microsoft.WinGet.Configuration module is installed

    if (!(Get-Module -ListAvailable -Name Microsoft.WinGet.Configuration)) {

        Write-Host "Installing Microsoft.WinGet.Configuration"

        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope $psInstallScope

        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

 

        pwsh.exe -MTA -Command "Install-Module Microsoft.WinGet.Configuration -AllowPrerelease -Scope $psInstallScope"

 

        Write-Host "Done Installing Microsoft.WinGet.Configuration"

        $actionTaken = $true

    }

    else {

        Write-Host "Microsoft.WinGet.Configuration is already installed"

    }

 

    # if scope is CurrentUser, we need to ensure AppInstaller is installed

    if ($psInstallScope -eq "CurrentUser") {

        # we're not running as system, so install Microsoft.DesktopAppInstaller

        if (!(Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue)) {

            Write-Host "Installing Microsoft.DesktopAppInstaller"

            # download the DesktopAppInstaller appx package to $env:TEMP

            $tempFileName = [System.IO.Path]::GetRandomFileName()

            $DesktopAppInstallerAppx = "$env:TEMP\$tempFileName-DesktopAppInstaller.appx"

            try {

                $null = Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile $DesktopAppInstallerAppx

 

                # install the DesktopAppInstaller appx package

                Add-AppxPackage -Path $DesktopAppInstallerAppx -ForceApplicationShutdown

 

                Write-Host "Done Installing Microsoft.DesktopAppInstaller"

                $actionTaken = $true

            }

            catch {

                Write-Error "Failed to install DesktopAppInstaller appx package"

                Write-Error $_

            }

        }

        else {

            Write-Host "Microsoft.DesktopAppInstaller is already installed"

        }

    }

 

    return $actionTaken

}

 

