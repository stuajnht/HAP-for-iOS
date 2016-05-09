# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'HomeAccessPlus' do
  pod 'Alamofire'
  pod 'ChameleonFramework'
  pod 'Font-Awesome-Swift'
  pod 'Locksmith'
  pod 'MBProgressHUD'
  pod 'PermissionScope'
  pod 'SwiftyJSON'
  pod 'XCGLogger'
end

target 'HomeAccessPlusTests' do

end

post_install do | installer |
  require 'fileutils'
  FileUtils.cp_r('Pods/Target Support Files/Pods-HomeAccessPlus/Pods-HomeAccessPlus-acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end

