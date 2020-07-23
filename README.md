# VisionKitSample

VisionKitSample is a simple cordova plugin in swift which scans a page and returns back the page lines that contains the string passed as input to the plugin.

## Installation

```
cordova plugin add https://github.com/Aiswarya/VisionKitSample.git
```

## Usage

```
cordova.plugins.VisionKitSample.scanAndRetreiveLines("textToSearch",
  function (successResponse) {
    console.log(successResponse.linesIdentified);
   }, 
  function (errorResponse) {
    console.log(errorResponse);
  });
```
