# QuantumSDK BTLE Demo for XCode

## Getting the SDK and Developer Key
1. Login to [IPCMobile Developer Portal](https://developer.ipcmobile.com/).
2. Go to Docs and Downloads.
3. Download the latest QuantumSDK.
4. Go to your Profile and click on My Dev Keys.
5. Generate a Developer Key with your Bundle ID.

## Extracting the SDK
1. Unzip the SDK folder and locate the XCFramework zip file.
2. Unzip the XCFramework file and open the folder.
3. Copy the QuantumSDK.xcframework to the root of the BTLE Demo project.

![SDK location](https://www.ipclorenz.lineascanner.com/images/quantumsdk-btle-demo-location.png)

## Running the demo app
1. Open BTLEDemo.xcodeproj
2. On the Project navigator, choose BTLEDemo and go to Signing & Capabilities.
3. Update the Bundle Identifier to match your Developer Key.
4. Open AppDelegate.swift file and change the developerKey variable to your Developer Key.
5. Build and Run the demo app on your device.

## Using the demo app
DISCOVER
- start searching for compatible Bluetooth LE devices.

SCAN TO PAIR
- initiate the camera to scan device serial number and pair to it.

RECONNECT
- reconnect to last paired Bluetooth LE device.

DISCONNECT
- disconnect to currently paired Bluetooth LE device.
