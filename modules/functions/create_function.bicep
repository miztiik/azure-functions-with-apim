param deploymentParams object
param funcParams object
param tags object = resourceGroup().tags
param logAnalyticsWorkspaceId string
param enableDiagnostics bool = true

param saName string

// @description('The name of the function app that you wish to create.')
// param appName string = 'fnapp${uniqueString(resourceGroup().id)}'

// Get Storage Account Reference
// Get reference of SA
resource r_sa 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: saName
}

resource r_fnHostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${funcParams.funcNamePrefix}-fnPlan-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  kind: 'linux'
  sku: {
    // https://learn.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-sku-not-available-errors
    name: funcParams.skuName
    tier: funcParams.funcHostingPlanTier
    family: 'Y'
  }
  properties: {
    reserved: true
  }
}

resource r_fnApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${funcParams.funcNamePrefix}-fnApp-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned'
    // type: 'SystemAssigned, UserAssigned'
    //   userAssignedIdentities: {
    //     '${identity.id}': {}
    //   }
  }
  properties: {
    enabled: true
    reserved: true
    serverFarmId: r_fnHostingPlan.id
    clientAffinityEnabled: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.10' //az webapp list-runtimes --linux || az functionapp list-runtimes --os linux -o table
      // ftpsState: 'FtpsOnly'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      // appSettings: [
      //   {
      //     name: 'AzureWebJobsStorage'
      //     value: 'DefaultEndpointsProtocol=https;AccountName=${saName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${r_sa.listKeys().keys[0].value}'
      //   }
      //   {
      //     name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
      //     value: 'DefaultEndpointsProtocol=https;AccountName=${saName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${r_sa.listKeys().keys[0].value}'
      //   }
      //   {
      //     name: 'FUNCTIONS_WORKER_RUNTIME'
      //     value: 'python'
      //   }
      //   {
      //     name: 'FUNCTIONS_EXTENSION_VERSION'
      //     value: '~4'
      //   }
      //   {
      //     name: 'SUBSCRIPTION_ID'
      //     value: subscription().subscriptionId
      //   }
      //   {
      //     name: 'RESOURCE_GROUP'
      //     value: resourceGroup().name
      //   }
      //   // {
      //   //   name: 'WEBSITE_RUN_FROM_PACKAGE'
      //   //   value: 'https://github.com/miztiik/azure-create-functions-with-bicep/raw/main/app/app7.zip'
      //   // }
      //   // {
      //   //   name: 'FUNCTION_APP_EDIT_MODE'
      //   //   value: 'readwrite'
      //   // }
      //   // {
      //   //   name: 'FUNCTIONS_WORKER_RUNTIME'
      //   //   value: funcParams.funcRuntime
      //   // }
      //   // {
      //   //   name: 'dbServer'
      //   //   value: serverName
      //   // }
      //   // {
      //   //   name: 'dbName'
      //   //   value: sqlDBName
      //   // }
      //   // {
      //   //   name: 'dbUsername'
      //   //   value: dbUsername
      //   // }
      //   // {
      //   //   name: 'dbPassword'
      //   //   value: dbPassword
      //   // }
      //   // {
      //   //   name: 'eventhubConnectionString'
      //   //   value: eventhubConnectionString
      //   // }
      //   // {
      //   //   name: 'responsesEHConnectionString'
      //   //   value: responsesEHConnectionString
      //   // }
      //   {
      //     name: 'WEBSITE_CONTENTSHARE'
      //     value: toLower(funcParams.funcNamePrefix)
      //   }
      //   {
      //     name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
      //     value: r_applicationInsights.properties.InstrumentationKey
      //   }
      //   // {
      //   //   name: 'PYTHON_ENABLE_WORKER_EXTENSIONS'
      //   //   value: '0'
      //   // }
      // ]
    }

  }
}

resource r_fnAppSettings 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: r_fnApp
  name: 'appsettings' // Reservered Name
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${saName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${r_sa.listKeys().keys[0].value}'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${saName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${r_sa.listKeys().keys[0].value}'
    WEBSITE_CONTENTSHARE: toLower(funcParams.funcNamePrefix)
    APPINSIGHTS_INSTRUMENTATIONKEY: r_applicationInsights.properties.InstrumentationKey
    FUNCTIONS_WORKER_RUNTIME: 'python'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    SUBSCRIPTION_ID: subscription().subscriptionId
    RESOURCE_GROUP: resourceGroup().name
    DatabaseConnectionString: ''
  }
}


resource r_fn_1 'Microsoft.Web/sites/functions@2022-03-01' = {
  name: '${funcParams.funcNamePrefix}-fn-${deploymentParams.global_uniqueness}'
  parent: r_fnApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'anonymous' // The function is configured to use anonymous authentication (i.e. no function key required), since the Azure Functions infrastructure will verify that the request has come through Front Door.
          methods: [
            'get'
            'post'
          ]
        }
        {
          name: '$return'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      '__init__.py': loadTextContent('../../app/function_code/hello_world/__init__.py')
    }
  }
}

