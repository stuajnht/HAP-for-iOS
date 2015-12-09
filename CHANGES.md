# Home Access Plus+ iOS app change log

## 0.2.0

### New Stuff
* Added app icon
* Added API to check for Internet connection
* Added API to check that the HAP+ server is contactable
* Added API to check the username and password for the user, and log them in if correct
* Displayed loading spinner during the logon attempt - #2
* Presented option to choose the device type during first setup of HAP+

### Changes
* Updated the background colour of the login view and master-detail view to reflect those used in HAP+ - #1
* Informed users that they need to be running TLS 1.2 on the HAP+ server - #11

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