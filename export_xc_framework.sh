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

Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -configuration Release  -destination "generic/platform=iOS Simulator"  ARCHS=x86_64 -archivePath ${SIMULATOR_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES

check
Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -configuration Release  -destination "generic/platform=iOS"  ARCHS=arm64 -archivePath ${OS_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
check

rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR

echo "Creating $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework"
Xcodebuild -create-xcframework -framework $OS_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework  -debug-symbols $OS_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM -framework $SIMULATOR_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework -debug-symbols $SIMULATOR_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM -output $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework
check

echo "Copying $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework to WebRTCiOSSDK.xcframework"
rm -rf WebRTCiOSSDK.xcframework
cp -r $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework .
check 
#rm -rf $SIMULATOR_DIR
#rm -rf $OS_DIR

echo "WebRTCiOSSDK.xcframework is updated"
