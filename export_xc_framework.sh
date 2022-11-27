#!/bin/bash

check() {
  OUT=$?
  if [ $OUT -ne 0 ]; then
    echo "There is a problem in exporting xcframework. Please take a look at the logs above. Try to resolve the issue. If you need help, let's send a support request support@antmedia.io "
    exit $OUT
  fi
}

SIMULATOR_DIR=$(PWD)/Release-iphonesimulator.xcarchive
SIMULATOR_ARM64_DIR=$(PWD)/Release-iphonesimulator_arm64.xcarchive
UNIVERSAL_SIMULATOR_DIR=$(PWD)/Release-iphonesimulator_universal.xcarchive
OS_DIR=$(PWD)/Release-iphoneos.xcarchive
UNIVERSAL_DIR=$(PWD)/Release-Universal

rm -rf $SIMULATOR_DIR
rm -rf $SIMULATOR_ARM64_DIR
rm -rf $OS_DIR
rm -rf $UNIVERSAL_SIMULATOR_DIR

Xcodebuild -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK clean
check

#create simulator x86_64 
Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -configuration Release  -destination "generic/platform=iOS Simulator"  ARCHS=x86_64 -archivePath ${SIMULATOR_DIR}  SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
check

#create simulator arm64
Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -configuration Release  -destination "generic/platform=iOS Simulator"  ARCHS=arm64 -archivePath ${SIMULATOR_ARM64_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
check

#build fat binary for simulators
mkdir -p $UNIVERSAL_SIMULATOR_DIR
cp -r $SIMULATOR_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework  $UNIVERSAL_SIMULATOR_DIR/
lipo -create -output ${UNIVERSAL_SIMULATOR_DIR}/WebRTCiOSSDK.framework/WebRTCiOSSDK ${SIMULATOR_DIR}/Products/Library/Frameworks/WebRTCiOSSDK.framework/WebRTCiOSSDK ${SIMULATOR_ARM64_DIR}/Products/Library/Frameworks/WebRTCiOSSDK.framework/WebRTCiOSSDK 
check 

#merge dsyms
cp -r $SIMULATOR_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM  $UNIVERSAL_SIMULATOR_DIR/
check

lipo -create -output $UNIVERSAL_SIMULATOR_DIR/WebRTCiOSSDK.framework.dSYM/Contents/Resources/DWARF/WebRTCiOSSDK \
  $SIMULATOR_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM/Contents/Resources/DWARF/WebRTCiOSSDK \
  $SIMULATOR_ARM64_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM/Contents/Resources/DWARF/WebRTCiOSSDK
check

#create device arm64
Xcodebuild archive -workspace AntMediaReferenceApplication.xcworkspace -scheme WebRTCiOSSDK -configuration Release  -destination "generic/platform=iOS"  ARCHS=arm64 -archivePath ${OS_DIR} SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
check



rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR

echo "Creating $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework"
Xcodebuild -create-xcframework \
  -framework $OS_DIR/Products/Library/Frameworks/WebRTCiOSSDK.framework \
  -debug-symbols  $OS_DIR/dSYMs/WebRTCiOSSDK.framework.dSYM \
  -framework $UNIVERSAL_SIMULATOR_DIR/WebRTCiOSSDK.framework \
  -debug-symbols  $UNIVERSAL_SIMULATOR_DIR/WebRTCiOSSDK.framework.dSYM \
  -output $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework
check

echo "Copying $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework to WebRTCiOSSDK.xcframework"
rm -rf WebRTCiOSSDK.xcframework
cp -r $UNIVERSAL_DIR/WebRTCiOSSDK.xcframework .
check 
#rm -rf $SIMULATOR_DIR
#rm -rf $OS_DIR

echo "WebRTCiOSSDK.xcframework is updated"
