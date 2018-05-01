# azure-vms-automated-updates

This sample code set up automated patching on Azure VMS.
while there is a few resources online explaining how to do this via arm template deployment.

Phase 1 (arm-vms/wms.arm.json)

This template set up the pre requisite resources :
  - creates an AutomationAccount.
  - creates a LogAnalytics workspace with the OMS Updates solution installed and linked to the automation account.
  - creates a set of Widows VMS, each with the MicrosoftMonitoringAgent linked to the log analytics workspace.

Once the deployment is finished, each VM is now an Hybrid Runbook Worker on the automation account.
The status of windows update rollout for those VMs is now visible on the Azure portal (under AutomationAccount/UpdateManagement) or 
on the OMS portal (under System Update Assessment)

If we want to schedule windows update execution on the VMs, we can do it from both UIs (AutomationAccount and OMS Portal), but 
this doesn't scale. If we redeploy with a greater or smaller number of VMs we have to go back to the UI and modify the schedules 
accordingly.

Implementing the schedules via arm template presents a few challenges :
  - The schedules need to not overlap to ensure availability of whichever service our VMs host. 
  - We don't want all nodes of a same service applying updates (and potentially restarting) at the same time.
  - The schedules need a start date and time that has to be in the future.
  - The Hybrid Runbook Workers are created in  the background durig the deployment and we can't know their IDs from the deployment output.
  - You cannot overwrite the job schedules that are created, they have to be unregistered and the recreated for every deployment
  - A resource of the type jobSchedule has to have a GUID for a name and these have to be unique (can't overwrite)

Before we can deploy our scheduled update job via arm template, we need 3 values that have to be generated outside of a deployment and we need to make sure 
the already existing upate jobs will not interfere with the deployment (they need to be unregistered).

Phase 2 (Powershell)





