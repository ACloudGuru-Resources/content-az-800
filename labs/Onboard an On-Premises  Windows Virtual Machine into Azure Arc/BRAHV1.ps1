param(
    $UserName = 'admin_user',
    $Password
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Fix Server UI
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart:$false

# Create NAT Virtual Switch
Import-Module Hyper-V
New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix “10.2.1.0/24”
Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24

# Create VHD
$VM = "BRAVM1"
New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing

# Download Answer File 
Invoke-WebRequest -Uri "" 

# Inject Password into Answer File


#Download and Inject Answer File
$Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriverLetter)\mount\windows\Windows\Panther\unattend.xml"

# Create Virtual Machine
New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "C:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
Set-VMProcessor $($VM) -Count 2
Start-VM -VMName "$($VM)"