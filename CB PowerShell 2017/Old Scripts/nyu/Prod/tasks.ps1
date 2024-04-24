$schedule = new-object -com("Schedule.Service") 
$schedule.connect() 
$tasks = $schedule.getfolder("\").gettasks(0)

$tasks | select Name,TaskName,Principal,Author,Description,Enabled,LastRunTime


foreach ($t in $tasks)
{
foreach ($a in $t.Actions)
{
    $a.Path
}
}