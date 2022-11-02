param(
    $UserName = 'admin_user',
    $Password,
    $VMName
)
# Create NAT Virtual Switch
Import-Module Hyper-V
New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix “10.2.1.0/24”
Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24

# Create VHD
$VM = "BRAVM1"
New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "D:\Temp\$($VM).vhd" -Differencing

# Download Answer File 
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Hyper-V%20Switch-Embedded%20Teaming/unattend.xml" -OutFile "C:\Temp\unattend.xml"

# Inject Password into Answer File
(Get-Content "C:\Temp\unattend.xml") -Replace '%LABPASSWORD%', "$($Password)" | Set-Content "C:\Temp\unattend.xml"

#Download and Inject Answer File
$Volume = Mount-VHD -Path "D:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

#Dismount the VHD
Dismount-VHD -Path "D:\Temp\$($VM).vhd"

# Create Virtual Machine
New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "D:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
Add-VMNetworkAdapter -VMName BRAVM1 -SwitchName 'InternalvSwitch'
Set-VMProcessor "$($VM)" -Count 2
Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true

# Start the VM
Start-VM -VMName "$($VM)"