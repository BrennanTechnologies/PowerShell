
Function Remove-ByForce 
{
     [cmdletbinding(SupportsShouldProcess)] 
     Param([string]$File)

    
 
     If ($PSCmdlet.ShouldContinue("Are you sure that you know what you are doing?","Delete with -Force parameter!")) 
     {  
             write-Host "Deleting File" -ForegroundColor Red
             #Remove-Item $File -Force
     } Else 
     {  
             "Mission aborted!"     
     } 
}

cls
Remove-ByForce test -Confirm