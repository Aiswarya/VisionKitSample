# VisionKitSample

VisionKitSample is a simple cordova plugin in swift which scans a page using VisionKit (available from iOS 13) and returns back the page lines that contains the string that was passed as input to the plugin.

## Installation

Below command will add the plugin with default "NSCameraUsageDescription" specified in the plugin.
```
cordova plugin add https://github.com/Aiswarya/VisionKitSample.git
```
Inorder to add application specific NSCameraUsageDescription, plugin can be added by specifying variable name "CAMERA_USAGE_DESCRIPTION". 
```
cordova plugin add https://github.com/Aiswarya/VisionKitSample.git --variable CAMERA_USAGE_DESCRIPTION="description"
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
