[CmdletBinding()]
param(   
    
    [Parameter(Mandatory = $true)]
    [string]$resourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$automationAccount,

    [Parameter(Mandatory = $true)]
    [int]$instanceNumber,

    [string]$vmPrefix,

    [string]$runbookName,

    [switch]$clean

)

# list the existing HybridrunbookworkerGroup on the automation account that matches our VM prefix
$groupNames = Get-AzureRMAutomationHybridWorkerGroup -ResourceGroupName $resourceGroupName `
    -AutomationAccountName $automationAccount `
    | Where-Object {$_.Name -Match "^$($vmPrefix).*"} `
    | Select-Object -ExpandProperty Name

# check that we have as many HybridrunbookworkerGroups as the expected number of instances, fail if not
if ($groupNames.Count -ne $instanceNumber) {
    Throw "workerGroups and instances number don't match"
}

# list all scheduled job in the automation account for this particular runbook and vm prefix
$scheduleJobIds = Get-AzureRmAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
        -AutomationAccountName $automationAccount -RunBookName $runbookName `
        | Where-Object {$_.ScheduleName -Match "^$($vmPrefix).*"} `
        | Select-Object -ExpandProperty JobScheduleID        


foreach ($scheduleJobId in $scheduleJobIds) {
    if ($Clean) {
        # we need to unregister them and create new ones because we can't overwrite them via ARM template
        Unregister-AzureRmAutomationScheduledRunbook -ResourceGroupName $resourceGroupName `
            -AutomationAccountName $automationAccount `
            -JobScheduleId $scheduleJobId `
            -Force
        Write-host "unregistered : $($scheduleJobId)"   
    }
}

# return the names of the workerGroup as an array
$groupNames