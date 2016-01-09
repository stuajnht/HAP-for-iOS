# Frequently Asked Questions
Before asking for help or reporting a bug, please read through these Frequently Asked Questions to see if the problem can be resolved.

## Contents
* [I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect](#i-am-typing-in-a-correct-home-access-plus-server-address-but-i-am-being-told-it-is-incorrect)
* [When uploading a file from &lt;_app name_&gt; the upload progress is shown but the file doesn't appear in the folder](#when-uploading-a-file-from-app-name-the-upload-progress-is-shown-but-the-file-doesnt-appear-in-the-folder)

## I am typing in a correct Home Access Plus+ server address, but I am being told it is incorrect
You need to be running HAP+ over https with version 1.2 of TLS, which is a requirement by [Apple](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14) and [Home Access Plus+](https://hap.codeplex.com/SourceControl/changeset/87691). If you know that you are typing your HAP+ server address in correctly, and you are being told that it is incorrect, then it is a good idea to check that the server has TLS 1.2 enabled using [SSL Labs](https://www.ssllabs.com/ssltest/index.html).

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