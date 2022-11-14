param(
    $UserName = 'admin_user',
    $Password = '18FC6CDAE918fc6cdae9'
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
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Deploy%20and%20Configure%20Windows%20Dynamic%20Host%20Configuration%20Protocol%20(DHCP)%20Servers/Create-VM.ps1' -OutFile 'C:\temp\Create-VM.ps1'

# Create VMs
$VMs = @('BRADHCP1','BRASVR1')
foreach ($VM in $VMs) {
    #Set Scheduled Tasks to create the VM after restart
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Create-VM.ps1 -Password $($Password) -VM $($VM)"
    # Random dleay so both don't run at exactly the same time
    $Trigger = New-ScheduledTaskTrigger -AtStartup
    $Trigger.Delay = 'PT15S'
    Register-ScheduledTask -TaskName "Create-VM $($VM)" -Action $Action -Trigger $Trigger -Description "Create VM" -RunLevel Highest -User "System"
}

# Install Hyper-V
Add-WindowsFeature Hyper-V -IncludeManagementTools -Restart:$false

#Restart the Server
Restart-Computer -Force 
