function Connect-ToEPMAutomate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]
        $EPM_UserId
        ,
        [Parameter(Mandatory=$true)]
        [String]
        $EPM_UserPw
        ,
        [Parameter(Mandatory=$true)]
        [String]
        $EPM_URL
    )
    ####################################################################################
    ### LOG IN TO EPMAUTOMATE
    ####################################################################################
    
    try{
        $CmdLine = "login $EPM_UserId $EPM_UserPw $EPM_URL"
        $ReturnCode = Start-Process "$EPMAutomate_Path\epmautomate.bat" $CmdLine -Wait -passthru -WindowStyle $ShowDosWindow
        Write-Log "Login $($ReturnCode.ExitCode)"
    } catch {
        Write-Log $Error[0].Exception.Message
    }

    if( $ReturnResult -eq 1){
        Send_Email_Error
        Exit
    }

}

