ModulesToImport = 'ActiveDirectory' 

VisibleFunctions = 'Reset-ADUserPassword', 'Unlock-ADUserAccount' 

FunctionDefinitions = @(
    @{
        Name = 'Reset-ADUserPassword'
    
        ScriptBlock = {
            param($UserName)
            $User = Get-ADUser -Filter "SamAccountName -eq `"$Username`"" -ResultSetSize 1 -SearchBase 'OU=User Accounts,DC=corp,DC=barrierreefaudio,DC=com' -SearchScope 'Subtree' -ErrorAction SilentlyContinue
            if ($User) {
                try {
                    # Unlock User Account
                    Unlock-ADAccount -Identity $User
                    # Set a New Password
                    $Password = "Random$(Get-Random -Minimum 999 -Max 9999)"
                    Set-ADAccountPassword -Identity $User -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
                    #Force Password Change at Logon
                    Set-ADUser -Identity $User -ChangePasswordAtLogon $true
                    Write-Output "$($User.Name) password reset to $($Password)"
                }
                catch {
                    Write-Output "An error occured."
                }
            }
            else {
                Write-Output "User not found"
            }
            
        }
    }
    @{
        Name = 'Unlock-ADUserAccount'
    
        ScriptBlock = {
            param($UserName)
            $User = Get-ADUser -Filter "SamAccountName -eq `"$Username`"" -ResultSetSize 1 -SearchBase 'OU=User Accounts,DC=corp,DC=barrierreefaudio,DC=com' -SearchScope 'Subtree' -ErrorAction SilentlyContinue
            if ($User) {
                try {
                    # Unlock User Account
                    Unlock-ADAccount -Identity $User
                    Write-Output "$($User.Name) unlocked"
                }
                catch {
                    Write-Output "An error occured."
                }
            }
            else {
                Write-Output "User not found"
            }
            
        }
    }
) 