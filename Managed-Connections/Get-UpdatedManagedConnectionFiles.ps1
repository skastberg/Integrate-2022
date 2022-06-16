[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $localSettingsFile,
    [Parameter(Mandatory = $False)]
    [string]
    $destinationFolder = "$PSScriptRoot\.exports",
    [Parameter(Mandatory = $true)]
    [string]
    $prefix,
    [Parameter(Mandatory = $true)]
    [string]
    $vaultName
)

Clear-Host

$settings = Get-Content -Path $localSettingsFile -Encoding utf8 | ConvertFrom-Json -Depth 10

#$settings.values | Out-GridView


Connect-AzAccount -Tenant $settings.values.WORKFLOWS_TENANT_ID | Out-Null
$ctx = Set-AzContext -Subscription $settings.values.WORKFLOWS_SUBSCRIPTION_ID

Write-Host "Creating '$prefix.connections.az.json' as the managed connections should look in your release."  -ForegroundColor Cyan
. "$PSScriptRoot\Generate-Connections.ps1" -resourceGroup $settings.values.WORKFLOWS_RESOURCE_GROUP_NAME -outputLocation "$destinationFolder\$prefix.connections.az.json"
Write-Host "`r`nCreating '$prefix.connections.az.json' as the managed connections should look in Visual Studio Code. Copy the contents of the managedConnections element to your connections.json"  -ForegroundColor Cyan
. "$PSScriptRoot\Generate-ConnectionsRaw.ps1" -resourceGroup $settings.values.WORKFLOWS_RESOURCE_GROUP_NAME -outputLocation "$destinationFolder\$prefix.connections.code.json"

$connections = Get-Content -Path "$destinationFolder\$prefix.connections.code.json" -Encoding utf8 | ConvertFrom-Json -Depth 10

Write-Host "`r`nGetting connectionKeys for copying into local.settings.json."  -ForegroundColor Cyan
$tokens = ""
foreach ($currentConnection in $connections.managedApiConnections.PSObject.Properties) {
    $currentConnection.Name
    $tokens += ",`"$($currentConnection.Name)-connectionKey`":`"$secret`"`r`n"
}

Set-Content -Path "$destinationFolder\$prefix.connectionkeys.txt" -Value $tokens -Encoding utf8

Write-Host "`r`nCreating Key vault references for copying into local.settings.json. This should be the preferred approach"  -ForegroundColor Cyan
$kvReference = ""
foreach ($currentConnection in $connections.managedApiConnections.PSObject.Properties) {
    $currentConnection.Name
    $reference = "@Microsoft.KeyVault(VaultName=$vaultName;SecretName=$($currentConnection.Name)-connectionKey)"
    $kvReference += ",`"$($currentConnection.Name)-connectionKey`":`"$reference`"`r`n"
}

Set-Content -Path "$destinationFolder\$prefix.KvReference.txt" -Value $kvReference -Encoding utf8