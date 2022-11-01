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

#Download Scripts
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Hyper-V%20Switch-Embedded%20Teaming/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'

#Set Scheduled Tasks
# Remove Deployments
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -Password $($Password)"
$Trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "Create-VM" -Action $Action -Trigger $Trigger -Description "Clean-up Azure Deployments" -RunLevel Highest -User "System"

#Restart the Server
Restart-Computer -Force