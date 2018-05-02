# azure-vms-automated-updates

This sample code set up automated patching on Azure VMS. While there is a few resources online explaining how to do this on the UI, we want to manage those via arm template deployment.

## Phase 1 : Deploy a set of VMs with Update Management enabled via arm

This template set up the pre requisite resources :
  - creates an AutomationAccount.
  - creates a LogAnalytics workspace with the OMS Updates solution installed and linked to the automation account.
  - creates a set of Widows VMS, each with the MicrosoftMonitoringAgent linked to the log analytics workspace.

  ```powershell
  > Login-AzureRmAccount
  > New-AzureRmResourceGroup -Name "eck-sample-rg" -Location "uksouth"
  > New-AzureRmResourceGroupDeployment -ResourceGroupName "eck-sample-rg" -TemplateFile .\phase-1\vms.arm.json -TemplateParameterFile .\phase-1\vms.params.local.arm.json
  ```

## Phase 2 : Use Powershell to generates the parameters we need

Before we can deploy our scheduled update jobs via arm template we need 3 steps that need to be performed outside of a deployment :
- Generate a timestamp that will be unique to each deployment.
```powershell
> $timeStamp = .\phase-2\Get-UnixTimestamp.ps1
> $timeStamp
1525256370
```
- Generate a date in the future that will be the start date of our schedules (i.e next Sunday).
```powershell
> $startDate = .\phase-2\Get-NextWeekday.ps1 -dayOfWeek "Sunday"
> $startDate
2018-05-06
```
- List the existing Hybrid Runbook Worker Groups that match our VMs and remove the scheduledRunbooks on our schedules that match the runbook (in our case Patch-MicrosoftOMSComputers) if they've been deployed already.
```powershell
> $workerGroups = .\phase-2\Get-HybridRunbookworkerGroup.ps1 -resourceGroupName "eck-sample-rg" -automationAccount "eck-sample-aa" -instanceNumber 2 -vmPrefix "eck-sample-vm" -runbookName "Patch-MicrosoftOMSComputers" -clean
unregistered : 4579a459-660b-5419-8a6e-afa6f4012e95
unregistered : 086eac53-835c-56e8-a73c-fd00bd220334
> $workerGroups
eck-sample-vm_124f24b9-eb34-4384-b9ac-f72e9b3b24cf,eck-sample-vm_41d97d74-b214-48f8-8440-34ad55d8c5b6
```

## Phase 3 : Deploy Schedules and scheduledRunbook via arm

This template deploys 2 resources for each VMs :
 - a schedule that starts after the previous job has finished, for more than 1 VM the schedules will start on the specified day at 01:00, 03:00, 05:0- ... The schedules are set to repeat every week.
 - a scheduledRunbook of Patch-MicrosoftOMSComputers associated with 1 schedule with a specified duration so it doesn't overlap when the next schedule starts.

  ```powershell
  > New-AzureRmResourceGroupDeployment -ResourceGroupName "eck-sample-rg" -TemplateFile .\phase-3\scheduled.updates.arm.json -TemplateParameterFile .\phase-3\scheduled.updates.params.local.arm.json -timeStamp $timeStamp -scheduledUpdateStartDate $startDate -scheduledUpdateWorkerGroups $workerGroups
  ```









