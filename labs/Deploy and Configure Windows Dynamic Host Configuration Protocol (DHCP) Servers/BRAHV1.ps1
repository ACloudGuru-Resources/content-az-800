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

# Ensure C:\Temp exists
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue

#Download Scripts
Invoke-WebRequest -Uri '' -OutFile 'C:\temp\Create-VM.ps1'

# Create VMs
$VMs = @('BRADC1','BRAWKS1')
foreach ($VM in $VMs) {
    #Set Scheduled Tasks to create the VM after restart
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -Password $($Password) -VMName $($VM)"
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"

    # Create VHD
    New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing

    # Download Answer File 
    New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri "" -OutFile "C:\Temp\unattend.xml"

    # Inject Password into Answer File
    (Get-Content "C:\Temp\unattend.xml") -Replace '%LABPASSWORD%', "$($Password)" | Set-Content "C:\Temp\unattend.xml"

    #Download and Inject Answer File
    $Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
    New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
    Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

    #Dismount the VHD
    Dismount-VHD -Path "C:\Temp\$($VM).vhd"
}

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart:$false

#Restart the Server
Restart-Computer -Force