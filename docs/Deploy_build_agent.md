# Deploy build agent
 
Now the build agent VM image is built and stored in Azure Storage. The last step is to deploy the agent using Azure DevOps Release Pipeline. The release has 3 jobs:

1. It creates new Azure Virtual Machine from image created by _Build Agent Image_. Additionally it removes other resources in case previous deployment failed.
2. It removes existing build agent from Azure DevOps pool. Then it installs Azure DevOps agent on the new virtual machine.
3. It deletes Azure Virtual Machine running previous build agent.

## Setup release pipeline

1. From menu select **Pipelines** then **Releases**.
2. Click **New release pipeline**.
3. Select **Empty job** (no template).
4. Select **Variables** tab and enter following variables:

| Name                           | Value                                                      | Hidden | Scope   |
|--------------------------------|------------------------------------------------------------|--------|---------|
| Azure.ServicePrincipalObjectId | Value of $spClientId returned by _SetupPacker.ps1_ script. | true   | Release |
| Azure.VirtualMachinePrefix     | Prefix that will be added to VM name. For example, when prefix is _VSBuild1V_, then VM is named VSBuild1V*X*R (X is release number). |        | Release |

![Release variables](images/Deploy_build_agent_Variables.png)

5. Open **Variable groups** and link following variable groups: Azure resources, Build Agent properties, Azure DevOps Account

![Release variable groups](images/Deploy_build_agent_Variable_groups.png)

6. Open **Pipeline** tab.
7. Click **Add artifact**.
8. Set following properties:
    - **Project**: Current Azure DevOps project
    - **Source (build pipeline)**: Build Agent Image
    - **Default version**: Latest
    - **Source alias**: AgentImage
9. Click **Add**.

![Artifact - AgentImage](images/Deploy_build_agent_Artifact_AgentImage.png)

10. Click **Add artifact**.
11. Set following properties:
    - **Project**: Current Azure DevOps project
    - **Source (build pipeline)**: Build Scripts
    - **Default version**: Latest from the build pipeline default branch with tags
    - **Tags**: _empty_
    - **Source alias**: BuildScripts
12. Click **Add**.

![Artifact - BuildScripts](images/Deploy_build_agent_Artifact_BuildScripts.png)

13. Select stage in the release and change name to _Azure DevOps Default Queue_.

![Release stage](images/Deploy_build_agent_Release_stage.png)

14. Open **Tasks** tab.
15. Select first job and set following properties:
    - **Display name**: Create virtual machine
    - **Agent pool**: Default

![Create Virtual Machine job](images/Deploy_build_agent_Create_virtual_machine_job.png)

16. Add task **Azure PowerShell** and set properties:
    - **Display name**: Clean up Azure virtual machines
    - **Azure Connection Type**: Azure Resource Manager
    - **Azure Subscription**: Azure Build
    - **Script Type**: Script File Path
    - **Script Path**: `$(System.DefaultWorkingDirectory)/BuildScripts/deploy/DeleteVMs.ps1`
    - **Script Arguments**: `-RGName "$(Azure.ResourceGroup)" -ExceptVMs @("$(Agent.MachineName)")`
    - **ErrorActionPreference**: Stop
    - **Azure PowerShell Version**: Latest installed version

![Clean up Azure virtual machines](images/Deploy_build_agent_Clean_up_Azure_virtual_machines.png)

17. Add task **Azure PowerShell** and set properties:
    - **Display name**: Create virtual machine
    - **Azure Connection Type**: Azure Resource Manager
    - **Azure Subscription**: Azure Build
    - **Script Type**: Script File Path
    - **Script Path**: `$(System.DefaultWorkingDirectory)/BuildScripts/deploy/CreateVM.ps1`
    - **Script Arguments**: `-RGName "$(Azure.ResourceGroup)" -Location "$(Azure.Location)" -VHDUriFile "$(System.DefaultWorkingDirectory)\AgentImage\image\ImageOutput.txt" -VMName "$(Azure.VirtualMachinePrefix)$(Release.ReleaseId)R" -Username "$(BuildAgent.Username)" -Password "$(BuildAgent.Password)" -ServicePrincipalObjectId "$(Azure.ServicePrincipalObjectId)"`
    - **ErrorActionPreference**: Stop
    - **Azure PowerShell Version**: Latest installed version

![Create virtual machine](images/Deploy_build_agent_Create_virtual_machine.png)

18. At Deployment Process click **Add an agentless job**.

![Add an agentless job](images/Deploy_build_agent_Add_an_agentless_job.png)

19. Set **Display name** to "Wait for virtual machine".

![Wait for virtual machine](images/Deploy_build_agent_Wait_for_virtual_machine.png)

20. Add task **Delay** and set properties:
    - **Display name**: Delay by 2 minutes
    - **Delay time (minutes)**: 2

![Delay by 2 minutes](images/Deploy_build_agent_Delay_by_2_minutes.png)

21. At Deployment Process click **Add an agent job**.

![Add an agent job](images/Deploy_build_agent_Add_an_agent_job.png)

22. Set properties of the job:
    - **Display name**: Install build agent
    - **Agent pool**: Hosted VS2017

![Install build agent job](images/Deploy_build_agent_Install_build_agent_job.png)

23. Add task **PowerShell** and set properties:
    - **Display name**: Delete old build agent
    - **Type**: File Path
    - **Script Path**: `$(System.DefaultWorkingDirectory)/BuildScripts/deploy/DeleteAgent.ps1`
    - **Script Arguments**: `-VstsUrl "$(System.TeamFoundationCollectionUri)" -AuthToken "$(ADOAccount.PAT)" -AgentName "$(Azure.VirtualMachinePrefix)*"`
    - **ErrorActionPreference**: Stop

![Delete old build agent](images/Deploy_build_agent_Delete_old_build_agent.png)

24. Add task **Azure PowerShell** and set properties:
    - **Display name**: Install build agent
    - **Azure Connection Type**: Azure Resource Manager
    - **Azure Subscription**: Azure Build
    - **Script Type**: Script File Path
    - **Script Path**: `$(System.DefaultWorkingDirectory)/BuildScripts/deploy/InstallAgent.ps1`
    - **Script Arguments**: `-RGName "$(Azure.ResourceGroup)" -VMName "$(Azure.VirtualMachinePrefix)$(Release.ReleaseId)R" -Username "$(BuildAgent.Username)" -Password "$(BuildAgent.Password)" -VstsUrl "$(System.TeamFoundationCollectionUri)" -PAT "$(ADOAccount.PAT)" -VSTSAgentUrl "$(ADOAccount.AgentUrl)"`
    - **ErrorActionPreference**: Stop
    - **Azure PowerShell Version**: Latest installed version

![Install build agent](images/Deploy_build_agent_Install_build_agent.png)

25. At Deployment Process click **Add an agentless job**.

![Add an agentless job](images/Deploy_build_agent_Add_an_agentless_job.png)

26. Set **Display name** to "Wait for build agent".

![Wait for virtual machine](images/Deploy_build_agent_Wait_for_virtual_machine.png)

27. Add task **Delay** and set properties:
    - **Display name**: Delay by 2 minutes
    - **Delay time (minutes)**: 2

![Delay by 2 minutes](images/Deploy_build_agent_Delay_by_2_minutes.png)

28. At Deployment Process click **Add an agent job**.

![Add an agent job](images/Deploy_build_agent_Add_an_agent_job.png)

29. Set properties of the job:
    - **Display name**: Delete old virtual machine
    - **Agent pool**: Default

![Delete old virtual machine job](images/Deploy_build_agent_Delete_old_virtual_machine_job.png)

30. Add task **Azure PowerShell** and set properties:
    - **Display name**: Delete old virtual machine
    - **Azure Connection Type**: Azure Resource Manager
    - **Azure Subscription**: Azure Build
    - **Script Type**: Script File Path
    - **Script Path**: `$(System.DefaultWorkingDirectory)/BuildScripts/deploy/DeleteVMs.ps1`
    - **Script Arguments**: `-RGName "$(Azure.ResourceGroup)" -ExceptVMs @("$(Agent.MachineName)")`
    - **ErrorActionPreference**: Stop
    - **Azure PowerShell Version**: Latest installed version

![Delete old virtual machine](images/Deploy_build_agent_Delete_old_virtual_machine.png)

31. **Save** the release pipeline and name it _Azure DevOps Build Agent_.
32. Click **Create a release**. Confirm build versions to use and click **Create**.

After about 30 minutes the release should be finished and you should have your build agent ready.
