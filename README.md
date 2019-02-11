# Overview

This article and set of scripts can help you setup fully automated deployment of [Azure DevOps](https://azure.microsoft.com/en-us/solutions/devops/) build agents. It explains step-by-step instructions, how to setup automated deployment of [self-hosted agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops#install) using [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops).

[VSTS/TFS automated build agent provisioning](https://www.betterask.erni/news-room/vsts-tfs-automated-build-agent-provisioning/)

# Problem

Setup and maintenance of build agents may be a daunting task. It requires configuration of Windows OS, installation of different development tools (like Visual Studio), etc. And then, when it is done, from time to time it is required to update the software, or install a new one, or install security patches. This may be very time consuming.

# Solution

## Very easy solution

Microsoft provides [Microsoft hosted agents](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/hosted?view=azure-devops&tabs=yaml) with different configurations. These agents are ready to use. Microsoft is simply doing all the hard work for you.

## Custom solution

There might be situations, when it's not possible to use Microsoft hosted agents. For example:

- Custom software or special configuration is required on the agent.
- Agent must be in Azure Virtual Network to have access to specific resources or VPN.
- Agent must have pre-installed certification keys. (bad practice)
- Your product must comply with regulations of complete reproducibility. It means that every build of your software must be reproducible by using exactly same version of tools, operating system and patches. This is not possible with Microsoft hosted agents, because they are upgraded every month.

In such case, you have to maintain your self-hosted agent by yourself. And this is what you need:

1. Azure DevOps organization - I assume, you already have this, and therefore you need build agent.
2. Azure subscription - This article helps you deploy agent in Microsoft Azure. If you want to use different cloud provider or own datacenter you may use some scripts from here, but some parts must be implemented by yourself.

And these are tasks to setup automated deployment of self-hosted build agent.

1. [Setup Azure Resource Group](docs/Setup_Azure_Resource_Group.md)
2. [Setup Azure DevOps project](docs/Setup_Azure_DevOps_project.md)
3. [Create build agent image](docs/Create_build_agent_image.md)
4. [Deploy build agent](docs/Deploy_build_agent.md)