// resource zipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = {
//   parent: r_fnApp
//   name:  any('ZipDeploy')
//   properties: {
//     packageUri: 'https://github.com/miztiik/azure-create-functions-with-bicep/raw/main/app8.zip'
//   }
// }

// module app_service_webjob_msdeploy 'nested/microsoft.web/sites/extensions.bicep' = {
//   name: 'app-service-webjob-msdeploy'
//   params: {
//     appServiceName: dnsNamePrefix
//     webJobZipDeployUrl: azAppServiceWebJobZipUri
//   }
//   dependsOn: [
//     app_service_deploy
//   ]
// }

// Function App Binding
resource r_fnAppBinding 'Microsoft.Web/sites/hostNameBindings@2022-03-01' = {
  parent: r_fnApp
  name: '${r_fnApp.name}.azurewebsites.net'
  properties: {
    siteName: r_fnApp.name
    hostNameType: 'Verified'
  }
}

resource r_applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${funcParams.funcNamePrefix}-fnAppInsights-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Enabling Diagnostics for the Function
resource r_fnLogsToAzureMonitor 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: '${funcParams.funcNamePrefix}-logs-${deploymentParams.global_uniqueness}'
  scope: r_fnApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

/*
#####################################################################################
#                                                                                   #
#                               API Management                                      #
#                                                                                   #
#####################################################################################
*/


// Add API Management to the function

resource r_apiMgmt 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: '${funcParams.funcNamePrefix}-api-${deploymentParams.global_uniqueness}'
  location: deploymentParams.location
  tags: tags
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'miztiik@github'
    publisherName: 'miztiik'
  }
}

resource r_apiMgmt_Logger 'Microsoft.ApiManagement/service/loggers@2019-01-01' = {
  name: r_applicationInsights.name
  parent: r_apiMgmt
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger resources to APIM'
    credentials: {
      instrumentationKey: r_applicationInsights.properties.InstrumentationKey
    }
  }
}

resource r_api_Insights 'Microsoft.ApiManagement/service/diagnostics@2022-08-01' = {
  name: 'applicationinsights' // This is a reserved name
  parent: r_apiMgmt
  properties: {
    loggerId: r_apiMgmt_Logger.id
    alwaysLog: 'allErrors'
    logClientIp: true
    httpCorrelationProtocol: 'W3C'
    verbosity: 'verbose'
    backend: {
      request: {
        body: {
          bytes: 4096
        }
      }
      response: {
        body: {
          bytes: 4096
        }
      }
    }
    sampling: {
      percentage: 89
      samplingType: 'fixed'
    }
  }
}

resource r_apiM_Diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: r_apiMgmt
  // name: 'apiManagementDiagnosticSettings'
  name: '${funcParams.funcNamePrefix}-api-mgmt-diagnostics-${deploymentParams.global_uniqueness}'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated' //https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/resource-logs?WT.mc_id=Portal-Microsoft_Azure_Monitoring#select-the-collection-mode
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


/*
#####################################################################################
#                                                                                   #
#                                         APIs                                      #
#                                                                                   #
#####################################################################################
*/

// Create REST API

param api_1_name string = 'store-events-producer'

resource r_api_1 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  parent: r_apiMgmt
  name: '${api_1_name}-api-${deploymentParams.global_uniqueness}'
  properties: {
    displayName: 'Store Event Producer API'
    apiRevision: '1'
    description: 'Python based store events producer. Check out Github for more details'
    serviceUrl: 'https://github.com/miztiik' //This is the backend URL
    // path: 'producer/store-events'
    path: '${r_fnApp.name}/${r_fn_1.name}'
    isCurrent: true
    subscriptionRequired: false
    protocols: [
      'http'
      'https'
    ]
  }
}

// Add Named key to REST API Management - Allows APIM to call the function
resource r_api_1_KeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2021-12-01-preview' = {
  parent: r_apiMgmt
  name: 'rest-api-function-api-key'
  properties: {
    displayName: 'rest-api-function-api-key'
    secret: true
    value: listkeys('${r_fnApp.id}/host/default', '2016-08-01').masterKey
  }
}


// Add Backend to API
resource r_api_1_backend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  parent: r_apiMgmt
  name: 'store-events-producer-function'
  properties: {
    description: 'Store events producer function app'
    url: 'https://${r_fnApp.name}.azurewebsites.net/api/${r_fn_1.name}'
    // url: 'https://${r_fnApp.properties.hostNames[0]}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}${r_fnApp.id}'
    // resourceId: r_fnApp.id
    credentials: {
      query: {
      }
      header: {
        'x-functions-key': [
          '{{${r_api_1_KeyNamedValue.name}}}'
        ]
      }
    }
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}



