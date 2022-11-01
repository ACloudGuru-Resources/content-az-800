$GUID = New-GUID
$PolicyConfig      = @{
  PolicyId      = "$($GUID)"
  ContentUri    = "https://github.com/ACloudGuru-Resources/content-az-800/raw/master/labs/Configure%20Azure%20Automanage%20Machine%20Configuration/WebServer.zip"
  DisplayName   = 'Web Server Policy'
  Description   = 'WebServer Policy to ensure IIS is installed'
  Path          = './policies'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig