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
      {
        name: 'workstation-subnet'
        properties:{
          addressPrefix: '10.0.1.0/24'
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
        ''
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File BRADC1.ps1 -Password "CF2ndIXS2bj6XTtz"'
    }
  }
}

//BRAWKS1
resource BRAWKS1PIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'BRAWKS1-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource BRAWKS1NIC1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'BRAWKS1-NIC1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'BRAWKS1-NIC1-IPConfig1'
              properties: {
                privateIPAllocationMethod: 'Static'
                privateIPAddress: '10.0.1.5'
                publicIPAddress: {
                  id: BRAWKS1PIP.id
                }
                subnet: {
                  id: vnetbarrierreef.properties.subnets[1].id
                }
              }
            }
          ]
  }
}

resource BRAWKS1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'BRAWKS1'
  dependsOn: [
    BRADC1CSE
  ]
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'BRAWKS1'
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
        name: 'BRAWKS1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BRAWKS1NIC1.id
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

resource BRAWKS1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: BRAWKS1
  name: 'BRAWKS1-CSE'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        ''
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File BRAWKS1.ps1 -Password "CF2ndIXS2bj6XTtz"'
    }
  }
}
