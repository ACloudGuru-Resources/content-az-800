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
New-Item -Path C:\ -Name Data -ItemType Directory
New-SmbShare -Path C:\Data -Name Data -FullAccess Everyone

# Create a PowerShell Script
$RandomFiles = @('File1.bak','File2.bak','File3.bak','File4.bak','File5.bak','File6.bak','File7.bak','File8.bak','File9.bak','File10.bak')
foreach ($File in $RandomFiles) {
    New-Item -Path C:\Data -Name $File
    Write-Output "$(Get-Random -Minimum 9999 -Maximum 99999)" | Out-File -FilePath "C:\Scripts\$($File)"
}

# Wait for Domain
while ((Test-NetConnection $($DomainName) -Port 389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).TcpTestSucceeded -eq $false) {
    Start-Sleep -Seconds 5
}

# Domain Join
$pw = ConvertTo-SecureString "$($Password)" -AsPlainText -Force
$userName = "$($UserName)@$($DomainName)"
[pscredential]$creds = New-Object System.Management.Automation.PSCredential ($userName, $pw)
Add-Computer -Credential $creds -DomainName "$($DomainName)" -Restart -Force