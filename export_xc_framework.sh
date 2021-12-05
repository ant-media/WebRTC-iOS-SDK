#!/bin/bash

SIMULATOR_DIR=$(PWD)/Release-iphonesimulator
OS_DIR=$(PWD)/Release-iphoneos
UNIVERSAL_DIR=$(PWD)/Release-Universal

rm -rf $SIMULATOR_DIR
rm -rf $OS_DIR

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK clean
Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphonesimulator ARCHS=x86_64 -configuration Release install CONFIGURATION_BUILD_DIR=${SIMULATOR_DIR}

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphoneos ARCHS=arm64 -configuration Release install CONFIGURATION_BUILD_DIR=$OS_DIR


rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR

Xcodebuild -create-xcframework -framework $OS_DIR/WebRTCiOSSDK.framework -framework $SIMULATOR_DIR/WebRTCiOSSDK.framework -output $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework


#rm -rf $SIMULATOR_DIR
#rm -rf $OS_DIR

echo "If everything is ok. Your XC Framework is $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework"
