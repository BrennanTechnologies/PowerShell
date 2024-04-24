cls

function Do-Something
{
    write-host "Do Something"
}

function Test-ShouldProcess {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param()

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        # Preparation

        if ($PSCmdlet.ShouldProcess("Target","Do-Something")) 
        {
            write-host "No Whatif"
        }

        # Cleanup
    }
    
<#   
    Process {
    # ---  Pre-impact code #--
    
    # -Confirm --> $ConfirmPreference = 'Low'
    
    # ShouldProcess intercepts WhatIf* --> no need to pass it on
    if ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")) 
    {
        Write-Verbose ('[{0}] Reached command' -f $MyInvocation.MyCommand)
        # Variable scope ensures that parent session remains unchanged
        $ConfirmPreference = 'None'
        Do-Something
    }
        
    #--- Post-impact code #---
    
    }
    
  #>  
    
    End {
          Write-Verbose ('[{0}] Confirm={1} ConfirmPreference={2} WhatIf={3} WhatIfPreference={4}' -f $MyInvocation.MyCommand, $Confirm, $ConfirmPreference, $WhatIf, $WhatIfPreference)
      }
}


Test-ShouldProcess -whatif