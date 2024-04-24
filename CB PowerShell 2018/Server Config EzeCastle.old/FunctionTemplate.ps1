### This Function is a Template for all Functions
function Function-Template
{
    BEGIN
    {
        #Remove-Variable -name CustomErrMsg
        $script:FunctionName = $MyInvocation.MyCommand.name #Get the name of the currently executing function
    }

    PROCESS
    {
        $script:CustomErrMsg = "Custom Error Msg: Error with Do-Somthing"
    
        # Setup the scriptblock to execute with the Try/Catch function.
        $ScriptBlock = 
        {

            Do-Something
        
        }

        Try-Catch $ScriptBlock
    }        
    END
    {
        #Remove-Variable -scope local #clear function varables w/ local scope
    }
}
### End Function Template