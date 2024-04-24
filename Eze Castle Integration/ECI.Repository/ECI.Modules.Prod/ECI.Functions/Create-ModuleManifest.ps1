function Create-ModuleManifest
{
    [CmdletBinding()]
    [Alias("cm")]
    
    Param([Parameter(Mandatory = $True)] [string]$ModuleName)

    $ModuleName = $ModuleName
    $Args = @{

    #Path = ""
    RootModule  = "$ModuleName.psm1"
    Author = "Chris Brennan"
    CompanyName = "Eze Castle"
    ModuleVersion = "5.18.18" 
    Description = "Library of Common Functions"
    #PowerShellVersion = ""
    #RequiredModules = ""
    #FileList = ""
    #ModuleList = ""
    #ReleaseNotes = ""
    #ScriptsToProcess = ""
    
    }
    New-ModuleManifest @Args
}