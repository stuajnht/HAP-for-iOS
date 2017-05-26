# Frequently Asked Questions
Before asking for help or reporting a bug, please read through these Frequently Asked Questions to see if the problem can be resolved.

## Contents
* [I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect](#i-am-typing-in-a-correct-home-access-plus-server-address-but-i-am-being-told-it-is-incorrect)
* [What option should I choose after the initial setup: "Personal", "Shared" or "Single"?](#what-option-should-i-choose-after-the-initial-setup-personal-shared-or-single)
* [When browsing files, the app downloads and previews a "_login.aspx_" file](#when-browsing-files-the-app-downloads-and-previews-a-login.aspx-file)
* [When browsing folders, an "_Unable to load folder_" error message keeps showing](#when-browsing-folders-an-unable-to-load-folder-error-message-keeps-showing)
* [When trying to use the menu (upload popover) I am told to log in again](#when-trying-to-use-the-menu-upload-popover-i-am-told-to-log-in-again)
* [Files from &lt;_app name_&gt; are showing their extension and "File" as the document type](#files-from-app-name-are-showing-their-extension-and-file-as-the-document-type)
* [When uploading a file from &lt;_app name_&gt; the upload progress is shown but the file doesn't appear in the folder](#when-uploading-a-file-from-app-name-the-upload-progress-is-shown-but-the-file-doesnt-appear-in-the-folder)
* [When using the document picker in &lt;_app name_&gt; an error of *Failed to launch 'Home Access Plus+'* is shown](#when-using-the-document-picker-in-app-name-an-error-of-failed-to-launch-home-access-plus-is-shown)
* [I am being asked to type an "_authenticated username_" to log out of the device](#i-am-being-asked-to-type-an-authenticated-username-to-log-out-of-the-device)
* [Why are so many Privacy Purpose Permissions needed?](#why-are-so-many-privacy-purpose-permissions-needed)
* [Something is not Working as Expected (Using Log Files)](#something-is-not-working-as-expected-using-log-files)

## I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect
You need to be running HAP+ over https with version 1.2 of TLS, which is a requirement by [Apple](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14) and [Home Access Plus+](https://hap.codeplex.com/SourceControl/changeset/87691). If you know that you are typing your HAP+ server address in correctly, and you are being told that it is incorrect, then it is a good idea to check that the server has TLS 1.2 enabled and is using a correctly configured SSL certificate (isn't self signed, expired, or containing a mismatched domain name) using [SSL Labs](https://www.ssllabs.com/ssltest/index.html).

## What option should I choose after the initial setup: "Personal", "Shared" or "Single"?
The app is designed to be used in a number of setups, namely Personal, Shared or Single. Which option you should choose is the one that best matches how the device you're installing it on to is being used. If you're still not sure, a more thorough description of each option is given below:
* *Personal* - This is the option that should be chosen if you have bought the device for your own use, such as your mobile phone. If you are a student, this is most likely the option that you'll choose
* *Shared* - If the iOS device is part of a class set or shared between departments. The app will log the user out once the lesson ends, to prevent other students being able to access work that isn't theirs (requires the [HAP+ timetable plugin](https://hap.codeplex.com/wikipage?title=Timetable%20Plugin&referringTitle=Documentation) to be installed and set up on the HAP+ server)
* *Single* - The device that the app has been installed on is part of a 1:1 scheme, whereby the device is not shared between students and a single student will always log in to the same device, or you are using a set of iOS devices in a presentation / exam and don't want users to log out of them. See also: ["Single" mode logout steps](#i-am-being-asked-to-type-an-authenticated-username-to-log-out-of-the-device)

## When browsing files, the app downloads and previews a "_login.aspx_" file
This is due to the logon tokens for the app expiring, so the HAP+ server attempts to show the login page that is used when browsing using an Internet browser. Since version 0.7.0 the app automatically logs users back in with the credentials they origianlly used to log in to the app. If you are on or above this version, please log out of the app and log back in again, as your password may have expired or been changed, meaning the app cannot log you in successfully.

## When browsing folders, an "_Unable to load folder_" error message keeps showing
This error message may be shown due to loss of connectivity or your logon tokens have expired for the app. Please try the following steps to resolve the problem:
1. Check that you are connected to a network, and press the "_Try Again_" button. This should solve the problem most of the time
2. Press the home button and then tap on the app icon. After a few seconds, press the "_Try Again_" button. When the app starts, it attempts to log you in if needed
3. Press the menu button above where the folder listing normally is, and choose the "_Log Out_" option. Then log back in with your username and password

## When trying to use the menu (upload popover) I am told to log in again
It can sometimes (although very rarely (see below)) be the case where you, or a previous user, had logged out of the app in the past, but when using the app again in the future it appears that you are still logged in. When trying to open the menu (upload popover) on the file browser you will be informed that you need to log back in again. Please log back in to the app again to continue using it as expected.

> :information_source: This can be caused by iOS app restoration saving a previous layout when the app was switched away from, which it tries to restore from when the app is loaded again. If you logged out of the app and it crashed, or the device shut down, then when you open it again it tries to restore this incorrect state

> :information_source: To simulate when debugging the app: build and run the app from Xcode; press the home button; open the app via the icon on the device; stop running the app from Xcode; open the app again; press the menu button

## Files from &lt;_app name_&gt; are showing their extension and "File" as the document type
While HAP+ server contains [support for a large number of common file types](http://hap.codeplex.com/SourceControl/latest#CHS%20Extranet/HAP.Web/images/icons/knownicons.xml), apps for iOS may include their own extensions which are not commonly known. If you are uploading files from &lt;_app name_&gt; and they are showing the file name and extension, instead of just the file name, and the description of the file type is "File" then you will need to include these additional file types for HAP+ to be able to understand them. Follow the steps below to complete this:

> :warning: This involves modifying a core file in HAP+ that may get over-written when HAP+ is updated. If you find that support for certain file types has stopped working after an update, complete the steps below again. You do this at your own risk&hellip; create a copy of the file before modifying, just to be safe.

> :information_source: This list should be updated with more known app file extensions. Information about the contenttype for the file can be found on the [IANA Media Types webpage](http://www.iana.org/assignments/media-types/media-types.xhtml), otherwise it should be `application/octetstream`. Additional information on MIME types may be found on [www.freeformatter.com](http://www.freeformatter.com/mime-types-list.html) or [www.sitepoint.com](http://www.sitepoint.com/web-foundations/mime-types-complete-list/). Failing any of those websites, a search of the [file format list on Wikipedia](https://en.wikipedia.org/wiki/List_of_file_formats) for the extension may bring up the relevant information.

1. On your HAP+ webserver, browse to and open the following file `~\images\icons\knownicons.xml` (where `~` is the root directory of your HAP+ install, usually `C:\inetpub\wwwroot\hap\images\icons\knownicons.xml`)
2. Above the final line that ends with `</Icons>` add the following lines:
``` xml
<!-- Including additional support for file types, such as those created with the HAP+ iOS app -->
<Icon icon="zip.png" extension="7z" type="7z Compressed Archive" contenttype="application/x-7z-compressed" />
<Icon icon="mp3.png" extension="aac" type="Advanced Audio Coding" contenttype="audio/aac" />
<Icon icon="bmp.png" extension="ai" type="Adobe Illustrator Image" contenttype="application/postscript" />
<Icon icon="exe.png" extension="bin" type="MacBinary Archive" contenttype="application/macbinary" />
<Icon icon="zip.png" extension="bz2" type="bzip2 Compressed Archive" contenttype="application/x-bzip2" />
<Icon icon="cs.png" extension="c" type="C Source File" contenttype="text/plain" />
<Icon icon="docx.png" extension="epub" type="Electronic Publication" contenttype="application/epub+zip" />
<Icon icon="zip.png" extension="gz" type="Gzip Compressed Archive" contenttype="application/gzip" />
<Icon icon="cs.png" extension="h" type="C Header Source File" contenttype="text/plain" />
<Icon icon="bmp.png" extension="icns" type="Apple Icon Image" contenttype="application/octetstream" />
<Icon icon="txt.png" extension="json" type="JavaScript Object Notation File" contenttype="application/json" />
<Icon icon="pptx.png" extension="keynote" type="Apple iWorks Keynote" contenttype="application/octetstream" />
<Icon icon="txt.png" extension="log" type="Log File" contenttype="text/plain" />
<Icon icon="vid.png" extension="mov" type="QuickTime Movie" contenttype="video/quicktime" />
<Icon icon="xlsx.png" extension="numbers" type="Apple iWorks Numbers" contenttype="application/octetstream" />
<Icon icon="docx.png" extension="odt" type="Open Document Text" contenttype="application/vnd.oasis.opendocument.text" />
<Icon icon="pptx.png" extension="odp" type="Open Document Presentation" contenttype="application/vnd.oasis.opendocument.presentation" />
<Icon icon="xlsx.png" extension="ods" type="Open Document Spreadsheet" contenttype="application/vnd.oasis.opendocument.spreadsheet" />
<Icon icon="docx.png" extension="pages" type="Apple iWorks Pages" contenttype="application/octetstream" />
<Icon icon="cs.png" extension="php" type="PHP Hypertext Preprocessor File" contenttype="text/plain" />
<Icon icon="cs.png" extension="pl" type="Perl Script" contenttype="text/plain" />
<Icon icon="cs.png" extension="ps1" type="PowerShell Script" contenttype="text/plain" />
<Icon icon="cs.png" extension="py" type="Python Script" contenttype="text/plain" />
<Icon icon="bmp.png" extension="psd" type="Adobe Photoshop Document" contenttype="image/vnd.adobe.photoshop" />
<Icon icon="cs.png" extension="sh" type="Bourne Shell Script" contenttype="text/plain" />
<Icon icon="bmp.png" extension="svg" type="Scalable Vector Graphic" contenttype="image/svg+xml" />
<Icon icon="zip.png" extension="tar" type="Tape Archive" contenttype="application/x-tar" />
<Icon icon="cs.png" extension="vb" type="Visual Basic File" contenttype="text/plain" />
<Icon icon="cs.png" extension="vbs" type="Visual Basic Script" contenttype="text/plain" />
<Icon icon="txt.png" extension="yml" type="YAML Ain't Markup Language File" contenttype="text/plain" />
<Icon icon="txt.png" extension="yaml" type="YAML Ain't Markup Language File" contenttype="text/plain" />
```
3. Save the file
4. Open IIS manager and restart the IIS server service (or if you have other websites running, navigate to and restart just the HAP+ website)

> :information_source: If a new file extension is added to `knownicons.xml`, then the icon for it will probably not exist in the `~\images\icons\` folder. You can use [Nirsoft IconsExtract](http://www.nirsoft.net/utils/iconsext.html) to extract the file icon from the main program executable, convert it to a *.png file with [ImageMagick](http://www.imagemagick.org/script/index.php) (`convert <file>.ico <file>.png`) and copy it to the `~\images\icons\` folder.

## When uploading a file from &lt;_app name_&gt; the upload progress is shown but the file doesn't appear in the folder
By default, your institutions Home Access Plus+ server is set to only accept a limited number of file types. The app that you are using probably saves in a format that is not common, so HAP+ doesn't allow the file to be added. You will need to speak to your institutions network manager to allow support for additional file types. Point them here for the instructions on how to do this:
1. Log in to your HAP+ servers web interface and go to the setup page (something like: https://&lt;_domain_&gt;/hap/setup.aspx)
2. Go to the "My Files" tab
3. Scroll to the "Filters" section on this page
4. Perform the following steps (the first option on both steps is the 'easy' option, the second option is the 'safer for security' choice):
  1. Set the file types that are allowed to be uploaded, either:
    * To allow any file type to be uploaded:
      1. Click on the "All Files" button
    * To allow only specific file types to be uploaded:
      1. Click on the "Add" button next to the filter heading
      2. On the "Filter Editor" dialog that opens, type in the name for the filter and the extensions for the file types that are to be accepted, seperated with semicolons (e.g. \*.epub;\*.pages)
  2. Choose which user groups this filter is going to be available for. Click on the "Enable for" textbox, then on the dialog that opens either:
    * To allow this filter apply to all users in the domain:
      1. Click on the "All" button then press OK
    * To only allow this filter to apply to certain user groups:
      1. Click the "Custom" button
      2. Click the magnifying glass to search for the groups
      3. Browse your domain hierarchy to find the relevant group and click on them (if you aren't able to browse your domain, check that you have a password set on the "Active Directory" tab)
      4. Press the "Add" button
      5. Repeat the above steps 2 - 4 as many times as is needed
      6. If there is a blank row above the first group, click on it them press the "Remove" button
      7. Press OK to close the "Group Builder" dialog. (With the cursor still in the textbox, press the home key on your keyboard to go to the beginning of the text and remove any leading commas and spaces, which sometimes appear even if you've removed the blank row)
  3. Press the "Add" or "Save" button on the "Filter Editor" dialog
5. Press the big "Save" button at the bottom of the page. The relevant files can now be uploaded from the Home Access Plus+ app and "My Files" web interface

## When using the document picker in &lt;_app name_&gt; an error of *Failed to launch 'Home Access Plus+'* is shown
Once you have enabled the document picker in &lt;_app name_&gt;, by choosing 'More' from the Locations menu and turning it on, an alert may be shown with a title of "*Failed to launch 'Home Access Plus+'*" and a message body of "_The document picker 'Home Access Plus+' failed to launch (0)._". Upon pressing the _Dismiss_ button the document picker closes.

To fix this, you will need to restart your iOS device. While it's not common to say a device should be restarted once an app is installed ([Apple App Store Review Guidelines, Metadata - 3.11](https://developer.apple.com/app-store/review/guidelines/#metadata)), the replies given on this [feedback for "_Textastic_" app question](http://feedback.textasticapp.com/topic/999376-error-document-picker-both-google-drive-and-working-copy/) suggest to do this and it resolves the problem.

## I am being asked to type an "_authenticated username_" to log out of the device
This occurs when the Home Access Plus+ app on your device has been set up in ["Single" mode](#what-option-should-i-choose-after-the-initial-setup-personal-shared-or-single). To prevent unauthorised users logging out of the account that has been set up on the device, a special username needs to be entered. This is a unique username that has been set up at your institution. Please ask your IT department to log you out, or the reason why your device is set up this way.

:information_source: *For IT Departments*: If a user has set up their personal device in the incorrect mode, or you need to log the currently logged in user out, please follow these steps:
1. Create a group in Active Directory called `hap-ios-admins`
2. Create a new user in an OU that the HAP+ server is set up to look in
   * This account should have a hard-to-guess but memorable username, such as: `hap-app-log-out-1029384756`
   * This account can be set as disabled, only the username and group membership are checked to see if they are correct
3. Add the newly created user to the `hap-ios-admins` group created in step 1
4. Type in the username created, in the message on the device, and press continue. The user will then be logged out

> :warning: It is advised that you create a new user account for this. If you add your own user account to the `hap-ios-admins` group then it is likely a student will know your username and be able to log out of the device.

> :information_source: These steps will need to be undertaken each time a user wants to log off if a device is in "Single" mode. If this is not intended, uninstall and reinstall the app to be able to choose a [different mode](#what-option-should-i-choose-after-the-initial-setup-personal-shared-or-single) on first login again.

> :information_source: Users on the domain who are in the `Domain Admins` group are automatically logged out when the device is in "Single" mode. It is assumed that this group contains IT staff only, so when the device is initially being set up, you can log in and put it in "Single" mode, then log out quickly ready to hand it to a user.

## Why are so many Privacy Purpose Permissions needed?
Due to the inclusion of the [PermissionScope](https://github.com/nickoneill/PermissionScope) Cocoapod to simplify requests for permissions, there is an [issue](https://github.com/nickoneill/PermissionScope/issues/194) with how many permissions are requested compared to how many are ever used. The permissions this app uses are listed below:
* Privacy - Camera Usage Description (`NSCameraUsageDescription`): This allows for images or videos to be taken directly in the app and uploaded to the current folder, without needing to open the camera app first
* Privacy - Photo Library Usage (`NSPhotoLibraryUsageDescription`): This allows for the ability to browse the photo and video library on your device to access the files in them to upload it to the HAP+ server. While it is possible to send the media file from the photos app to this app, this allows for a convenient way to access those items

Any other Privacy Purpose Permissions that are shown *are not used*, but are needed to be included for the app to be submitted to the App Store

## Something is not Working as Expected (Using Log Files)
It is possible to generate log files from the app to see what is going on to cause a problem. To enable debug logging, perform the following steps:
1. Open the main iOS Settings app and scroll down to the "Home Access Plus+" section
2. Toggle the "Enable Logging to a File" option
3. If needed, select a logging level to capture the right amount of information
   * Severe - Only logged if the app has a serious problem, assuming it can be caught
   * Error - Captures most problems that occur during the use of the app
   * Warning (Default) - An error may occur related to this, but the app should work as expected
   * Infomation - High-level descriptions about what the app is currently doing
   * Debug - Detailed and developer orentated messages
4. Run the HAP+ app as you have been doing to recreate the problem
5. Browse to a folder that you can upload to, and from the upload menu, press the "Save Log Files" option (this will be a new item to the popover)
6. All log files from the device will be uploaded to the current folder as a zip file, and it can be opened on another computer to see what is causing the problem

> :information_source: If you are unable to log in, complete steps 1 - 4 above, then tap the name of the app on the login screen 10 times. An email will be created with the log files attached (assuming an email account is set up on the device). This limit is set to prevent any accidental triggering
