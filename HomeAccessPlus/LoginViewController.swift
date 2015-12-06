// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//
//  LoginViewController.swift
//  HomeAccessPlus
//

import UIKit
import ChameleonFramework
import XCGLogger

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var lblAppName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var tblHAPServer: UITextField!
    @IBOutlet weak var lblHAPServer: UILabel!
    @IBOutlet weak var tblUsername: UITextField!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var tbxPassword: UITextField!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var sclLoginTextboxes: UIScrollView!
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // Setting up a reference to the HAP+ server address
    var hapServerAddress = ""
    
    // Seeing if all of the login checks have completed successfully
    var successfulLogin = false
    
    // Used for moving the scrollbox when the keyboard is shown
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setting up the colours for the login scene
        view.backgroundColor = UIColor.flatSkyBlueColorDark()
        lblAppName.textColor = UIColor.flatWhiteColor()
        lblMessage.textColor = UIColor.flatWhiteColor()
        lblHAPServer.textColor = UIColor.flatWhiteColor()
        lblUsername.textColor = UIColor.flatWhiteColor()
        lblPassword.textColor = UIColor.flatWhiteColor()
        btnLogin.tintColor = UIColor.flatWhiteColor()
        
        // Handle the text field’s user input
        tblHAPServer.delegate = self
        tblUsername.delegate = self
        tbxPassword.delegate = self
        tblHAPServer.returnKeyType = .Next
        tblUsername.returnKeyType = .Next
        tbxPassword.returnKeyType = .Go
        
        // Registering for moving the scroll view when the keyboard is shown
        registerForKeyboardNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // Preventing the login button from progressing until the
        // login checks have been validated
        // From: http://jamesleist.com/ios-swift-tutorial-stop-segue-show-alert-text-box-empty/
        if (identifier == "login.btnLoginSegue") {
            // Deregistering from keyboard notifications to allow
            // enable scrolling the textboxes
            deregisterFromKeyboardNotifications()
            return successfulLogin
        }
        
        // By default, perform the transition
        return true
    }
    
    /// Cleans up the HAP+ URL address that the user has typed
    ///
    /// The HAP+ URL and API addresses need to be in the format
    /// https://hapServer.FQDN/optionalDirectory. This function
    /// formats the entered URL to make sure that it conforms to
    /// this standard
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 1
    /// - date: 2015-12-06
    @IBAction func formatHAPURL(sender: AnyObject) {
        // Making sure that https:// is at the beginning of the sting.
        // This is needed as by default HAP+ server only works over https
        // See: https://hap.codeplex.com/SourceControl/changeset/87691
        let http = "http://"
        let https = "https://"
        
        hapServerAddress = tblHAPServer.text!
        logger.debug("Original HAP+ URL: \(hapServerAddress)")
        
        // Seeing if server has http at the start
        if (hapServerAddress.hasPrefix(http)) {
            // Replacing the http:// in the URL to be https://
            hapServerAddress = hapServerAddress.stringByReplacingOccurrencesOfString(http, withString: https)
        } else {
            // Appending https:// to the start of the address
            hapServerAddress = https + hapServerAddress
        }
        
        // Removing any trailing '/' characters, as we add these in
        // during any API calls
        if (hapServerAddress.hasSuffix("/")) {
            hapServerAddress = hapServerAddress.substringToIndex(hapServerAddress.endIndex.predecessor())
        }
        
        logger.debug("Formatted HAP+ URL: \(hapServerAddress)")
    }
    
    @IBAction func attemptLogin(sender: AnyObject) {
        // Checking if there is an available Internet connection,
        // and if so, attempt to log the user into the HAP+ server
        if(api.checkConnection()) {
            // Cleaning up the HAP+ server address that has been typed
            
            checkAPI(hapServerAddress, attempt: 1)
        } else {
            // Unable to connect to the Internet, so let the user know they
            // should make sure they have an active connection
            let apiCheckConnectionController = UIAlertController(title: "Unable to access the Internet", message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.Alert)
            apiCheckConnectionController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(apiCheckConnectionController, animated: true, completion: nil)
        }
    }
    
    /// Checks the HAP+ API provided, to make sure that the server is
    /// contactable and the right version
    ///
    /// Before attempting to do any additional processing, we need to make sure
    /// the HAP+ server URL provided can contact the users HAP+ server. This function
    /// performs this, and either caries on with the logon attempt, or lets the user
    /// know that there was a problem with the URL
    ///
    /// - note: This function can get called twice if needed before continuing the logon
    ///         attempt. If the user doesn't type "/hap" at the end of the URL but the
    ///         site needs it, this is when the function is called again with this appended
    ///         to hopefully guess what should be in there. Any server set up different to
    ///         this will fail on the second attempt, and let the user know
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 2
    /// - date: 2015-12-03
    ///
    /// - parameter hapServer: The URL to the HAP+ server
    /// - parameter attempt: How many times this function has been called
    func checkAPI(hapServer: String, attempt: Int) -> Void {
        logger.debug("Attempting to contact the HAP+ server at the URL: \(hapServer)")
        
        api.checkAPI(hapServer, callback: { (result: Bool) -> Void in
            logger.info("HAP+ API contactable at \(hapServer): \(result)")
            
            // Seeing if the check for the API was successful. If not, then see
            // what attempt we are on. If the first attempt, then call this function
            // again with "/hap" at the end of the URL, otherwise let the user know
            // there was a problem with the URL they entered
            if (result == false && attempt == 1) {
                self.checkAPI(hapServer + "/hap", attempt: attempt + 1)
            }
            if (result == false && attempt != 1) {
                let apiFailController = UIAlertController(title: "Invalid HAP+ Address", message: "The address that you have entered for the HAP+ server is not valid", preferredStyle: UIAlertControllerStyle.Alert)
                apiFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(apiFailController, animated: true, completion: nil)
            }
            if (result) {
                // Successful HAP+ API check, so continue with the login attempt
                // - TODO: Remove this as it's just in for testing, and replace with next login check
                self.successfulLogin = true
                self.performSegueWithIdentifier("login.btnLoginSegue", sender: self)
            }
        })
    }
    
    /// Looking after moving the focus onto each textfield when the next
    /// button is pressed on the keyboard
    ///
    /// To make it easier for the user to navigate to the next textbox
    /// when they're setting up the login information, we move the focus
    /// to the next textbox when the 'next' button is presses on the keyboard
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 1
    /// - date: 2015-12-06
    ///
    /// - param textfield: The identifier for the textfield
    /// - returns: Indicates that the text field should respond to the user
    ///            pressing the next / go key
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Hide the keyboard and move it to the next textfield
        if textField == self.tblHAPServer {
            self.tblUsername.becomeFirstResponder()
        }
        if textField == self.tblUsername {
            self.tbxPassword.becomeFirstResponder()
        }
        if textField == self.tbxPassword {
            self.tbxPassword.resignFirstResponder()
            attemptLogin(self)
        }
        return true
    }
    
    // MARK: Keyboard
    // The following functions look after scrolling the textboxes into view
    // when the keyboard is shown or hidden:
    //  * registerForKeyboardNotifications
    //  * deregisterFromKeyboardNotifications
    //  * keyboardWasShown
    //  * keyboardWillBeHidden
    //  * textFieldDidBeginEditing
    //  * textFieldDidEndEditing
    // See: http://stackoverflow.com/a/28813720
    func registerForKeyboardNotifications() {
        // Adding notifies on keyboard appearing
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications() {
        // Removing notifies on keyboard appearing
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        // Need to calculate keyboard exact size due to Apple suggestions
        self.sclLoginTextboxes.scrollEnabled = true
        let info : NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        self.sclLoginTextboxes.contentInset = contentInsets
        self.sclLoginTextboxes.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let _ = activeField {
            if (!CGRectContainsPoint(aRect, activeField!.frame.origin)) {
                self.sclLoginTextboxes.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        // Once keyboard disappears, restore original positions
        let info : NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        self.sclLoginTextboxes.contentInset = contentInsets
        self.sclLoginTextboxes.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.sclLoginTextboxes.scrollEnabled = false
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeField = nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
