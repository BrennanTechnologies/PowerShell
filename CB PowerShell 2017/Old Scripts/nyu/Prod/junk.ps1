cls
#Get-ScheduledTask | get-member

$Tasks = Get-ScheduledTask | Select *
#Get-ScheduledTaskInfo

foreach ($task in $tasks)
{

    $task.TaskName
    $task.Principal
    
}


<#

Name                      MemberType     Definition                                                                                                    
----                      ----------     ----------                                                                                                    
Clone                     Method         System.Object ICloneable.Clone()                                                                              
Dispose                   Method         void Dispose(), void IDisposable.Dispose()                                                                    
Equals                    Method         bool Equals(System.Object obj)                                                                                
GetCimSessionComputerName Method         string GetCimSessionComputerName()                                                                            
GetCimSessionInstanceId   Method         guid GetCimSessionInstanceId()                                                                                
GetHashCode               Method         int GetHashCode()                                                                                             
GetObjectData             Method         void GetObjectData(System.Runtime.Serialization.SerializationInfo info, System.Runtime.Serialization.Stream...
GetType                   Method         type GetType()                                                                                                
ToString                  Method         string ToString()                                                                                             
Actions                   Property       CimInstance#InstanceArray Actions {get;set;}                                                                  
Author                    Property       string Author {get;set;}                                                                                      
Date                      Property       string Date {get;set;}                                                                                        
Description               Property       string Description {get;set;}                                                                                 
Documentation             Property       string Documentation {get;set;}                                                                               
Principal                 Property       CimInstance#Instance Principal {get;set;}                                                                     
PSComputerName            Property       string PSComputerName {get;}                                                                                  
SecurityDescriptor        Property       string SecurityDescriptor {get;set;}                                                                          
Settings                  Property       CimInstance#Instance Settings {get;set;}                                                                      
Source                    Property       string Source {get;set;}                                                                                      
TaskName                  Property       string TaskName {get;}                                                                                        
TaskPath                  Property       string TaskPath {get;}                                                                                        
Triggers                  Property       CimInstance#InstanceArray Triggers {get;set;}                                                                 
URI                       Property       string URI {get;}                                                                                             
Version                   Property       string Version {get;set;}                                                                                     
State                     ScriptProperty System.Object State {get

#>