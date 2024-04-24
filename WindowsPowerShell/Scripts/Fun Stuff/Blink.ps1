cls
#1..15 | foreach {[system.console]::ForegroundColor = $_; write-host "Warning !!!!`r" -nonewline; sleep 1}

While($true){ 
   1..15 | foreach {[system.console]::ForegroundColor = $_; write-host "Warning !!!!`r" -nonewline; sleep 1}
}

