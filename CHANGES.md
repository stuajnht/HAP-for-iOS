# Home Access Plus+ iOS app change log

## 0.5.0

### New Stuff
* Upload files from other apps to a folder on the HAP+ server
* Upload photo and video files from iOS device to the HAP+ server

### Changes
* Included the drive letter under the name of the drive, to help the user identify the one they need
* Files that are over a certain size (20MB on mobile connections, 100MB on WiFi) need to be allowed by the user before they are downloaded

### Bug Fixes
* Stopped the file properties view appearing over the newly browsed to folder on small devices - #16
* Stopped showing the drive space if the HAP+ server reports it as a negative value - #17

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
* Set the correct icon for the relevant folder / file that is being displayed in the file browser table - #13
* A number of other things that 

## 0.2.0

### New Stuff
* Added app icon
* Added API to check for Internet connection
* Added API to check that the HAP+ server is contactable
* Added API to check the username and password for the user, and log them in if correct
* Displayed loading spinner during the logon attempt - #2
* Presented option to choose the device type during first setup of HAP+
* Collected the groups that the user is part of, to see if they are a domain admin
* Locksmith is being used to securely store the users password for future authentication attempts

### Changes
* Updated the background colour of the login view and master-detail view to reflect those used in HAP+ - #1
* Informed users that they need to be running TLS 1.2 on the HAP+ server - #11
* Disabled auto correction and predictive text on logon textboxes, and set HAP+ address keyboard display type to URLs - #12

### Bug Fixes
* If the HAP+ server address already begins with https://, do not prepend it again - #10
* When an invalid HAP+ server DNS address is typed in, prevent the app crashing - #11

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