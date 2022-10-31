param location string = resourceGroup().location
param vmUsername string = 'admin_user'
@secure()
param vmPassword string = '${substring(toUpper(uniqueString(resourceGroup().location)),0,4)}${substring(uniqueString(resourceGroup().location),0,4)}'

resource vnetbarrierreef 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-barrierreef'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'identity-subnet'
        properties:{
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgdefault.id
          }
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        '10.0.0.5'
        '168.63.129.16'
      ]
    }
  }
}

resource nsgdefault 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-default'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAnyRDPInbound'
        properties: {
          description: 'Allow inbound RDP traffic from all VMs to Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}
//BRADC1
resource BRADC1PIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'BRADC1-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource BRADC1NIC1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'BRADC1-NIC1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'BRADC1-NIC1-IPConfig1'
              properties: {
                privateIPAllocationMethod: 'Static'
                privateIPAddress: '10.0.0.5'
                publicIPAddress: {
                  id: BRADC1PIP.id
                }
                subnet: {
                  id: vnetbarrierreef.properties.subnets[0].id
                }
              }
            }
          ]
  }
}

resource BRADC1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'BRADC1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'BRADC1'
      adminUsername: 'admin_user'
      adminPassword: 'CF2ndIXS2bj6XTtz'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'BRADC1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BRADC1NIC1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource BRADC1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: BRADC1
  name: 'BRADC1-CSE'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Update%20Management%20using%20Azure%20Automation/BRADC1.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File BRADC1.ps1 -Password "CF2ndIXS2bj6XTtz"'
    }
  }
}

//BRADC2
resource BRADC2PIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'BRADC2-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource BRADC2NIC1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'BRADC2-NIC1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'BRADC2-NIC1-IPConfig1'
              properties: {
                privateIPAllocationMethod: 'Static'
                privateIPAddress: '10.0.0.6'
                publicIPAddress: {
                  id: BRADC2PIP.id
                }
                subnet: {
                  id: vnetbarrierreef.properties.subnets[0].id
                }
              }
            }
          ]
  }
}

resource BRADC2 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'BRADC2'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'BRADC2'
      adminUsername: 'admin_user'
      adminPassword: 'CF2ndIXS2bj6XTtz'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'BRADC2-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BRADC2NIC1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource BRADC2CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: BRADC2
  name: 'BRADC2-CSE'
  dependsOn: [
    BRADC1CSE
  ]
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Update%20Management%20using%20Azure%20Automation/BRADC2.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File BRADC2.ps1 -Password "CF2ndIXS2bj6XTtz"'
    }
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2019-06-01' = {
  name: 'aa-automation-prod-001'
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'law-monitoring-prod-001'
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
  }
}

resource linkedWorkspace 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  name: 'Automation'
  parent: logAnalyticsWorkspace
  properties: {
    resourceId: automationAccount.id
  }
}

resource logAnalyticsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Updates(${logAnalyticsWorkspace.name})'
  location: location
  dependsOn: [
    linkedWorkspace
  ]
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'Updates(${logAnalyticsWorkspace.name})'
    product: 'OMSGallery/Updates'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}
