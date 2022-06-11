

**Get-ConnectorBicep.ps1** 

Will generate a bicep files under _.exports_ folder named after the chosen connector. 

> **Note** The output folder **.exports** is added to _.gitignore_.

Known issues:

- Object parameters are not handled correctly
- Non-string parameters are sometimes expected as strings in the parameterValues section.

