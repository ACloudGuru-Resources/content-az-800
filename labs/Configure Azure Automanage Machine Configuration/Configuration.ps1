configuration WebServer {
    Import-DscResource –ModuleName PSDscResources
    node 'localhost'
    {
        WindowsFeature WebServer {
            Name   = "Web-Server"
            Ensure = "Present"
        }

    }
} 
