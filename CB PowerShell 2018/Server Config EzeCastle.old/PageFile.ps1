cls
$ComputerSystem = $null

    # Disables automatically managed page file setting first
    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -EnableAllPrivileges
    #$ConputerName = 
    $ComputerSystem.Path.Server
    #$ComputerName
    #exit
    if ($ComputerSystem.AutomaticManagedPagefile)
    {
        $ComputerSystem.AutomaticManagedPagefile = $false
        if ($PSCmdlet.ShouldProcess("$($ComputerSystem.Path.Server)", 'Disable automatic managed page file'))
        {
            $ComputerSystem.Put()
        }
    }