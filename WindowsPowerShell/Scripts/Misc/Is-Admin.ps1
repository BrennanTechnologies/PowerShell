function Is-Admin
{
    param ($User)

    #are we an administrator or LUA?
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [System.Security.Principal.WindowsPrincipal]($User)
    Return $Principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function IsAdmin
{
    $User = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Role = (New-Object Security.Principal.WindowsPrincipal $User).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Return $Role
}