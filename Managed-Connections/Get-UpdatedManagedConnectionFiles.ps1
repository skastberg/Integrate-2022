[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $localSettingsFile,
    [Parameter()]
    [string]
    $destinationFolder = "$PSScriptRoot\.exports",
    [Parameter()]
    [string]
    $prefix,
    [Parameter()]
    [string]
    $vaultName
)

Clear-Host

$settings = Get-Content -Path $localSettingsFile -Encoding utf8 | ConvertFrom-Json -Depth 10

#$settings.values | Out-GridView


Connect-AzAccount -Tenant $settings.values.WORKFLOWS_TENANT_ID | Out-Null
$ctx = Set-AzContext -Subscription $settings.values.WORKFLOWS_SUBSCRIPTION_ID

. "$PSScriptRoot\Generate-Connections.ps1" -resourceGroup $settings.values.WORKFLOWS_RESOURCE_GROUP_NAME -outputLocation "$destinationFolder\$prefix.connections.az.json"
. "$PSScriptRoot\Generate-ConnectionsRaw.ps1" -resourceGroup $settings.values.WORKFLOWS_RESOURCE_GROUP_NAME -outputLocation "$destinationFolder\$prefix.connections.code.json"

$connections = Get-Content -Path "$destinationFolder\$prefix.connections.code.json" -Encoding utf8 | ConvertFrom-Json -Depth 10
$tokens = ""
foreach ($currentConnection in $connections.managedApiConnections.PSObject.Properties) {
    $currentConnection.Name
    $secret = Get-AzKeyVaultSecret -VaultName "$vaultName" -Name "$($currentConnection.Name)-connectionKey" -AsPlainText
    $tokens += ",`"$($currentConnection.Name)-connectionKey`":`"$secret`"`r`n"
}

Set-Content -Path "$destinationFolder\$prefix.connectionkeys.txt" -Value $tokens -Encoding utf8