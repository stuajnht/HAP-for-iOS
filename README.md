# Home Access Plus+ for iOS

Home Access Plus+ (HAP) for iOS provides a native app to connect your Apple device to your institutions [Home Access Plus+](https://hap.codeplex.com) server. You can then browse, upload and download files easily to and from your iOS device to your institution network file drives.

## Requirements
To be able to use this app, you will need to have the following:
* iOS 9 device
* Home Access Plus+ set up and running for your institution (bug your network managers to get this set up)
  * You need to be running HAP+ over https with version 1.2 of TLS, which is a requirement by [Apple](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14) and [Home Access Plus+](https://hap.codeplex.com/SourceControl/changeset/87691). If you know that you are typing your HAP+ server address in correctly, and you are being told that it is incorrect, then it is a good idea to check that the server has TLS 1.2 enabled using [SSL Labs](https://www.ssllabs.com/ssltest/index.html).

## Frequently Asked Questions
Before asking for help or reporting a bug, please read through these few Frequently Asked Questions to see if the problem can be resolved.

### When uploading a file from &lt;_app name_&gt; the upload progress is shown but the file doesn't appear in the folder
By default, your institutions Home Access Plus+ server is set to only accept a limited number of file types. The app that you are using probably saves in a format that is not common, so HAP+ doesn't allow the file to be added. You will need to speak to your institutions network manager to allow support for additional file types. Point them here for the instructions on how to do this:
1. Log in to your HAP+ servers web interface and go to the setup page (something like: https://<domain>/hap/setup.aspx)
2. Go to the "My Files" tab
3. Scroll to the "Filters" section on this page
4. Perform the following steps (the first option on both steps is the 'easy' option, the second option is the 'safer for security' choice):
   a. Set the file types that are allowed to be uploaded, either:
      * To allow any file type to be uploaded, click on the "All Files" button
      * To allow only specific file types to be uploaded, click on the "Add" button next to the filter heading. On the "Filter Editor" dialog that opens, type in the name for the filter and the extensions for the file types that are to be accepted, seperated with semicolons (e.g. *.epub;*.pages)
   b. Choose which user groups this filter is going to be available for. Click on the "Enable for" textbox, then on the dialog that opens either:
      * To allow this filter apply to all users in the domain, click on the "All" button then press OK
      * To only allow this filter to apply to certain user groups, click the "Custom" button then the magnifying glass to search for the groups. Browse your domain hierarchy to find the relevant group and click on them (if you aren't able to browse your domain, check that you have a password set on the "Active Directory" tab) then press the "Add" button. Repeat as many times as is needed. If there is a blank row above the first group, click on it them press the "Remove" button. Press OK to close the "Group Builder" dialog. (With the cursor still in the textbox, press the home key on your keyboard to go to the beginning of the text and remove any leading commas and spaces, which sometimes appear even if you've removed the blank row)
   c. Press the "Add" or "Save" button on the "Filter Editor" dialog
5. Press the big "Save" button at the bottom of the page. The relevant files can now be uploaded from the Home Access Plus+ app and "My Files" web interface

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

## To-Do List
The following features are planned for the Home Access Plus+ iOS app, along with their expected releases (which can change).

### 0.5.0
* ~~Accept files from other apps~~
* ~~Upload files to the folder specified by the user on the HAP+ server~~
* Upload files from the photo gallery with a popover on the 'add' button
* Check if the file being uploaded exists / has the same name and automatically append a number on the end
* Prevent auto-downloading files that are over a certain size

### 0.6.0
* Create new folders
* Delete files / folders
* Over-write files that already exist, if the user confirms they want to (requires original file to be deleted first, then new file uploaded)

### 0.7.0
* Auto re-login for devices that are in 'personal' or 'single' mode
* A settings menu of some sort (either in-app or the main settings app)
* Update additional supported file icons
* Update icon so that the ‘house’ isn’t as close to the bottom corner