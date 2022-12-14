param(
    $DomainName = 'corp.barrierreefaudio.com',
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

# Add Authenticated Users to the Remote Desktop Users Group
Add-LocalGroupMember -Group "Remote Desktop Users" -Member 'S-1-5-11'

# Install Remote Service Administrative Tools
Install-WindowsFeature RSAT-AD-Tools -IncludeAllSubFeature

# Domain Join
$pw = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
$userName = "$($UserName)@$($DomainName)"
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($userName, $pw)
Add-Computer -Credential $creds -DomainName "$($DomainName)" -Restart -Force