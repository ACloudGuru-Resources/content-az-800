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

# Create VHD
$VM = "BRAVM1"
New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "D:\Temp\$($VM).vhd" -Differencing

# Download Answer File 
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri "" -OutFile "C:\Temp\unattend.xml"

# Inject Password into Answer File
(Get-Content "C:\Temp\unattend.xml") -Replace '%LABPASSWORD%', "$($Password)" | Set-Content "C:\Temp\unattend.xml"

#Download and Inject Answer File
$Volume = Mount-VHD -Path "D:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

#Dismount the VHD
Dismount-VHD -Path "D:\Temp\$($VM).vhd"

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart:$false

#Restart the Server
Restart-Computer -Force