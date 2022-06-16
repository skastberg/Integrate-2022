

**Get-ConnectorBicep.ps1** 

Will generate a bicep files under _.exports_ folder named after the chosen connector. 

> **Note** The output folder **.exports** is added to _.gitignore_.

Known issues:

- Object parameters are not handled correctly
- Non-string parameters are sometimes expected as strings in the parameterValues section.


**Get-UpdatedManagedConnectionFiles.ps1**

Will generate files containing Connection information based on the connections in a provided resource group to use in Visual Studio Code.

>Assumes you have generated the connections with **Get-ConnectorBicep.ps1** and have stored the connectionkey in KeyVault. 

Calls **Generate-ConnectionsRaw.ps1** and **Generate-Connections.ps1** and saves the files in a folder you provide. See the table below for details on the saved files.


| File                            | Description                                                                                                                                          |
| :------------------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| \<prefix>.connections.az.json   | Shows how the managed connections should look in should look in the deployment.                                                                      |
| \<prefix>.connections.code.json | Shows how the managed connections should look in Visual Studio Code. Copy the contents of the managedApiConnections element to your connections.json |
| \<prefix>.connectionKeys.txt | Lines you can use in your local.settings.json to match the connection information created in \<prefix>.connections.code.json. Here we have to connectionKeys as when created the normal way in VS Code.  |
| \<prefix>.KvReference.txt | Lines you can in your local.settings.json to match the connection information created in  \<prefix>.connections.code.json. Here we use Key vault references instead which is the best solution as you don't need to update the local.settings.json when the keys are updated.  |


![Output example](OutputExample.jpg)

**Generate-ConnectionsAdv.ps1**

Used in the Azure DevOps pipeline to generate a connections.json to use when deploying. Calls **Generate-Connections.ps1**. The keys can be copied to your local.settings.json.
If the key have expired do a new release with the bicep files and the keys will be updated in KeyVault.

>**Note** The script **Generate-Connections.ps1** is a copy from here https://github.com/Azure/logicapps/blob/master/azure-devops-sample/.pipelines/scripts/Generate-Connections.ps1

