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

# Network Location Awareness Fix for Single DC
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters" -Name "AlwaysExpectDomainController" -Value 1

# Install ADDS
Install-WindowsFeature "AD-Domain-Services" -IncludeManagementTools | Out-Null

# Wait for Domain
while ((Test-NetConnection $($DomainName) -Port 389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded -eq $false) {
    Start-Sleep -Seconds 5
}

# Promote Domain Controller
$SecurePassword = ConvertTo-SecureString "$($Password)" -AsPlainText -Force #Note: This is used for DSRM and DC Promote
$UserName = "$($UserName)@$($DomainName)"
[pscredential]$Credentials = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)
Import-Module ADDSDeployment
Install-ADDSDomainController -SafeModeAdministratorPassword $SecurePassword -Credential $Credentials -DomainName "$($DomainName)" -NoRebootOnCompletion:$false -SiteName "Default-First-Site-Name" -Force