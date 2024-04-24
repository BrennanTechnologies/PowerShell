cls


$PSVersion = ((get-host).Version).Major

if ($PSVersion -ge 5)
{
    "Ver 5"
}
if ($PSVersion -lt 5)
{
    "Pre 5"
}