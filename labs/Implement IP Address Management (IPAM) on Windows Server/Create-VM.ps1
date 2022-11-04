param(
    $UserName = 'admin_user',
    $Password,
    $VM,
    [ValidateSet("PDC","None","MemberServer")]
    [string]$Role = 'None',
    $DomainName = 'corp.barrierreefaudio.com',
    $DomainNetBiosName = 'CORP',
    $IP = '10.2.1.2',
    $Prefix = '24',
    $DefaultGateway = '10.2.1.1',
    $DNSServers = '168.63.129.16'
)
function Wait-VMReady ($VM)
{
    while ((Get-VM $VM | Select-Object -ExpandProperty Heartbeat) -notlike "Ok*") {
        Start-Sleep -Seconds 1
    }
}
function Wait-VMPowerShellReady ($VM, $Credential)
{
    while (-not (Invoke-Command -ScriptBlock {Get-ComputerInfo} -VMName $VM -Credential $Credential -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 1
    }
} 


# Import Hyper-V Module
Import-Module Hyper-V

# Create NAT Virtual Switch
if (-not(Get-VMSwitch -Name "InternalvSwitch" -ErrorAction SilentlyContinue)) {
    New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
    New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix '10.2.1.0/24'
    Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24
} 

# Create VHD
New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing

# Download Answer File 
New-Item -Path "C:\Temp\$($VM)" -ItemType Directory -ErrorAction SilentlyContinue
$AnswerFilePath = "C:\Temp\$($VM)\unattend.xml"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Deploy%20and%20Configure%20Windows%20Dynamic%20Host%20Configuration%20Protocol%20(DHCP)%20Servers/unattend.xml" -OutFile $AnswerFilePath

# Inject ComputerName into Answer File
(Get-Content $AnswerFilePath) -Replace '%COMPUTERNAME%', "$($VM)" | Set-Content $AnswerFilePath

# Inject Password into Answer File
(Get-Content $AnswerFilePath) -Replace '%LABPASSWORD%', "$($Password)" | Set-Content $AnswerFilePath

# Download and Inject Answer File
$Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
Copy-Item $AnswerFilePath "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

# Dismount the VHD
Dismount-VHD -Path "C:\Temp\$($VM).vhd"

# Create Virtual Machine
New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
Set-VMProcessor "$($VM)" -Count 2
Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true

# Start the VM
Start-VM -VMName "$($VM)" 

# For all VMs with a Role, wait for the VM to be ready and then configure IP Addressing
if ($Role -ne 'None') {
    # Generate Credentials
    $SecurePassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
    [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)

    # Wait for the VM to be ready
    Wait-VMReady -VMName $VM

    # Wait for Unattend to run
    Wait-VMPowerShellReady -VMName $VM -Credential $Credential 

    # Configure IP addresssing
    # IP
    Invoke-Command -ScriptBlock {New-NetIPAddress -IPAddress $using:IP -PrefixLength $using:Prefix -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -DefaultGateway $using:DefaultGateway | Out-Null} -VMName $VM -Credential $Credential
    # DNS
    Invoke-Command -ScriptBlock {Set-DnsClientServerAddress -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -ServerAddresses $using:DNSServers | Out-Null} -VMName $VM -Credential $Credential
}

# For Member Servers, perform a domain join
if ($Role -eq 'MemberServer') {
    $DomainJoinUserName = "$($UserName)@$($DomainName)"
    [pscredential]$DomainJoinCredential = New-Object System.Management.Automation.PSCredential ($DomainJoinUserName, $SecurePassword)
    Invoke-Command -ScriptBlock {Add-Computer -Credential $using:DomainJoinCredential -DomainName "$($DomainName)" -Restart -Force} -VMName $VM -Credential $Credential
}

# For the PDC Role, Deploy the AD DS Role and Promote to a Domain Controller
if ($Role -eq 'PDC') {
    Invoke-Command -ScriptBlock {Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null} -VMName $VM -Credential $Credential
    Invoke-Command -ScriptBlock {$DSRMPassword = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force; Install-ADDSForest -DomainName $using:DomainName -SafeModeAdministratorPassword $DSRMPassword -DomainNetBIOSName $using:DomainNetBiosName -InstallDns -Force} -VMName $VM -Credential $Credential
}