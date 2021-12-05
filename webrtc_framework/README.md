# AntMediaSDK
iOS SDK 

*  Get WebRTC source code and checkout the below commit 

m96 branch -> branch-heads/4664
git checkout -b antmedia_m96 branch-heads/4664

Latest commit is  
809830f1b39f9d0933dd979c9e8f32a4a922b71c (HEAD -> antmedia_m96, branch-heads/4664)
Author: Philipp Hancke <phancke@nvidia.com>
Date:   Thu Nov 25 08:57:54 2021 +0100


* Apply patch in this directory

* Build WebRTC.framework for architectures, arm64, x64 . Configuration for arm as follows 
target_os = "ios"
target_cpu = "arm64" # for each arch change x64
is_debug = false
ios_enable_code_signing = false
ios_deployment_target="10.0"
enable_run_ios_unittests_with_xctest=true
rtc_enable_objc_symbol_export=true

* gn gen out/ios_64

* ninja -C out/ios framework_objc


* you need to run below command for all architectures and their directory map as follows
src/out/ios_64 -> arm64
src/out/x64 -> x64

* After everything has finished. Run the following command to have xcframework in out directory

xcodebuild -create-xcframework -framework out/ios_64/WebRTC.framework -framework out/x64/WebRTC.framework -output out/WebRTC.xcframework

* Replace the WebRTC.xcframework folder with the current one 
