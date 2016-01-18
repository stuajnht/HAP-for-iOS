# Frequently Asked Questions
Before asking for help or reporting a bug, please read through these Frequently Asked Questions to see if the problem can be resolved.

## Contents
* [I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect](#i-am-typing-in-a-correct-home-access-plus-server-address-but-i-am-being-told-it-is-incorrect)
* [What option should I choose after the initial setup: "Personal", "Shared" or "Single"?](#what-option-should-i-choose-after-the-initial-setup-personal-shared-or-single)
* [When browsing files, the app downloads and previews a "_login.aspx_" file](#when-browsing-files-the-app-downloads-and-previews-a-login.aspx-file)
* [Files from &lt;_app name_&gt; are showing their extension and "File" as the document type](#files-from-app-name-are-showing-their-extension-and-file-as-the-document-type)
* [When uploading a file from &lt;_app name_&gt; the upload progress is shown but the file doesn't appear in the folder](#when-uploading-a-file-from-app-name-the-upload-progress-is-shown-but-the-file-doesnt-appear-in-the-folder)

## I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect
You need to be running HAP+ over https with version 1.2 of TLS, which is a requirement by [Apple](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14) and [Home Access Plus+](https://hap.codeplex.com/SourceControl/changeset/87691). If you know that you are typing your HAP+ server address in correctly, and you are being told that it is incorrect, then it is a good idea to check that the server has TLS 1.2 enabled using [SSL Labs](https://www.ssllabs.com/ssltest/index.html).

## What option should I choose after the initial setup: "Personal", "Shared" or "Single"?
The app is designed to be used in a number of setups, namely Personal, Shared or Single. Which option you should choose is the one that best matches how the device you're installing it on to is being used. If you're still not sure, a more thorough description of each option is given below:
* *Personal* - This is the option that should be chosen if you have bought the device for your own use, such as your mobile phone. If you are a student, this is most likely the option that you'll choose
* *Shared* - If the iOS device is part of a class set or shared between departments. The app will log the user out once the lesson ends, to prevent other students being able to access work that isn't theirs (requires the HAP+ timetable plugin). Note: This is currently not implemented yet
* *Single* - The device that the app has been installed on is part of a 1:1 scheme, whereby the device is not shared between students and a single student will always log in to the same device

## When browsing files, the app downloads and previews a "_login.aspx_" file
This is due to the logon tokens for the app expiring, so the HAP+ server attempts to show the login page that is used when browsing using an Internet browser. Currently, the app doesn't automatically re-login, so you'll need to close the app and open it again. This will be fixed in a future build.

## Files from &lt;_app name_&gt; are showing their extension and "File" as the document type
While HAP+ server contains [support for a large number of common file types](http://hap.codeplex.com/SourceControl/latest#CHS%20Extranet/HAP.Web/images/icons/knownicons.xml), apps for iOS may include their own extensions which are not commonly known. If you are uploading files from &lt;_app name_&gt; and they are showing the file name and extension, instead of just the file name, and the description of the file type is "File" then you will need to include these additional file types for HAP+ to be able to understand them. Follow the steps below to complete this:

> :warning: This involves modifying a core file in HAP+ that may get over-written when HAP+ is updated. If you find that support for certain file types has stopped working after an update, complete the steps below again. You do this at your own risk&hellip; create a copy of the file before modifying, just to be safe.

> :information_source: This list should be updated with more known app file extensions. Information about the contenttype for the file may be found [here](http://www.freeformatter.com/mime-types-list.html) or [here](http://www.sitepoint.com/web-foundations/mime-types-complete-list/), otherwise it should be `application/octetstream`

1. On your HAP+ webserver, browse to and open the following file `~\images\icons\knownicons.xml` (where `~` is the root directory of your HAP+ install, usually `C:\inetpub\wwwroot\hap\images\icons\knownicons.xml`)
2. Above the final line that ends with `</Icons>` add the following lines:
``` xml
<!-- Including additional support for files created with the HAP+ iOS app -->
<Icon icon="docx.png" extension="epub" type="Electronic Publication" contenttype="application/epub+zip" />
<Icon icon="pptx.png" extension="keynote" type="Apple iWorks Keynote" contenttype="application/octetstream" />
<Icon icon="xlsx.png" extension="numbers" type="Apple iWorks Numbers" contenttype="application/octetstream" />
<Icon icon="vid.png" extension="mov" type="QuickTime Movie" contenttype="video/quicktime" />
<Icon icon="docx.png" extension="pages" type="Apple iWorks Pages" contenttype="application/octetstream" />
```
3. Save the file
4. Open IIS manager and restart the IIS server service (or if you have other websites running, navigate to and restart just the HAP+ website)

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