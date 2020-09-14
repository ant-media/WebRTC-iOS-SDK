#!/bin/bash

# Before running this script, you need to get WebRTC source code
# apply the batch in the folder

# After that
# this script is used for creating fat binary of WebRTC.framework
# It can be run after all frameworks are ready in out directory
# src/out/ios -> arm
# src/out/ios_64 -> arm64
# src/out/x86 -> x86
# src/out/x64 -> x64

# Sample args.gn for arm out/ios/args.gn, just change the cpu in different architecture
# target_os = "ios"
# target_cpu = "arm" # for each arch change it arm64, x86 and x64
# is_debug = false
# ios_enable_code_signing = false

# Sample build command, run the below command for each directory
# gn gen out/ios
# ninja -C out/ios framework_objc

# cd out   # copy this file to out folder as well
# run this file ./build...
# fat binary should be ready in release-universal

OS_DIR_64=$(PWD)/ios_64
OS_DIR=$(PWD)/ios
OS_DIR_x64=$(PWD)/x64
OS_DIR_x86=$(PWD)/x86

UNIVERSAL_DIR=$(PWD)/Release-Universal

rm -rf $UNIVERSAL_DIR

lipo -create $OS_DIR/WebRTC.framework/WebRTC  $OS_DIR_64/WebRTC.framework/WebRTC $OS_DIR_x64/WebRTC.framework/WebRTC $OS_DIR_x86/WebRTC.framework/WebRTC -output WebRTC

rm -rf $UNIVERSAL_DIR
mkdir $UNIVERSAL_DIR
cp -LR $OS_DIR_64/WebRTC.framework  $UNIVERSAL_DIR


mv WebRTC $UNIVERSAL_DIR/WebRTC.framework/WebRTC

#cp $OS_DIR_64/WebRTC.framework/Modules/WebRTC.swiftmodule/* $UNIVERSAL_DIR/WebRTC.framework/Modules/WebRTC.swiftmodule/


echo "If everything is ok. Your Universal Framework is under $UNIVERSAL_DIR"
