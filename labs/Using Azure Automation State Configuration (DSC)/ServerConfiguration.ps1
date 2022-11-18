configuration ServerConfiguration {
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -ModuleName DnsServerDsc
    Import-DscResource -ModuleName  StorageDsc

    node ("BRADC1")
    {
        WaitForDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount = 60
        }

        Disk SVolume
        {
            DiskId = 2
            DriveLetter = 'S'
            Size = 9GB
            
            DependsOn = '[WaitForDisk]Disk2'
        }

        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain 'NewForest'
        {
            DomainName                    = "$(Get-AutomationVariable -Name 'DomainName')"
            Credential                    = (Get-AutomationPSCredential -Name 'ServerAdmin')
            SafemodeAdministratorPassword = (Get-AutomationPSCredential -Name 'DSRMPassword')
            ForestMode                    = 'WinThreshold'
            DatabasePath                  = 'S:\NTDS'
            LogPath                       = 'S:\NTDS'
            SysvolPath                    = 'S:\SYSVOL'

            DependsOn = '[Disk]SVolume'
        }

        DnsServerForwarder 'SetForwarders'
        {
            IsSingleInstance = 'Yes'
            IPAddresses      = @('168.63.129.16')
            UseRootHint      = $true

            DependsOn = '[ADDomain]NewForest'
        }
    }

    node ("BRADC2")
    {
        WaitForDisk Disk2
        {
            DiskId = 2
            RetryIntervalSec = 60
            RetryCount = 60
        }

        Disk SVolume
        {
            DiskId = 2
            DriveLetter = 'S'
            Size = 9GB
            
            DependsOn = '[WaitForDisk]Disk2'
        }

        WindowsFeature 'InstallADDomainServicesFeature'
        {
            Ensure = 'Present'
            Name   = 'AD-Domain-Services'
        }

        WindowsFeature 'RSATADPowerShell'
        {
            Ensure    = 'Present'
            Name      = 'RSAT-AD-PowerShell'

            DependsOn = '[WindowsFeature]InstallADDomainServicesFeature'
        }

        WaitForADDomain 'WaitForDomain'
        {
            DomainName = "$(Get-AutomationVariable -Name 'DomainName')"
            Credential = $(Get-AutomationPSCredential -Name 'EnterpriseAdmin')

            DependsOn  = '[WindowsFeature]RSATADPowerShell'
        }

        ADDomainController 'ReplicaDomainController'
        {
            DomainName                    = "$(Get-AutomationVariable -Name 'DomainName')"
            Credential                    = $(Get-AutomationPSCredential -Name 'EnterpriseAdmin')
            SafeModeAdministratorPassword = (Get-AutomationPSCredential -Name 'DSRMPassword')
            IsGlobalCatalog               = $true
            DatabasePath                  = 'S:\NTDS'
            LogPath                       = 'S:\NTDS'
            SysvolPath                    = 'S:\SYSVOL'

            DependsOn                     = @('[WaitForADDomain]WaitForDomain','[Disk]SVolume')
        }

        DnsServerForwarder 'SetForwarders'
        {
            IsSingleInstance = 'Yes'
            IPAddresses      = @('168.63.129.16')
            UseRootHint      = $true

            DependsOn = '[ADDomainController]ReplicaDomainController'
        }

    }
}