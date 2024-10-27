$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PsDscAllowPlainTextPassword = $true
        }
    )
}
$ResourceGroupName = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
$AutomationAccountName = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty AutomationAccountName
Start-AzAutomationDscCompilatiåonJob -ConfigurationName 'ServerConfiguration' -ConfigurationData $ConfigurationData -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName