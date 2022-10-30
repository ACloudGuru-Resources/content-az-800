param (
    [pscredential]
	$Credential
)

Import-Module -Name ActiveDirectory

$Users = Search-ADAccount –AccountInactive –UsersOnly -Credential $Credential | Where-Object Enabled -eq $true
foreach ($User in $Users) {
    Write-Output "Disabling $($User.Name)"
    Disable-ADAccount -Identity $User -Credential $Credential -WhatIf 
} 