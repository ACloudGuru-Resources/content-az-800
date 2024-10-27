$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PsDscAllowPlainTextPassword = $true
        }
    )
}
$ResourceGroupName = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
$AutomationAccountName = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Name
Start-AzAutomationDscCompilatiåonJob -ConfigurationName 'ServerConfiguration' -ConfigurationData $ConfigurationData -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName