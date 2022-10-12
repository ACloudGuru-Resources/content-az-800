# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Fix Server UI
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

# Create a File Share
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Data -ItemType Directory
New-SmbShare -Path C:\Data -Name Data -FullAccess Everyone

# Install ADDS and Create Forest
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "p@55w0rd" -AsPlainText -Force
Install-ADDSForest -DomainName "dev.rivercityai.com" -SafeModeAdministratorPassword $pw -DomainNetBIOSName 'DEV' -InstallDns -Force
