var location  = resourceGroup().location
var vmUsername  = 'admin_user'
var uniqueString = substring('@LINUX_ACADEMY_UNIQUE_ID', 0, 10 )
var vmPassword = concat(toUpper(uniqueString),uniqueString)
var customImageDefinitionName =  'Win2022_Eval_VHD'
var customImageResourceId = resourceId('07089ab1-6f34-49b2-9cad-f1a654494a69', 'LACustomImagesRG', 'Microsoft.Compute/galleries/images/versions', 'LAImagesGallery', customImageDefinitionName, 'latest')

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
        name: 'server-subnet'
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
//BRAHV1
resource BRAHV1PIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'BRAHV1-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource BRAHV1NIC1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'BRAHV1-NIC1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'BRAHV1-NIC1-IPConfig1'
              properties: {
                privateIPAllocationMethod: 'Static'
                privateIPAddress: '10.0.0.5'
                publicIPAddress: {
                  id: BRAHV1PIP.id
                }
                subnet: {
                  id: vnetbarrierreef.properties.subnets[0].id
                }
              }
            }
          ]
  }
}

resource BRAHV1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'BRAHV1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'standard_d2s_v3'
    }
    osProfile: {
      computerName: 'BRAHV1'
      adminUsername: vmUsername
      adminPassword: vmPassword
    }
    storageProfile: {
      imageReference: {
        id: customImageResourceId
      }
      osDisk: {
        name: 'BRAHV1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: BRAHV1NIC1.id
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

resource BRAHV1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: BRAHV1
  name: 'BRAHV1-CSE'
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
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File BRAHV1.ps1 -Password "${vmPassword}"'
    }
  }
}
