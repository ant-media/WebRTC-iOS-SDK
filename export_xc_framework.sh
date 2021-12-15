#!/bin/bash

check() {
  OUT=$?
  if [ $OUT -ne 0 ]; then
    echo "There is a problem in exporting xcframework. Please take a look at the logs above. Try to resolve the issue. If you need help, let's send a support request support@antmedia.io "
    exit $OUT
  fi
}

SIMULATOR_DIR=$(PWD)/Release-iphonesimulator.xcarchive
OS_DIR=$(PWD)/Release-iphoneos.xcarchive
UNIVERSAL_DIR=$(PWD)/Release-Universal

rm -rf $SIMULATOR_DIR
rm -rf $OS_DIR

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK clean
check

Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphonesimulator ARCHS=x86_64 -archivePath ${SIMULATOR_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

check
Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -sdk iphoneos ARCHS=arm64 -archivePath ${OS_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
check

rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR

Xcodebuild -create-xcframework -framework $OS_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework -framework $SIMULATOR_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework -output $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework
check


#rm -rf $SIMULATOR_DIR
#rm -rf $OS_DIR

echo "If everything is ok. Your XC Framework is $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework"
