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
    $DNSServers = @('10.2.1.2','168.63.129.16')
)
# Set the Error Action Preference
$ErrorActionPreference = 'Stop'

# Configure Logging
$AllUsersDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$LogFile = Join-Path -Path $AllUsersDesktop -ChildPath "$($VM)-Labsetup.log" 

function Write-Log ($Entry, $Path = $LogFile) {
    Add-Content -Path $LogFile -Value "$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString()): $($Entry)" 
} 

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
Write-Log -Entry "VM Creation Start"
try{
    if (-not(Get-VMSwitch -Name "InternalvSwitch" -ErrorAction SilentlyContinue)) {
        Write-Log -Entry "Create Virtual Switch Start"
        New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
        New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix '10.2.1.0/24'
        Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24
        Write-Log -Entry "Create Virtual Switch Success"
    }
} catch {
    Write-Log -Entry "Create Virtual Switch Failed. Please contact Support."
    Exit
}

# Create VHD
try {
    Write-Log -Entry "Create VHD Start"
    New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing
    Write-Log -Entry "Create VHD Success"
} catch {
    Write-Log -Entry "Create VHD Failed. Please contact Support."
    Exit
}

# Download Answer File 
try {
    Write-Log -Entry "Download Answer File Start"
    New-Item -Path "C:\Temp\$($VM)" -ItemType Directory -ErrorAction SilentlyContinue
    $AnswerFilePath = "C:\Temp\$($VM)\unattend.xml"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Implement%20IP%20Address%20Management%20(IPAM)%20on%20Windows%20Server/unattend.xml" -OutFile $AnswerFilePath
    Write-Log -Entry "Download Answer File Success"
}
catch {
    Write-Log -Entry "Download Answer File Failed. Please contact Support."
    Exit
}

# Update Answer File
try {
    Write-Log -Entry "Update Answer File Start"
    # Inject ComputerName into Answer File
    (Get-Content $AnswerFilePath) -Replace '%COMPUTERNAME%', "$($VM)" | Set-Content $AnswerFilePath

    # Inject Password into Answer File
    (Get-Content $AnswerFilePath) -Replace '%LABPASSWORD%', "$($Password)" | Set-Content $AnswerFilePath
    Write-Log -Entry "Update Answer File Success"
}
catch {
    Write-Log -Entry "Update Answer File Failed. Please contact Support."
    Exit
}

# Inject Answer File into VHD
try {
    Write-Log -Entry "Inject Answer File into VHD Start"
    $Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
    New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
    Copy-Item $AnswerFilePath "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"
    Write-Log -Entry "Inject Answer File into VHD Success"
}
catch {
    Write-Log -Entry "Inject Answer File into VHD Failed. Please contact Support."
    Exit
}

# Dismount the VHD
try {
    Write-Log -Entry "Dismount VHD Start"
    Dismount-VHD -Path "C:\Temp\$($VM).vhd"
    Write-Log -Entry "Dismount VHD Success"
}
catch {
    Write-Log -Entry "Dismount VHD Failed. Please contact Support."
    Exit
}

# Create and Start VM
try {
    Write-Log -Entry "Create and Start VM Start"
    # Create Virtual Machine
    New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
    Set-VMProcessor "$($VM)" -Count 2
    Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true

    # Ensure Enhanced Session Mode is enabled on the host and VM
    Set-VMhost -EnableEnhancedSessionMode $true
    Set-VM -VMName "$($VM)" -EnhancedSessionTransportType HvSocket

    # Start the VM
    Start-VM -VMName "$($VM)" 
    Write-Log -Entry "Create and Start VM Success"
}
catch {
    Write-Log -Entry "Create and Start VM Failed. Please contact Support."
    Exit
}

# For all VMs with a Role, wait for the VM to be ready and then configure IP Addressing
Write-Log -Entry "VM Customization Start"

try {

    # Wait for the VM to be ready
    Wait-VMReady -VM $VM
    # Wait for Unattend to run
    Wait-VMPowerShellReady -VM $VM -Credential $Credential 
    # Rename the VM
    Invoke-Command -ScriptBlock {Rename-Computer -NewName $using:VM} -VMName $VM -Credential $Credential

    # Restart VM
    Restart-VM -Name "$($VM)" -Force

    if ($Role -ne 'None') {
        # Generate Credentials
        $SecurePassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
        [pscredential]$Credential = New-Object System.Management.Automation.PSCredential ("Administrator", $SecurePassword)
    
        # Wait for the VM to be ready
        Wait-VMReady -VM $VM
    
        # Wait for Unattend to run
        Wait-VMPowerShellReady -VM $VM -Credential $Credential 
    
        # Configure IP addresssing
        # IP
        Invoke-Command -ScriptBlock {New-NetIPAddress -IPAddress $using:IP -PrefixLength $using:Prefix -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -DefaultGateway $using:DefaultGateway | Out-Null} -VMName $VM -Credential $Credential
        # DNS
        Invoke-Command -ScriptBlock {Set-DnsClientServerAddress -InterfaceAlias (Get-NetIPInterface -InterfaceAlias "*Ethernet*" -AddressFamily IPv4 | Select-Object -Expand InterfaceAlias) -ServerAddresses $using:DNSServers | Out-Null} -VMName $VM -Credential $Credential
    }
    
    # For Member Servers, perform a domain join
    if ($Role -eq 'MemberServer') {
        $DomainJoinUserName = "administrator@$($DomainName)"
        [pscredential]$DomainJoinCredential = New-Object System.Management.Automation.PSCredential ($DomainJoinUserName, $SecurePassword)
        Invoke-Command -ScriptBlock {Add-Computer -Credential $using:DomainJoinCredential -DomainName "$($DomainName)" -Restart -Force} -VMName $VM -Credential $Credential
    }
    
    # For the PDC Role, Deploy the AD DS Role and Promote to a Domain Controller
    if ($Role -eq 'PDC') {
        Invoke-Command -ScriptBlock {$ProgressPreference = "SilentlyContinue"; $WarningPreference = "SilentlyContinue"; Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null} -VMName $VM -Credential $Credential
        Invoke-Command -ScriptBlock {$ProgressPreference = "SilentlyContinue"; $WarningPreference = "SilentlyContinue"; $DSRMPassword = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force; Install-ADDSForest -DomainName $using:DomainName -SafeModeAdministratorPassword $DSRMPassword -DomainNetBIOSName $using:DomainNetBiosName -InstallDns -Force} -VMName $VM -Credential $Credential
    } 

    Write-Log -Entry "VM Customization Success"
} catch {
    Write-Log -Entry "VM Customization Failed. Please contact Support."
    Exit
}

Wait-VMReady -VM $VM

Write-Log -Entry "LAB READY" 