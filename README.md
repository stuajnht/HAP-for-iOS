# Home Access Plus+ for iOS

Home Access Plus+ (HAP) for iOS provides a native app to connect your Apple device to your institutions [Home Access Plus+](https://hap.codeplex.com) server. You can then browse, upload and download files easily to and from your iOS device to your institution network file drives.

## Requirements
To be able to use this app, you will need to have the following:
* iOS 9 device
* Home Access Plus+ set up and running for your institution (bug your network managers to get this set up)
  * You need to be running HAP+ over https with version 1.2 of TLS, which is a requirement by [Apple](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14) and [Home Access Plus+](https://hap.codeplex.com/SourceControl/changeset/87691). If you know that you are typing your HAP+ server address in correctly, and you are being told that it is incorrect, then it is a good idea to check that the server has TLS 1.2 enabled using [SSL Labs](https://www.ssllabs.com/ssltest/index.html).

## Contributing
Thanks for your interest in contributing to this project. You can contribute or report issues in the following ways:
* [Report a bug](http://issuetemplate.com/#/stuajnht/HAP-for-iOS/bug) if something isn't working as you expect it to
* [Suggest an improvement](http://issuetemplate.com/#/stuajnht/HAP-for-iOS/request) for something that you'd like to see

## License Terms
Home Access Plus+ for iOS is publised under the GNU GPL v3 License, see the [LICENSE](https://github.com/stuajnht/HAP-for-iOS/blob/master/LICENSE.md) file for more information.

The name "Home Access Plus+" and all server side code are copyright Nick Brown ([nb development](https://nbdev.uk/projects/hap.aspx))

### Cocoapods
This project uses Cocoapods. Their project source code pages and licenses can be found below:
* [Alamofire](https://github.com/Alamofire/Alamofire/)
* [ChameleonFramework](https://github.com/ViccAlexander/Chameleon)
* [Font Awesome Swift](https://github.com/Vaberer/Font-Awesome-Swift)
* [Locksmith](https://github.com/matthewpalmer/Locksmith)
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [XCGLogger](https://github.com/DaveWoodCom/XCGLogger)

### Other Projects
The following projects and source code are included in HAP+ for iOS. Their licenses project pages can be found below:
* [Reach](https://github.com/Isuru-Nanayakkara/Reach)