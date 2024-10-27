$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName = "*"
            PsDscAllowPlainTextPassword = $true
        }
    )
}
$ResourceGroupName = Get-AzResourceGroup | Select-Object -ExpandProperty Name
$AutomationAccountName = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName | Select-Object -ExpandProperty Name
Start-AzAutomationDscCompilationJob -ConfigurationName 'ServerConfiguration' -ConfigurationData $ConfigurationData -ResourceGroupName $ResourceGroupName -AutomationAccountName