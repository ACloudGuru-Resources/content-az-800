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
New-Item -Path 'C:\Temp' -ItemType Directory -ErrorAction SilentlyContinue

#Download Scripts
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Implement%20IP%20Address%20Management%20(IPAM)%20on%20Windows%20Server/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'

# Create VMs
$VMs = @{
    BRADC1 = @{
        Role = "PDC"
        IP = "10.2.1.2"
    }
    BRAIPAM1  = @{
        Role = "MemberServer"
        IP = "10.2.1.3"
    }
}
foreach ($VM in $VMs.GetEnumerator()) {
    #Set Scheduled Tasks to create the VM after restart
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -Password `"$($Password)`" -VM `"$($VM.Name)`" -Role `"$($VM.Value['Role'])`" -IP `"$($VM.Value['IP'])`""
    # Random delay so both don't run at exactly the same time
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Trigger.Delay = 'PT1M'
    Register-ScheduledTask -TaskName "Create-VM $($VM.Name)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
}

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart:$false

#Restart the Server
Restart-Computer -Force 