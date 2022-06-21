# Make sure you have connected your Azure account and set context to the subscription you want to use:
# 1) Connect-AzAccount
# 2) Set-AzContext -Subscription <subscription-id-here>

<#
    .SYNOPSIS
        Generate a connections json file using API connections already deployed to a resource group.

    .PARAMETER resourceGroup
        The name of the resource group that contains the API connectors.

    .PARAMETER outputLocation
    The path to store the updated connections json file. Defaults to connections.json in the local directory.

    .PARAMETER withFunctions
    A flag to include Azure Functions in the connection file.

    .EXAMPLE
        Generates a connections json file.

        ./Generate-Connections.ps1Adv -resourceGroup rg-api-connections -outputLocation connections.json

        Use this if you want to include function connectors
        ./Generate-ConnectionsAdv.ps1 -resourceGroup rg-api-connections -outputLocation connections.json -withFunctions
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroup,
    [Parameter(Mandatory = $True)]
    [string]
    $connectionsDeployFile
)


$outputLocation = "$PSScriptRoot\temp.connections.json"
. "$PSScriptRoot\Generate-Connections.ps1" -resourceGroup $resourceGroup -outputLocation $outputLocation 

$connectionsDeploy = Get-Content -Path $connectionsDeployFile -Encoding utf8 | ConvertFrom-Json -Depth 10
$connections = Get-Content -Path $outputLocation -Encoding utf8 | ConvertFrom-Json -Depth 10
$connectionsDeploy.managedApiConnections = $connections.managedApiConnections
$connectionsToDeploy = $connectionsDeploy | ConvertTo-Json -Depth 10
$connectionsToDeploy | Set-Content -Path $connectionsDeployFile -Encoding utf8