// Add Operation to API
resource r_api_1_Get_Operation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  parent: r_api_1
  name: 'GetEventCount'
  properties: {
    displayName: '/default_event_count - Default Events Count'
    method: 'GET'
    // urlTemplate: '/default_event_count'
    urlTemplate: '/'
    description: 'Provides capability to get detailed about a specific deprecation'
    responses: [
      {
        statusCode: 200
        description: 'Success - Payload of Store Events Structure'
        representations: [
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  storeId: 0
                  firstName: 'string'
                  lastName: 'string'
                  loyaltyId: 'string'
                  orderItems: [
                    {
                      productId: 0
                      quantity: 0
                    }
                  ]
                }
              }
            }
            typeName: 'deprecationInfo'
          }
        ]
        headers: []
      }
    ]
  }
}


resource r_api_1_POST_Operation 'Microsoft.ApiManagement/service/apis/operations@2021-12-01-preview' = {
  name: 'post-order'
  parent: r_api_1
  properties: {
    displayName: '/trigger - Initiate Order Generation'
    description: 'Provides ability to request "N-count" of events'
    method: 'POST'
    urlTemplate: '/trigger/{count}'
    templateParameters: [
      {
        name: 'count'
        description: 'The unique ID of the deprecation.'
        type: 'string'
        required: true
        values: []
      }
    ]
    request: {
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                storeId: 0
                firstName: 'string'
                lastName: 'string'
                loyaltyId: 'string'
                orderItems: [
                  {
                    productId: 0
                    quantity: 0
                  }
                ]
              }
            }
          }
        }
        {
          contentType: 'text/json'
          examples: {
            default: {
              value: {
                storeId: 0
                firstName: 'string'
                lastName: 'string'
                loyaltyId: 'string'
                orderItems: [
                  {
                    productId: 0
                    quantity: 0
                  }
                ]
              }
            }
          }
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Success'
      }
    ]
  }
}




// Add Rate Limit Policy to REST API
// resource r_api_1_policy 'Microsoft.ApiManagement/service/apis/policies@2021-01-01-preview' = {
//   parent: r_api_1
//   name: 'policy' // This is a reserved name
//   properties: {
//     format: 'rawxml'
//     // value: replace(loadTextContent('../../app/api_policy/api_policy.xml'),'__ORIGIN__',originUrl)
//     value: loadTextContent('../../app/api_policy/api_policy.xml')
//   }
// }

resource policy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-04-01-preview' = {
  parent: r_api_1_Get_Operation
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><set-backend-service id="apim-generated-policy" backend-id="${r_api_1_backend.name}" /></inbound><backend><forward-request /></backend><outbound /></policies>'
  }
}




// resource r_apiMgmtTemplateProduct 'Microsoft.ApiManagement/service/products@2021-08-01' = {
//   parent: r_apiMgmt
//   name: 'apiMgmtTemplateProduct'
//   properties: {
//     displayName: 'MiztiikUniverse-APIs'
//     description: 'Provide Azure Function endpoints'
//     subscriptionRequired: true
//     approvalRequired: true
//     state: 'published'
//   }
// }

// resource r_apiMgmtTemplateProductApi 'Microsoft.ApiManagement/service/products/apis@2021-08-01' = {
//   parent: r_apiMgmtTemplateProduct
//   name: 'apiMgmtTemplateApi'
//   dependsOn: [
//     r_api_1
//   ]
// }


/*

// Add custom policy to product
resource apimProductPolicy 'Microsoft.ApiManagement/service/products/policies@2019-12-01' = {
  name: '${apimProduct.name}/policy'
  properties: {
    format: 'rawxml'
    value: '<policies><inbound><base /></inbound><backend><base /></backend><outbound><set-header name="Server" exists-action="delete" /><set-header name="X-Powered-By" exists-action="delete" /><set-header name="X-AspNet-Version" exists-action="delete" /><base /></outbound><on-error><base /></on-error></policies>'
  }
}

// Add User
resource apimUser 'Microsoft.ApiManagement/service/users@2019-12-01' = {
  name: '${apim.name}/custom-user'
  properties: {
    firstName: 'Custom'
    lastName: 'User'
    state: 'active'
    email: 'custom-user-email@address.com'
  }
}

// Add Subscription
resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2019-12-01' = {
  name: '${apim.name}/custom-subscription'
  properties: {
    displayName: 'Custom Subscription'
    primaryKey: 'custom-primary-key-${uniqueString(resourceGroup().id)}'
    secondaryKey: 'custom-secondary-key-${uniqueString(resourceGroup().id)}'
    state: 'active'
    scope: '/products/${apimProduct.id}'
  }
}

*/















// APIM Outputs


// Functions Outputs
output fnName string = r_fn_1.name

output fnIdentity string = r_fnApp.identity.principalId


output apiMgmtId string = r_apiMgmt.id
output appInsightsInstrumentationKey string = r_applicationInsights.properties.InstrumentationKey
output apiManagementURL string = r_apiMgmt.properties.portalUrl

output ApiUrl string = r_api_1_Get_Operation.properties.urlTemplate

output myApiUrl1 string = 'https://${reference(resourceId('Microsoft.ApiManagement/service', r_apiMgmt.name)).properties.hostnameConfigurations[0].hostName}/${r_api_1.name}/${r_api_1_Get_Operation.name}'
