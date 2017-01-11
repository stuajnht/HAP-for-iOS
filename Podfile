# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

# Setting up Cocoapods shared between the main project
# target and and extensions
def shared_pods
  pod 'Alamofire'
  pod 'Font-Awesome-Swift'
  pod 'Locksmith'
  pod 'MBProgressHUD'
  pod 'SwiftyJSON'
  pod 'XCGLogger'
end

target 'HomeAccessPlus' do
  shared_pods
  pod 'ChameleonFramework'
  pod 'DKImagePickerController'
  pod 'PermissionScope'
end

target 'HomeAccessPlusDocumentProvider' do
  shared_pods
end

target 'HomeAccessPlusDocumentProviderFileProvider' do
  shared_pods
end

target 'HomeAccessPlusTests' do

end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-HomeAccessPlus/Pods-HomeAccessPlus-acknowledgements.plist', 'Settings.bundle/AcknowledgementsCocoaPods.plist', :remove_destination => true)
end

