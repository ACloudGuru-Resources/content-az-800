param location string = resourceGroup().location
param vmUsername string = 'admin_user'
var uniqueString = substring('@LINUX_ACADEMY_UNIQUE_ID', 0, 10 )
var vmPassword = concat(toUpper(uniqueString),uniqueString)

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
      vmSize: 'standard_b1ms'
    }
    osProfile: {
      computerName: 'BRADC1'
      adminUsername: 'admin_user'
      adminPassword: vmPassword
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
      vmSize: 'standard_b1ms'
    }
    osProfile: {
      computerName: 'BRADC2'
      adminUsername: 'admin_user'
      adminPassword: vmPassword
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
