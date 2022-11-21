param(
    $Password
)

# Import Hyper-V Module
Import-Module Hyper-V

# Wait for Hyper-V
while (-not(Get-VMHost -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 5
}

# Create VHD
$VM = "BRAVM1"
New-Item -Path C:\Temp -ItemType Directory -ErrorAction SilentlyContinue
New-VHD -ParentPath "C:\Users\Public\Documents\20348.169.amd64fre.fe_release_svc_refresh.210806-2348_server_serverdatacentereval_en-us.vhd" -Path "C:\Temp\$($VM).vhd" -Differencing

# Download Answer File
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ACloudGuru-Resources/content-az-800/master/labs/Configure%20Nested%20Virtualization%20on%20an%20Azure%20Virtual%20Machine/unattend.xml" -OutFile "C:\Temp\unattend.xml"

# Inject Password into Answer File
(Get-Content "C:\Temp\unattend.xml") -Replace '%LABPASSWORD%', "$($Password)" | Set-Content "C:\Temp\unattend.xml"

#Download and Inject Answer File
$Volume = Mount-VHD -Path "C:\Temp\$($VM).vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume
New-Item "$($Volume.DriveLetter):\Windows" -Name "Panther" -ItemType Directory -ErrorAction "SilentlyContinue"
Copy-Item "C:\Temp\unattend.xml" "$($Volume.DriveLetter):\Windows\Panther\unattend.xml"

#Dismount the VHD
Dismount-VHD -Path "C:\Temp\$($VM).vhd"