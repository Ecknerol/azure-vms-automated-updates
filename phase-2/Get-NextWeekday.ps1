
param (
    [string] $dayOfWeek = "Sunday"
)


$nextWeekday =$(1..7 | % {$(Get-Date).AddDays($_)} | ? {$_.DayOfWeek -eq $dayOfWeek})
$nextWeekday = $nextWeekday.ToString('yyyy-MM-dd')

$nextWeekday
