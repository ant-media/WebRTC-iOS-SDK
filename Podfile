# Uncomment the next line to define a global platform for your project

abstract_target 'AntMediaWebRTCSDK' do
  platform :ios, '12.0'
  use_frameworks!
  pod 'Starscream', '~> 4.0.4'
  
  target 'AntMediaReferenceApplication' do
  end

  target 'WebRTCiOSSDK' do
  end
  
  target 'ScreenShare' do
  end
  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end
end
