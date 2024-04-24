$MainFunction={
   $stepChoice= read-host 'Where would you like to start.'switch($stepChoice)
   {
       1{Step1}
       2{Step2}
       3{Step3}
   }
}
# Steps.ps1 functionStep1{ 
  'Step 1'Step2 
} 
functionStep2{ 
  'Step 2'Step3 
} 
functionStep3{ 
  'Step 3''Done!'}
#This line executes the program& $MainFunction
