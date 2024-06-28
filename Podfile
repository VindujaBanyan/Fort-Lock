# Uncomment the next line to define a global platform for your project
 platform :ios, '13.0'

target 'Fort' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Fort
  pod 'IQKeyboardManagerSwift', :modular_headers => true
  pod 'Alamofire'
   pod 'SlideMenuControllerSwift'
   pod 'TrustKit', '~> 3.0.3'
   pod 'XLPagerTabStrip'
   pod 'JJFloatingActionButton'
   pod 'Firebase'
   pod 'Firebase/Core'
   pod 'Firebase/Messaging'
   pod 'Firebase/RemoteConfig'
   pod 'AppCenter'
   pod 'SKCountryPicker'
   pod 'libPhoneNumber-iOS'
   pod 'SwiftyJSON'
   pod 'JailbrokenDetector'
   pod 'nanopb'
   pod 'Firebase/Analytics'
   pod 'FirebaseAuth'
   pod 'FirebaseFirestore'
  # pod 'Firebase/AnalyticsWithoutAdIdSupport'
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if target.platform_name == :ios
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
# post_install do |installer|
  # installer.generated_projects.each do |project|
    #   project.targets.each do |target|
         # target.build_configurations.each do |config|
             #  config.build_settings ['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
          end
      end
  end
 end
