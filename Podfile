# Uncomment the next line to define a global platform for your project
platform :ios, '17.0'

# Исправление deployment target для YandexMobileMetrica
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end

target 'Tracker_New' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Tracker_New
  pod 'YandexMobileMetrica', '~> 4.0'

end

