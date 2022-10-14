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

# Create a File Share
Install-WindowsFeature FS-FileServer
New-Item -Path C:\ -Name Scripts -ItemType Directory
New-SmbShare -Path C:\Scripts -Name Scripts -FullAccess Everyone

# Create a PowerShell Script
New-Item -Path C:\Scripts -Name "Get-RiskyUsers.ps1"
Set-Content -Path "C:\Scripts\Get-RiskyUsers.ps1" -Value "Write-Host 'Risky User Report' -ForegroundColor Yellow; Write-Host 'Inactive Users' -ForegroundColor White; Search-ADAccount –AccountInactive –UsersOnly | Format-Table; Write-Host 'Users With No Password Expiry' -ForegroundColor White; Search-ADAccount –PasswordNeverExpires –UsersOnly | Format-Table"

# Wait for Domain
while ((Test-NetConnection $($DomainName) -Port 389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded -eq $false) {
    Start-Sleep -Seconds 5
}


# Domain Join
$pw = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
$userName = "$($UserName)@$($DomainName)"
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($userName, $pw)
Add-Computer -Credential $creds -DomainName "$($DomainName)" -Restart -Force