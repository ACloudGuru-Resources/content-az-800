param(
    $DomainName = 'corp.barrierreefaudio.com',
    $UserName = 'admin_user',
    $Password
)
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1
$pw = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
$userName = "$($UserName)@$($DomainName)"
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($userName, $pw)
Add-Computer -Credential $creds -DomainName "$($DomainName)" -Restart -Force