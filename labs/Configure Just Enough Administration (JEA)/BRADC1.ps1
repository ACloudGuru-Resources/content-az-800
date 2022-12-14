param(
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

# Create a non-Administrator User
$UserPassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
New-LocalUser -Name helpdesk_user -Password $UserPassword

# Network Location Awareness Fix for Single DC
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters" -Name "AlwaysExpectDomainController" -Value 1

# Install ADDS and Create Forest
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force
Install-ADDSForest -DomainName "corp.barrierreefaudio.com" -SafeModeAdministratorPassword $pw -DomainNetBIOSName 'CORP' -InstallDns -Force