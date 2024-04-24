

&{

    BEGIN {
    
        $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray 
        Write-Host "BEGIN: - InGuest"  (Get-PSCallStack)[1].Command -ForegroundColor Magenta   
    }

    PROCESS {
    
        $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray 
        Write-Host "PROCESS: - InGuest"  (Get-PSCallStack)[1].Command -ForegroundColor Magenta   


        #################################
        ### Configure OS
        #################################
        
        AST.Automation.Set.ExecutionPolicyonVMGuest -VMName $VMName
        
        AST.Automation.Rename-LocalComputer -Domain $domain -ServerName $serverName -OUPath $oUPath
        AST.Automaion.Join-Domain -Domain $domain
        AST.Automation.Activate-OSLicense

        #################################
        ### Install/Configure Software
        #################################
        AST.Automaion.Install-Patches
        AST.Automaion.Install-Symantec
        AST.Automaion.Install-Lumension
        AST.Automaion.Install-IPMonitor
        
        #################################
        ### Verify
        #################################

        AST.Automaion.Verify-Patches
        AST.Automaion.Lumension
        AST.Automaion.Symantec
        

        AST.Automaion.Send-Notification

    }

    END {
        
        $functionName = $MyInvocation.MyCommand; Write-Host `r`n ("=" * 75)`r`n " EXECUTING FUNCTION: " $functionName `n`r ("=" * 75) -ForegroundColor DarkGray  
        Write-Host "END: - InGues"  (Get-PSCallStack)[1].Command -ForegroundColor Magenta  
    
    }

}