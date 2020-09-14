# AntMediaSDK
iOS SDK 

*  Get WebRTC source code and checkout the below commit 

m85 branch -> branch-heads/4183
Latest commit is  
2bcd4837dd5eeed98523344d437eb0b7e4f441ba (HEAD -> m85, branch-heads/4183)
Author: Taylor Brandstetter <deadbeef@webrtc.org>
Date:   Tue Jul 21 14:02:47 2020 -0700


* Apply patch in this directory

* Build WebRTC.framework for all architectures, arm, arm64, x86, x64 . Configuration for arm as follows 
target_os = "ios"
target_cpu = "arm" # for each arch change it arm64, x86 and x64
is_debug = false
ios_enable_code_signing = false

* gn gen out/ios

* ninja -C out/ios framework_objc


* you need to run below command for all architectures and their directory map as follows
src/out/ios -> arm
src/out/ios_64 -> arm64
src/out/x86 -> x86
src/out/x64 -> x64

* After everything has finished. Copy build_universal_webrtc_framework.sh to the src/out directory
and run it to have fat binary
./build_universal_webrtc_framework.sh

Then fat binary should be in Release-Universal