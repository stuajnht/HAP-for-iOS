# Home Access Plus+ iOS app change log

## 0.9.0

### Notes
* Starting from build 790, this project uses Xcode 8.2 and Swift 3.0.2. A large amount of code refactoring has taken place since [#f6ecd4] to conform to the latest syntax

### New Stuff
* Log files [can be created](FAQ.md#something-is-not-working-as-expected-using-log-files) for use in debugging the app on remote devices and uploaded

## 0.8.0

### Notes
* This version never left 'alpha' stage, and has since been changed to 0.9.0, due to other commitments causing this project to have an unexpected hiatus (apart from the occasional code fix). The decision to bump up the version number is due to a large number of code changes needed for Swift 3

### New Stuff
* Multiple photos or videos can be selected and uploaded at once to the HAP+ server
* The licenses for the [various projects](README.md#license-terms) this app uses are shown in the main iOS Settings app

### Changes
* The old functionality to upload one photo or video at a time to the HAP+ server can be enabled in the main iOS settings app
* Displayed the name of the file being uploaded on the "file exists" alert, so that it is known which file the message is referring to
* Changed how the "File Browser" table view controller works:
  * If the device is in portrait mode, the view is now shown after login
  * The view can be hidden in both portrait and landscape orentations, giving more available screen space to preview files

### Bug Fixes
* Fixed bug where the app would crash if the user logged out when the device is in portrait mode (The master view controller would stay visible, causing subsequent actions to try and access settings that are nil)
* Fixed bug where the upload popover would show an incorrect lanuch location if the device is rotated when the popover is visible
* Fixed bug where if the currently selected file is downloaded immediately again, but the file data has been changed on a remote device, the correct version of the file is shown

## 0.7.0

### Notes
* Starting from build 729, this project uses Xcode 7.3 and Swift 2.2. These have been updated from Xcode 7.1.1 and Swift 2.1, which were used since this project began

### New Stuff
* Upload files to the HAP+ server from cloud storage providers (the relevant apps need to be installed on the iOS device too)
* Files can be uploaded and downloaded in some external apps without needing to download from the Home Access Plus+ app first
* Users can log out of the app if they want to pass it to another user - [#4](https://github.com/stuajnht/HAP-for-iOS/issues/4)
* Users are automatically logged back in to the HAP+ server and if they do not use the app for a period of time (or their logon sessions are renewed constantly if the app is in the foreground), so they can continue where they left off almost straight away
* Users who are using the device during a timetabled lesson are automatically logged out at the end of the lesson. The device needs to be set up in "shared" mode for this to work, and the [timetable plugin for HAP+](https://hap.codeplex.com/wikipage?title=Timetable%20Plugin&referringTitle=Documentation) needs to be installed

### Changes
* App restoration now takes place if the app is stopped in the background, so that when opened again the user remains in the same folder location they were before
* Updated message on the login screen if the HAP+ server does not have a correctly configured SSL certificate (self signed, expired, domain name mismatch) - credit: [kidpressingbuttons](http://www.edugeek.net/members/kidpressingbuttons.html)

### Bug Fixes
* Fixed typo in upload popover description text from 'curent' to 'current' - [#19](https://github.com/stuajnht/HAP-for-iOS/pull/19) credit: [@TestValleySchool](https://github.com/TestValleySchool)
* Fixed bug where the upload popover would restore incorrectly as a full screen view if the user had to grant app permissions, rather than stay in the popover - [#20](https://github.com/stuajnht/HAP-for-iOS/issues/20)

## 0.6.0

### New Stuff
* Files and folders can be deleted by swiping them to the left
* New folders can be created in the currently viewed folder
* When uploading a file, if it already exists in the current folder the user is given the choice to:
  * Create a new version of the file and keep the old version too
  * Replace the original file with the one being uploaded from the app

### Changes
* Keyboards on the login screen and new folder alert only allow letters and numbers, to prevent emojis being used

## 0.5.0

### New Stuff
* Upload files from other apps to a folder on the HAP+ server
* Upload photo and video files from iOS device to the HAP+ server

### Changes
* Included the drive letter under the name of the drive, to help the user identify the one they need
* Files that are over a certain size (20MB on mobile connections, 100MB on WiFi) need to be allowed by the user before they are downloaded

### Bug Fixes
* Stopped the file properties view appearing over the newly browsed to folder on small devices - [#16](https://github.com/stuajnht/HAP-for-iOS/issues/16)
* Stopped showing the drive space if the HAP+ server reports it as a negative value - [#17](https://github.com/stuajnht/HAP-for-iOS/issues/17)

## 0.4.0

### New Stuff
* Selected file is downloaded onto the device
* Supported files are displayed by QuickLook, so that they can be viewed and shared to other apps
* Files downloaded are removed from the device once the preview has been finished with

## 0.3.0

### New Stuff
* Listed drives available to the user once they have logged on
* Allowed the user to browse through the folder hierarchy on the network drives

### Changes
* Nothing major from what is listed above

### Bug Fixes
* Set the correct icon for the relevant folder / file that is being displayed in the file browser table - [#13](https://github.com/stuajnht/HAP-for-iOS/issues/13)
* A number of other things that 

## 0.2.0

### New Stuff
* Added app icon
* Added API to check for Internet connection
* Added API to check that the HAP+ server is contactable
* Added API to check the username and password for the user, and log them in if correct
* Displayed loading spinner during the logon attempt - [#2](https://github.com/stuajnht/HAP-for-iOS/issues/2)
* Presented option to choose the device type during first setup of HAP+
* Collected the groups that the user is part of, to see if they are a domain admin
* Locksmith is being used to securely store the users password for future authentication attempts

### Changes
* Updated the background colour of the login view and master-detail view to reflect those used in HAP+ - [#1](https://github.com/stuajnht/HAP-for-iOS/issues/1)
* Informed users that they need to be running TLS 1.2 on the HAP+ server - [#11](https://github.com/stuajnht/HAP-for-iOS/issues/11)
* Disabled auto correction and predictive text on logon textboxes, and set HAP+ address keyboard display type to URLs - [#12](https://github.com/stuajnht/HAP-for-iOS/issues/17)

### Bug Fixes
* If the HAP+ server address already begins with https://, do not prepend it again - [#10](https://github.com/stuajnht/HAP-for-iOS/issues/10)
* When an invalid HAP+ server DNS address is typed in, prevent the app crashing - [#11](https://github.com/stuajnht/HAP-for-iOS/issues/11)

## 0.1.0

### Notes
* Hello world!

### New Stuff
* Added settings for Home Access Plus iOS app
* Designed login view

### Changes
* Umm... not really

### Bug Fixes
* Quite a few
