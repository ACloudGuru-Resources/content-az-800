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

# Install Active Directory Domain Services RSAT
Install-WindowsFeature -Name RSAT-ADDS

# Wait for Domain
while ((Test-NetConnection $($DomainName) -Port 389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded -eq $false) {
    Start-Sleep -Seconds 5
}

# Domain Join
$pw = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
$userName = "$($UserName)@$($DomainName)"
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($userName, $pw)
Add-Computer -Credential $creds -DomainName "$($DomainName)" -Restart -Force