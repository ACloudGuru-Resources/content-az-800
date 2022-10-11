param (
    $DomainName = 'corp.barrierreefaudio.com',
    $NetbiosName = 'CORP',
    $DsrmPassword = 'p@55w0rd'
)
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null
$pw = ConvertTo-SecureString "$($DsrmPassword)" -AsPlainText -Force
Install-ADDSForest -DomainName "$($DomainName)" -SafeModeAdministratorPassword $pw -DomainNetBIOSName "$($NetbiosName)" -InstallDns -Force