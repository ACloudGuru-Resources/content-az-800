var location  = resourceGroup().location
var random  = '${substring(toUpper(uniqueString(resourceGroup().location)),0,4)}${substring(uniqueString(resourceGroup().location),0,4)}'

output output string = random
