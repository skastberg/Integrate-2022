param(
  [Parameter(Mandatory = $False)]
  [string]
  $location = "westeurope"
)


$subscriptions = az login --only-show-errors | ConvertFrom-Json -Depth 10
$selectedSubscription = $subscriptions | Out-GridView -Title "Select subscription" -PassThru
az account set --subscription $selectedSubscription.id
$tokenObject = az account get-access-token | ConvertFrom-Json -Depth 10
$accessToken = ConvertTo-SecureString $tokenObject.accessToken -Force -AsPlainText
$location = "$location"

$manageApisQuery = "https://management.azure.com/subscriptions/$($selectedSubscription.id)/providers/Microsoft.Web/locations/$location/managedApis?api-version=2016-06-01&"


$api = $null

while ( $null -eq $api -and $null -ne $manageApisQuery) {
    $apis = Invoke-RestMethod -Method Get -Uri $manageApisQuery -Authentication Bearer -Token $accessToken 
    $api = $apis.value | Out-GridView -Title "Select api" -PassThru
    $manageApisQuery = $apis.nextLink  
    if ( $null -eq $api -and $null -eq $manageApisQuery ) {
        Write-Host "Last page reached and no api chosen!" -ForegroundColor Yellow
        exit
    }  
}

$params ="@description('Connection DisplayName')`r`nparam DisplayName string`r`n@description('Location of the connection')`r`nparam Location string = resourceGroup().location`r`nparam connection_name string = '$($api.name)'`r`n"
$envparams = "@description('Environment identifier')`r`n@allowed([`r`n  'lab'`r`n  'dev'`r`n  'test'`r`n  'prod'`r`n])`r`nparam environment string = 'lab'"
$envparams += "`r`n@description('Name of the keyvault for connections')`r`nparam kv_name string`r`n"

$conheader = "`r`ntargetScope = 'resourceGroup'`r`n`r`n"
$conheader += "resource connection_resource 'Microsoft.Web/connections@2016-06-01' = {"
$conheader += "`r`n  name: DisplayName"
$conheader += "`r`n  location: Location"
$conheader += "`r`n  kind: 'V2'"
$conheader += "`r`n  properties: {"
$conheader += "`r`n    displayName: DisplayName"
$paramValues = "`r`nparameterValues: {"
#$api

foreach ($p in $api.properties.connectionParameters.psobject.Properties) {
    $paramType = $p.value.type
    $paramTypeBicep = "" 
    $secStringAttribute = ""
    switch ($paramType) {
        "securestring" {
            $paramTypeBicep = "string"
            $secStringAttribute = "`r`n@secure()"
        }
        "string" {
            $paramTypeBicep = "string"
        }
        "bool" {
            $paramTypeBicep = "bool"
        }
        "int" {
            $paramTypeBicep = "int"
        }
        "array" {
            $paramTypeBicep = "array"
        }
        Default {
            $paramTypeBicep = "object"
        }
    }
    
    $bicepParam = "`r`n@description('$($p.Value.uiDefinition.description).')$secStringAttribute`r`nparam $($p.Name) $paramTypeBicep"
    $paramValues+="`r`n$($p.Name): $($p.Name)"
    $params+= $bicepParam
}
$paramValues+="`r`n}"
$apiElement = "`r`napi: {"
$apiElement += "`r`nname: connection_name"
$apiElement += "`r`ndisplayName: '$($api.properties.generalInformation.displayName)'"
$apiElement += "`r`ndescription: '$($api.properties.generalInformation.description)'"
$apiElement += "`r`niconUri: '$($api.properties.generalInformation.iconUrl)'"
$apiElement += "`r`nbrandColor: '$($api.properties.metadata.brandColor)'"
$apiElement += "`r`nid: '/subscriptions/`${subscription().subscriptionId}/providers/Microsoft.Web/locations/`${Location}/managedApis/$($api.name)'"
$apiElement += "`r`ntype: 'Microsoft.Web/locations/managedApis'"
$apiElement += "`r`n}`r`n}`r`n}"

$conKey = "// Handle connectionKey

param baseTime string = utcNow('u')

var validityTimeSpan ={
  validityTimeSpan:'30'
}

var validTo = dateTimeAdd(baseTime, 'P`${validityTimeSpan.validityTimeSpan}D')

var key = environment == 'lab' || environment == 'dev' ? connection_resource.listConnectionKeys('2018-07-01-preview',validityTimeSpan).connectionKey : 'Skipped'

resource kv  'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: kv_name
}

resource kvConnectionKey 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = if (environment == 'lab' || environment == 'dev') {
  parent: kv
  name: '`${DisplayName}-connectionKey'
  properties: {
    value: key 
    attributes: {
      exp: dateTimeToEpoch(validTo)
    }
  }
}

output ConnectionName string = connection_resource.name
"


$con = "$params`r`n$envparams`r`n$conheader`r`n$paramValues`r`n$apiElement`r`n`r`n$conKey`r`n"
Set-Clipboard $con

$con | Set-Content -Path "$PSScriptRoot\.exports\$($api.name).bicep" 
