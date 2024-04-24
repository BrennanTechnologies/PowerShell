###################################################
### ECI.EMI.Automation.Role.Citrix.Dev.ps1
###################################################

&{

    BEGIN 
    {
        Write-Host `n('-' * 50)`n  "Configuring Citrix VDA" `n('-' * 50)`n -ForegroundColor Yellow
        Import-Module ECI.EMI.Automation.Role.Citrix.Dev -DisableNameChecking
    }

    PROCESS
    {
        Install-ECI.XenDesktopVDA 
        Configure-CrossForest
        Install-XenDesktopStudio
    }

    END
    {

    }
}