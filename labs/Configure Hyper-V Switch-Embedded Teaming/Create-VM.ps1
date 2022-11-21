param(
    $UserName = 'admin_user',
    $Password
)

# ErrorActionPreference
$ErrorActionPreference = 'Stop'

# Configure Logging
$AllUsersDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$LogFile = Join-Path -Path $AllUsersDesktop -ChildPath "Labsetup.log" 

function Write-Log ($Entry, $Path = $LogFile) {
    Add-Content -Path $LogFile -Value "$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString()): $($Entry)" 
} 


# Import the Hyper-V Module
Import-Module Hyper-V

# Wait for Hyper-V
while (-not(Get-VMHost -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 5
}

# Create NAT Virtual Switch
Write-Log -Entry "VM Creation Start"
Write-Log -Entry "Create Virtual Switch Start"
try{
    New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
    New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix '10.2.1.0/24'
    Get-NetAdapter 'vEthernet (InternalvSwitch)' | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24
    Write-Log -Entry "Create Virtual Switch Success"
} catch {
    Write-Log -Entry "Create Virtual Switch Failed. Please contact Support."
    Write-Log $_
    Exit
}

# Create VHD
try {
    Write-Log -Entry "Create VHD Start"
    $VM = "BRAVM1"
    New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "D:\Temp\$($VM).vhd" -Differencing
    Write-Log -Entry "Create VHD Success"
} catch {
    Write-Log -Entry "Create VHD Failed. Please contact Support."
    Write-Log $_
    Exit
}

# Download Answer File 
try {
    Write-Log -Entry "Download Anwser File Start"
    New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Hyper-V%20Switch-Embedded%20Teaming/unattend.xml" -OutFile "C:\Temp\unattend.xml"
    Write-Log -Entry "Download Anwser File Success"
}
catch {
    Write-Log -Entry "Download Anwser File Failed. Please contact Support."
    Write-Log $_
    Exit
}

# Inject Password into Answer File
try {
    Write-Log -Entry "Inject Anwser File Start"
    (Get-Content "C:\Temp\unattend.xml") -Replace '%LABPASSWORD%', "$($Password)" | Set-Content "C:\Temp\unattend.xml"

    # Inject Answer File into VHD
    $Volume = Mount-VHD -Path "D:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
    New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
    Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"
    Write-Log -Entry "Inject Anwser File Success"
}
catch {
    Write-Log -Entry "Inject Anwser File Failed. Please contact Support."
    Write-Log $_
    Exit
}

#Dismount the VHD
try {
    Write-Log -Entry "Dismount VHD Start"
    Dismount-VHD -Path "D:\Temp\$($VM).vhd"
    Write-Log -Entry "Dismount VHD Success"
}
catch {
    Write-Log -Entry "Dismount VHD Failed. Please contact Support."
    Write-Log $_
    Exit
}

# Create Virtual Machine
try {
    Write-Log -Entry "Create and Start VM Start"
    New-VM -Name "$($VM)" -Generation 1 -MemoryStartupBytes 2GB -VHDPath "D:\Temp\$($VM).vhd" -SwitchName 'InternalvSwitch'
    Add-VMNetworkAdapter -VMName BRAVM1 -SwitchName 'InternalvSwitch'
    Set-VMProcessor "$($VM)" -Count 2
    Set-VMProcessor "$($VM)" -ExposeVirtualizationExtensions $true
    # Start the VM
    Start-VM -VMName "$($VM)"
    Write-Log -Entry "Create and Start VM Success"
}
catch {
    Write-Log -Entry "Create and Start VM Failed. Please contact Support."
    Write-Log $_
    Exit
}

Write-Log -Entry "LAB READY"