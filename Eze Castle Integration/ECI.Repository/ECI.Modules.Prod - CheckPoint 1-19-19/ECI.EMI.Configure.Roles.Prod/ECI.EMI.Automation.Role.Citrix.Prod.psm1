
###################################################
### ECI.EMI.Automation.Role.Citrix.Dev.psm1
###################################################


function Install-ECI.XenDesktopVDA #<-- Add to Citrix Module
{
    $script:FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 50)`n "Executing Function: " $FunctionName `n('-' * 50) -ForegroundColor Gray

    $Scriptblock =
    {
        $installVDA = Start-Process 'R:\x64\XenDesktop Setup\XenDesktopVDASetup.exe' -ArgumentList '/QUIET /COMPONENTS VDA /EXCLUDE "Personal vDisk" /CONTROLLERS "qts-xendc01.ecicloud.com qts-xendc02.ecicloud.com" /nodesktopexperience /ENABLE_HDX_PORTS /OPTIMIZE /NOREBOOT' -NoNewWindow -PassThru -Wait

        if ($installVDA.exitcode -eq 3)
        {
            Write-Host "VDA component installed correctly, installing Studio next." -BackgroundColor Black
        }#alert that vda component installed correctly
               
        else
        {
            Write-Host -ForegroundColor Yellow "There was a problem installing the VDA component, please use the event viewer and troubleshoot accordingly." -BackgroundColor Black
            Write-Host -ForegroundColor Yellow "Once the errors are resolved please re-run this script" -BackgroundColor Black                       
        } #alert failure
    }
    Try-Catch $Scriptblock
}

function Configure-CrossForest
{

    $script:FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 50)`n "Executing Function: " $FunctionName `n('-' * 50) -ForegroundColor Gray

    #add the cross forest regkey 
    #$testRegValue = Get-ItemProperty 'HKLM:\SOFTWARE\Citrix\Citrix Virtual Desktop Agent' -Name SupportMultipleForest -ErrorAction SilentlyContinue | Out-Null
    #if(!$testRegValue)
    #{
        $Scriptblock =
        {
            New-ItemProperty -Path 'HKLM:\SOFTWARE\Citrix\Citrix Virtual Desktop Agent' -Name "SupportMultipleForest" -Value 1 -PropertyType DWORD -Force | Out-Null
        }
        Try-Catch $Scriptblock
    #}
}

function Install-XenDesktopStudio
{
    $script:FunctionName = $((Get-PSCallStack)[0].Command);Write-Host `n('-' * 50)`n "Executing Function: " $FunctionName `n('-' * 50) -ForegroundColor Gray

        $Scriptblock =
        {
            $installStudio = Start-Process -FilePath 'R:\x64\XenDesktop Setup\XenDesktopServerSetup.exe' -ArgumentList '/Quiet /configure_firewall /components "DESKTOPSTUDIO"' -NoNewWindow -PassThru -Wait

            if($installStudio.exitcode -eq 0)
            {
                Write-Host -ForegroundColor Yellow "Studio component installed correctly." -BackgroundColor Black
                Write-Host -ForegroundColor Yellow "The server will need to be rebooted for the VDA to register with the DDC's." -BackgroundColor Black
                Write-Host -ForegroundColor Yellow "Please email EMSAdmin to create/update the appropriate Delivery Group and Machine Catalog" -BackgroundColor Black
                        
            }#alert that studio component installed correctly
            else
            {
                Write-Host -ForegroundColor Yellow "There was a problem installing the Studio component, please use the event viewer and troubleshoot accordingly." -BackgroundColor Black
                Write-Host -ForegroundColor Yellow "Once the errors are resolved please re-run this script" -BackgroundColor Black                       
            }#alert failure
        }
        Try-Catch $Scriptblock
}

