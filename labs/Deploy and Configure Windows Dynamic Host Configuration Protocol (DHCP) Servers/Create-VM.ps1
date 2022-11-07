param(
    $UserName = 'admin_user',
    $Password,
    $VM
)
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

#Download and Inject Answer File
$Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
Copy-Item $AnswerFilePath "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

#Dismount the VHD
Dismount-VHD -Path "C:\Temp\$($VM).vhd"

# Create Virtual Machine
New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
Set-VMProcessor "$($VM)" -Count 2
Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true

# Ensure Enhanced Session Mode is enabled on the host and VM
Set-VMhost -EnableEnhancedSessionMode $true
Set-VM -VMName "$($VM)" -EnhancedSessionTransportType HvSocket

# Start the VM
Start-VM -VMName "$($VM)" 
