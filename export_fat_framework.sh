#!/bin/bash

SIMULATOR_DIR=$(PWD)/Release-iphonesimulator
OS_DIR=$(PWD)/Release-iphoneos
UNIVERSAL_DIR=$(PWD)/Release-Universal

rm -rf $SIMULATOR_DIR
rm -rf $OS_DIR

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK clean
Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphonesimulator -configuration Release install CONFIGURATION_BUILD_DIR=${SIMULATOR_DIR}

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphoneos -configuration Release install CONFIGURATION_BUILD_DIR=$OS_DIR

lipo -create $OS_DIR/WebRTCiOSSDK.framework/WebRTCiOSSDK  $SIMULATOR_DIR/WebRTCiOSSDK.framework/WebRTCiOSSDK -output WebRTCiOSSDK.temp

rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR
cp -LR $OS_DIR/.  $UNIVERSAL_DIR

mv WebRTCiOSSDK.temp $UNIVERSAL_DIR/WebRTCiOSSDK.framework/WebRTCiOSSDK

cp $SIMULATOR_DIR/WebRTCiOSSDK.framework/Modules/WebRTCiOSSDK.swiftmodule/* $UNIVERSAL_DIR/WebRTCiOSSDK.framework/Modules/WebRTCiOSSDK.swiftmodule/

rm -rf $SIMULATOR_DIR
rm -rf $OS_DIR

echo "If everything is ok. Your Universal Framework is $UNIVERSAL_DIR/WebRTCiOSSDK.framework"
