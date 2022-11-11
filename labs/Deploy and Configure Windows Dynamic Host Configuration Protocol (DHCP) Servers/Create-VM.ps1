param(
    $UserName = 'admin_user',
    $Password,
    $VM
)
# Configure Logging
$AllUsersDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
$LogFile = Join-Path -Path $AllUsersDesktop -ChildPath "$($VM)-Labsetup.log" 

function Write-Log ($Entry, $Path = $LogFile) {
    Add-Content -Path $LogFile -Value "$((Get-Date).ToShortDateString()) $((Get-Date).ToShortTimeString()): $($Entry)" 
} 

# Import Hyper-V Module
Import-Module Hyper-V

# Create NAT Virtual Switch
Write-Log -Entry "VM Creation Start"
try{
    if (-not(Get-VMSwitch -Name "InternalvSwitch" -ErrorAction SilentlyContinue)) {
        Write-Log -Entry "Create Virtual Switch Start"
        New-VMSwitch -Name 'InternalvSwitch' -SwitchType 'Internal'
        New-NetNat -Name LocalNAT -InternalIPInterfaceAddressPrefix “10.2.1.0/24”
        Get-NetAdapter "vEthernet (InternalvSwitch)" | New-NetIPAddress -IPAddress 10.2.1.1 -AddressFamily IPv4 -PrefixLength 24
        Write-Log -Entry "Create Virtual Switch Success"
    }
} catch {
    Write-Log -Entry "Create Virtual Switch Failed. Please contact Support."
}

# Create VHD
try {
    Write-Log -Entry "Create VHD Start"
    New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing
    Write-Log -Entry "Create VHD Success"
} catch {
    Write-Log -Entry "Create VHD Failed. Please contact Support."
}

# Download Answer File 
try {
    Write-Log -Entry "Download Answer File Start"
    New-Item -Path "C:\Temp\$($VM)" -ItemType Directory -ErrorAction SilentlyContinue
    $AnswerFilePath = "C:\Temp\$($VM)\unattend.xml"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Deploy%20and%20Configure%20Windows%20Dynamic%20Host%20Configuration%20Protocol%20(DHCP)%20Servers/unattend.xml" -OutFile $AnswerFilePath
    Write-Log -Entry "Download Answer File Success"
}
catch {
    Write-Log -Entry "Download Answer File Failed. Please contact Support."
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
}

# Dismount the VHD
try {
    Write-Log -Entry "Dismount VHD Start"
    Dismount-VHD -Path "C:\Temp\$($VM).vhd"
    Write-Log -Entry "Dismount VHD Success"
}
catch {
    Write-Log -Entry "Dismount VHD Failed. Please contact Support."
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
}

Write-Log -Entry "LAB READY"