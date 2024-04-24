<#
Test-PsCmdlet> $p


ParameterSetName     : __AllParameterSets
MyInvocation         : System.Management.Automation.InvocationInfo
PagingParameters     : 
InvokeCommand        : System.Management.Automation.CommandInvocationIntrinsics
Host                 : System.Management.Automation.Internal.Host.InternalHost
SessionState         : System.Management.Automation.SessionState
Events               : System.Management.Automation.PSLocalEventManager
JobRepository        : System.Management.Automation.JobRepository
JobManager           : System.Management.Automation.JobManager
InvokeProvider       : System.Management.Automation.ProviderIntrinsics
Stopping             : False
CommandRuntime       : Test-PsCmdlet
CurrentPSTransaction : 
CommandOrigin        : Internal
#>

<#
   TypeName: System.Management.Automation.Internal.Host.InternalHost

Name                   MemberType Definition                                                                                                
----                   ---------- ----------                                                                                                
EnterNestedPrompt      Method     void EnterNestedPrompt()                                                                                  
Equals                 Method     bool Equals(System.Object obj)                                                                            
ExitNestedPrompt       Method     void ExitNestedPrompt()                                                                                   
GetHashCode            Method     int GetHashCode()                                                                                         
GetType                Method     type GetType()                                                                                            
NotifyBeginApplication Method     void NotifyBeginApplication()                                                                             
NotifyEndApplication   Method     void NotifyEndApplication()                                                                               
PopRunspace            Method     void PopRunspace(), void IHostSupportsInteractiveSession.PopRunspace()                                    
PushRunspace           Method     void PushRunspace(runspace runspace), void IHostSupportsInteractiveSession.PushRunspace(runspace runspace)
SetShouldExit          Method     void SetShouldExit(int exitCode)                                                                          
ToString               Method     string ToString()                                                                                         
CurrentCulture         Property   cultureinfo CurrentCulture {get;}                                                                         
CurrentUICulture       Property   cultureinfo CurrentUICulture {get;}                                                                       
DebuggerEnabled        Property   bool DebuggerEnabled {get;set;}                                                                           
InstanceId             Property   guid InstanceId {get;}                                                                                    
IsRunspacePushed       Property   bool IsRunspacePushed {get;}                                                                              
Name                   Property   string Name {get;}                                                                                        
PrivateData            Property   psobject PrivateData {get;}                                                                               
Runspace               Property   runspace Runspace {get;}                                                                                  
UI                     Property   System.Management.Automation.Host.PSHostUserInterface UI {get;} 
#>

function Test-PsCmdlet
{
    [CmdletBinding()]
    param()

    Write-Host -ForegroundColor RED “Interactively explore `$PsCmdlet .  Copied `$PsCmdlet to `$p ”
    Write-Host -ForegroundColor RED ‘Type “Exit” to return’
    $p = $pscmdlet
    function Prompt {“Test-PsCmdlet> “}
    $host.EnterNestedPrompt()
}
Test-PsCmdlet

$p.CurrentProviderLocation(“FileSystem”)