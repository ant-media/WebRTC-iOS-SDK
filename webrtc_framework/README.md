# AntMediaSDK
iOS SDK 

* Get WebRTC source code, change directory to src folder with `cd src` and checkout the m108 branch -> branch-heads/5359
  ```
  git checkout -b antmedia_m108 branch-heads/5359
  ```

* Apply patch in this directory
  ```
  git am --signoff < 0001-rtc_audio_device_and_dont_ask_mic_permission_for_playback.patch
  ```

* Run the script to build WebRTC.framework for arm64(device).
  ```
  gn gen out/ios_arm64
  ```
  * Change the content of the `out/ios_arm64/args.gn` with your editor as follows
    ```
    target_os = "ios"
    target_cpu = "arm64" 
    target_environment="device"
    is_debug = false
    ios_enable_code_signing = false
    ios_deployment_target="12.0"
    enable_run_ios_unittests_with_xctest=true
    rtc_enable_objc_symbol_export=true
    enable_stripping=true
    ```
  * Run the command `ninja -C out/ios_arm64 framework_objc`   

* Run the script to build WebRTC.framework for arm64(simulator).
  ```
  gn gen out/ios_arm64_simulator
  ```
  * Change the content of the `out/ios_arm64_simulator/args.gn` with your editor as follows
    ````
    target_os = "ios"
    target_cpu = "arm64" 
    target_environment="simulator"
    is_debug = false
    ios_enable_code_signing = false
    ios_deployment_target="12.0"
    enable_run_ios_unittests_with_xctest=true
    rtc_enable_objc_symbol_export=true
    enable_stripping=true
    ```
  * Run the command `ninja -C out/ios_arm64_simulator framework_objc`   

* Run the script to build WebRTC.framework for x86_64(simulator).
  ```
  gn gen out/ios_x64_simulator
  ```
  * Change the content of the `out/ios_x64_simulator/args.gn`  with your editor as follows
    ````
    target_os = "ios"
    target_cpu = "x64" 
    target_environment="simulator"
    is_debug = false
    ios_enable_code_signing = false
    ios_deployment_target="12.0"
    enable_run_ios_unittests_with_xctest=true
    rtc_enable_objc_symbol_export=true
    enable_stripping=true
    ```
  * Run the command `ninja -C out/ios_x64_simulator framework_objc`   

* Run the command `mkdir -p out/ios_simulator_universal/`

* Copy content of `ios_x64_simulator` to the `ios_simulator_universal`
  ```
  cp -r out/ios_x64_simulator/WebRTC.Framework out/ios_simulator_universal/
  ```

* Create FAT binary for simulators
  ```
   lipo -create -output out/ios_simulator_universal/WebRTC.framework/WebRTC \
    out/ios_arm64_simulator/WebRTC.framework/WebRTC  \
    out/ios_x64_simulator/WebRTC.framework/WebRTC 
  ```

* After everything has finished. Run the following command to have xcframework in out directory

  ```   
  xcodebuild -create-xcframework -framework out/ios_simulator_universal/WebRTC.framework \
   -framework out/ios_arm64/WebRTC.framework \
   -output out/WebRTC.xcframework
  ```

* The new WebRTC.xcframework is available under `out` directory
