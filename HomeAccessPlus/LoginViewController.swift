// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015-2017  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
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
import MessageUI
import ChameleonFramework
import Locksmith
import MBProgressHUD
import XCGLogger
import Zip

class LoginViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var lblAppName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var tblHAPServer: UITextField!
    @IBOutlet weak var tbxHAPMultisite: UITextField!
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
    
    // MBProgressHUD variable, so that the detail label can be updated as needed
    var hud : MBProgressHUD = MBProgressHUD()
    
    // Used for moving the scrollbox when the keyboard is shown
    var activeField: UITextField?
    
    // Used to see how many times the app name label has been
    // tapped, to see if the log files should be emailed
    var appNameTapCount = 0
    
    // Used to hold a reference to the dynamically generated
    // picker view to show the servers available
    var pkrHAPServer : UIPickerView!
    
    // Used to display the list of HAP+ servers set up on this
    // device when multisite is enabled in the settings
    var hapServerPickerData: [String] = [String]()
    
    // Used to hold the dictionary of HAP+ server addresses and
    // site names. The key is the server URL, the value is the
    // name of the site
    var multisiteServerList: [String: String] = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setting up the colours for the login scene
        view.backgroundColor = UIColor(hexString: hapMainColour)
        lblAppName.textColor = UIColor.flatWhite()
        lblMessage.textColor = UIColor.flatWhite()
        lblHAPServer.textColor = UIColor.flatWhite()
        lblUsername.textColor = UIColor.flatWhite()
        lblPassword.textColor = UIColor.flatWhite()
        btnLogin.tintColor = UIColor.flatWhite()
        
        // Handle the text field’s user input
        tblHAPServer.delegate = self
        tblUsername.delegate = self
        tbxPassword.delegate = self
        tblHAPServer.returnKeyType = .next
        tblUsername.returnKeyType = .next
        tbxPassword.returnKeyType = .go
        
        // Handle the multisite textbox to display
        // the picker
        tbxHAPMultisite.delegate = self
        
        // Allowing the app name label to be pressed, so that
        // logs on the device can be uploaded
        // See: http://stackoverflow.com/a/39992213
        let appNameTap = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.emailLogFiles))
        lblAppName.isUserInteractionEnabled = true
        lblAppName.addGestureRecognizer(appNameTap)
        
        // Registering for moving the scroll view when the keyboard is shown
        registerForKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Clearing the username and password from the textboxes,
        // as when the user logs out the app will crash if it
        // still contains data in the textboxes and the user
        // just presses the 'login' button
        self.tblUsername.text = ""
        self.tbxPassword.text = ""
        
        // Showing the scroll container so that the textboxes
        // can be visible, if it has been hidden when trying
        // to log the user in if the app has been closed
        sclLoginTextboxes.isHidden = false
        
        // Resetting the counter to prevent any accidental uploads
        appNameTapCount = 0
        
        // Showing the HAP+ server textbox when UI Testing
        // is taking place, so that the test doesn't fail
        // See: http://stackoverflow.com/a/33774166
        // See: http://onefootball.github.io/resetting-application-data-after-each-test-with-xcode7-ui-testing/
        let args = ProcessInfo.processInfo.arguments
        if args.contains("UI_TESTING_RESET_SETTINGS") {
            logger.info("App has been launched in UI testing mode. Showing HAP+ server textbox")
            tblHAPServer.isHidden = false
            lblHAPServer.isHidden = false
            tbxHAPMultisite.isHidden = true
        } else {
            // Showing the relevant HAP+ server controls when the
            // app has focus. A "will enter forground" notification
            // is needed if the app is put into the background, the
            // multisite option changed in settings, then the app is
            // brought back again otherwise the controls do not update
            // until a login and logoff has occurred
            // See: https://stackoverflow.com/a/34529572
            showHAPServerControls()
            NotificationCenter.default.addObserver(self, selector: #selector(showHAPServerControls), name: .UIApplicationWillEnterForeground, object: nil)
            
            // Clear all items in the multisite picker to prevent them
            // being added continually when appended to below
            hapServerPickerData.removeAll()
            
            // Loading the multisite list of servers, and seeing if
            // there was any data returned
            if (loadMultisiteList()) {
                // Seeing if there is any data available before filling
                // in the multisite picker list
                if (multisiteServerList.count > 0) {
                    // Filling in the list of HAP+ servers for use in the
                    // multisite picker
                    for (hapServer, siteName) in multisiteServerList {
                        logger.debug("Adding server \(siteName) (\(hapServer)) to multisite picker list")
                        hapServerPickerData.append("\(siteName) (\(hapServer))")
                    }
                }
            }
            
            // The last item in the multisite picker should be to add
            // a new HAP+ server. This is assumed when the formatting
            // of the picker is taking place
            hapServerPickerData.append("Add new Home Access Plus+ Server")
            
            // Attempting to log the user in if they've logged in
            // before, but have closed the app (from the app switcher)
            // or restarted the device, rather than just backgrounding
            // the app
            if let username = settings!.string(forKey: settingsUsername) {
                // Hiding the view controls to prevent the user from
                // being able to do anything which may interfere with
                // the login process
                sclLoginTextboxes.isHidden = true
                
                // Filling in the username and password controls, so
                // that the loginUser function can access them
                tblUsername.text = username
                let dictionary = Locksmith.loadDataForUserAccount(userAccount: username)
                tbxPassword.text = (dictionary?[settingsPassword])! as? String
                
                // Attempt to log the user in to the HAP+ server and app
                hudShow("Checking login details")
                loginUser()
            }
        }
        
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Performs the segue to the master view controller
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-03
    ///
    /// - seealso: shouldPerformSegueWithIdentifier
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Setting the viewLoadedFromBrowsing variable to
        // be true, so that the loadFileBrowser() function
        // will be called once the login has taken place
        // This is to work around the repeated calling
        // to the above named function on app restoration
        if segue.identifier == "login.btnLoginSegue" {
            let controller = (segue.destination as! UISplitViewController).viewControllers[0] as! UINavigationController
            let masterController = controller.topViewController as! MasterViewController
            masterController.viewLoadedFromBrowsing = true
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
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
    /// - version: 2
    /// - date: 2015-12-06
    @IBAction func formatHAPURL(_ sender: AnyObject) {
        // Making sure that https:// is at the beginning of the sting.
        // This is needed as by default HAP+ server only works over https
        // See: https://hap.codeplex.com/SourceControl/changeset/87691
        let http = "http://"
        let https = "https://"
        
        hapServerAddress = tblHAPServer.text!
        logger.debug("Original HAP+ URL: \(self.hapServerAddress)")
        
        // Seeing if server has http at the start
        if (hapServerAddress.hasPrefix(http)) {
            // Replacing the http:// in the URL to be https://
            hapServerAddress = hapServerAddress.replacingOccurrences(of: http, with: https)
        } else {
            // Fix for issue #10 - See: https://github.com/stuajnht/HAP-for-iOS/issues/10
            // If the HAP+ address already includes https:// at the start, do
            // not prepend it again
            if (!hapServerAddress.hasPrefix(https)) {
                // Appending https:// to the start of the address
                hapServerAddress = https + hapServerAddress
            }
        }
        
        // Removing any trailing '/' characters, as we add these in
        // during any API calls
        if (hapServerAddress.hasSuffix("/")) {
            hapServerAddress = hapServerAddress.substring(to: hapServerAddress.characters.index(before: hapServerAddress.endIndex))
        }
        
        logger.debug("Formatted HAP+ URL: \(self.hapServerAddress)")
    }
    
    @IBAction func attemptLogin(_ sender: AnyObject) {
        // Hiding the keyboard, as if the user presses the login button
        // when the keyboard is still showing, it will cover the HUD and
        // pop up and down when any alerts are shown, which looks messy
        self.view.endEditing(true)
        
        // Seeing if the textboxes are valid before attempting
        // any login attempts
        if (textboxesValid() == false) {
            let textboxesValidAlertController = UIAlertController(title: "Incorrect Information", message: "Please check that you have entered all correct information, then try again", preferredStyle: UIAlertControllerStyle.alert)
            textboxesValidAlertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(textboxesValidAlertController, animated: true, completion: nil)
            logger.error("Login textboxes missing some information")
        } else {
            // Checking if there is an available Internet connection,
            // and if so, attempt to log the user into the HAP+ server
            hudShow("Checking Internet connection")
            
            if(api.checkConnection()) {
                // An Internet connection is available, so see if there is a
                // valid HAP+ server address
                hudUpdateLabel("Contacting HAP+ server")
                
                checkAPI(hapServerAddress, attempt: 1)
            } else {
                // Unable to connect to the Internet, so let the user know they
                // should make sure they have an active connection
                hudHide()
                
                let apiCheckConnectionController = UIAlertController(title: "Unable to access the Internet", message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.alert)
                apiCheckConnectionController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(apiCheckConnectionController, animated: true, completion: nil)
                logger.error("Unable to connect to the Internet to access the HAP+ server")
            }
        }
    }
    
    /// Shows the relevant HAP+ server controls, and message label,
    /// based on what mode the device is in
    ///
    /// When the view is shown, the relevant HAP+ server controls
    /// need to be processed to see what should be shown, such as
    /// the multiple sites picker, the HAP+ server address textbox
    /// or nothing at all if the device is set up and multiple
    /// sites is not enabled
    ///
    /// The message label is also updated depending on what has been
    /// set up. If multisite isn't enabled, then the site name is
    /// shown. Otherwise, a notice to select the school is shown.
    /// However, if there is no server set up, then the message to
    /// set up the device is shown instead
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 1.1.0-alpha
    /// - version: 2
    /// - date: 2017-06-04
    func showHAPServerControls() {
        // Seeing what combination of items for the HAP+ server
        // label, textbox and multisite should be shown. The multisite
        // textbox is hidden by default, and is shown based on what needs
        // to be available
        tbxHAPMultisite.isHidden = true
        
        // If there is a HAP+ server set in the settings, then we
        // need to see if it should be hidden as the device is set
        // up, or if the multisite picker should be shown. Otherwise,
        // the HAP+ server label and textbox should be shown
        if let hapServer = settings!.string(forKey: settingsHAPServer) {
            logger.debug("Settings for HAP+ server address exist with value: \(hapServer)")
            
            if settings!.bool(forKey: settingsMultisiteEnabled) {
                logger.debug("Multisite is enabled, so showing the multisite textbox")
                tbxHAPMultisite.isHidden = false
                tblHAPServer.isHidden = true
                lblHAPServer.isHidden = false
            } else {
                logger.debug("Multisite is not enabled, not showing any HAP+ server details")
                tblHAPServer.isHidden = true
                lblHAPServer.isHidden = true
            }
            
            tblHAPServer.text = hapServer
            
            // Checking the URL is still correct (it is) but this
            // function needs to be called otherwise when attempting
            // to log in it will say the URL is incorrect
            formatHAPURL(self)
        }
        
        // Filling in any settings that are saved for the message label
        if let siteName = settings!.string(forKey: settingsSiteName)
        {
            if settings!.bool(forKey: settingsMultisiteEnabled) {
                lblMessage.text = "Please select your school"
            } else {
                logger.info("The HAP+ server is for the site: \(siteName)")
                lblMessage.text = siteName
            }
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
    ///         this will fail on the second attempt, and let the user know. This can also
    ///         fail if the HAP+ server is not set up to use TLS 1.2 or has a SSL certificate
    ///         that is not configured correctly (self signed, expired, domain name mismatch)
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 4
    /// - date: 2016-03-18
    ///
    /// - parameter hapServer: The URL to the HAP+ server
    /// - parameter attempt: How many times this function has been called
    func checkAPI(_ hapServer: String, attempt: Int) -> Void {
        logger.info("Attempting to contact the HAP+ server at the URL: \(hapServer)")
        
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
                self.hudHide()
                
                let apiFailController = UIAlertController(title: "Unable to Contact Server", message: "The address for the HAP+ server is not valid; the server may be offline; the SSL certificate is not configured correctly; the server is not using TLS 1.2 or is not compliant with App Transport Security requirements\n\nPlease check and try again, or contact your IT department for assistance", preferredStyle: UIAlertControllerStyle.alert)
                apiFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(apiFailController, animated: true, completion: nil)
                logger.error("Unable to Contact HAP+ Server. Any of the following may be the cause: Invalid HAP+ address or server used; server may be offline; SSL certificate is incorrect; server is not using TLS 1.2 or not compliant with App Transport Security requirements. Check it is a valid address and the server is configured correctly")
            }
            if (result) {
                // Successful HAP+ API check, so we now have a fully valid
                // HAP+ server address
                self.hapServerAddress = hapServer
                
                // Saving the HAP+ server API address to use later
                settings!.set(hapServer, forKey: settingsHAPServer)
                
                // Continue with the login attempt by validating the credentials
                self.hudUpdateLabel("Checking login details")
                self.loginUser()
            }
        })
    }
    
    /// Attempting to log in user with the provided credentials
    ///
    /// Calls the HAPi loginUser() function to see if the provided credentials
    /// match those of a valid user on the network
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 7
    /// - date: 2016-03-18
    func loginUser() -> Void {
        // Checking the username and password entered are for a valid user on
        // the network
        logger.info("Attempting to log in user with typed credentials")
        self.api.loginUser(self.hapServerAddress, username: self.tblUsername.text!, password: self.tbxPassword.text!, callback: { (result: Bool) -> Void in
            // Hiding the HUD, as it doesn't matter what the result is, we
            // don't need to show it any more
            self.hudHide()
            
            // Seeing what the result is from the API logon attempt
            // The callback will be either 'true' or 'false' as this is
            // what is used in the JSON response for if the logon is valid
            if (result == true) {
                // We have successfully logged in, so set the variable to true and
                // perform the login to master view controller segue
                logger.info("Successfully logged in user to HAP+")
                
                // Updating the school name. This is needed to get around
                // the "Please set up this device" message still being
                // shown after the very first login and logout
                if let siteName = settings!.string(forKey: settingsSiteName) {
                    self.lblMessage.text = siteName
                }
                
                // Saving the new HAP+ server address and site name to the
                // multisite variable, so that it can be used by the multisite
                // picker should it be enabled
                self.updateMultisiteList()
                
                // Starting the startAPITestCheckTimer from the AppDelegate,
                // to keep the user logon tokens valid, as it wouldn't have
                // been started if a user wasn't logged in on app launch
                logger.debug("Starting API test check timer to keep logon tokens valid")
                let delegate = UIApplication.shared.delegate as? AppDelegate
                delegate!.startAPITestCheckTimer()
                
                // Find out what the device should be set up as: Personal, Shared
                // or Single so that it can be used later. This is shown run if it
                // hasn't been set before (i.e. the very first setup of this device)
                if let deviceType = settings!.string(forKey: settingsDeviceType) {
                    // Device is set up, so nothing to do here
                    logger.info("This device is set up in \(deviceType) mode")
                } else {
                    let loginUserDeviceType = UIAlertController(title: "Please Select Device Type", message: "Personal - A device you have bought\nShared - School owned class set\nSingle - School owned 1:1 scheme", preferredStyle: UIAlertControllerStyle.alert)
                    loginUserDeviceType.addAction(UIAlertAction(title: "Personal", style: UIAlertActionStyle.default, handler: {(alertAction) -> Void in
                        self.setDeviceType("personal") }))
                    loginUserDeviceType.addAction(UIAlertAction(title: "Shared", style: UIAlertActionStyle.default, handler: {(alertAction) -> Void in
                        self.setDeviceType("shared") }))
                    loginUserDeviceType.addAction(UIAlertAction(title: "Single", style: UIAlertActionStyle.default, handler: {(alertAction) -> Void in
                        self.setDeviceType("single") }))
                    self.present(loginUserDeviceType, animated: true, completion: nil)
                }
                
                // Performing the segue to the master detail view
                self.successfulLogin = true
                self.performSegue(withIdentifier: "login.btnLoginSegue", sender: self)
            } else {
                // Inform the user they didn't have a valid username or password
                logger.error("The username or password was not valid")
                let loginUserFailController = UIAlertController(title: "Invalid Username or Password", message: "The username and password combination is not valid. Please check and try again", preferredStyle: UIAlertControllerStyle.alert)
                loginUserFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(loginUserFailController, animated: true, completion: nil)
                
                // Showing the login textboxes scroll area, as it may
                // have been hidden if the user has opened up the
                // app from the beginning, and not from app restoration
                self.sclLoginTextboxes.isHidden = false
            }
        })
    }
    
    /// Set up the type of device this is
    ///
    /// A device can be in one of three states, which are:
    ///   * Personal - A device a user has bought themselves
    ///   * Shared - A device that is owned by the school, and 
    ///              part of a class set
    ///   * Single - A device owned by the school, in a 1:1 scheme
    ///
    /// During the initial login attempt and setup, the user is
    /// presented with the option to choose one of these three options
    /// in the form of an alert. Once the user has made their choice, it
    /// is saved here into the settings, and then the segue to the master
    /// detail view is completed
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-beta
    /// - version: 1
    /// - date: 2015-12-09
    ///
    /// - param deviceType: The type of device this is going to be
    func setDeviceType(_ deviceType: String) {
        logger.info("This device is being set up in \(deviceType) mode")
        settings!.set(deviceType, forKey: settingsDeviceType)
        // Performing the segue to the master detail view
        self.successfulLogin = true
        self.performSegue(withIdentifier: "login.btnLoginSegue", sender: self)
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
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
    
    /// Checks to see if all of the textboxes on the login view contain
    /// valid data before attempting to perform any logon attempts
    ///
    /// All textboxes on the login view need to have data filled in on them
    /// so that it can be used for the logon attempts. If any of these are
    /// blank, then the textboxes are not valid. The HAP+ address also needs
    /// to be a valid URL as well, which while this partially gets created
    /// and formatted when the user leaves the relevant textbox, we need to
    /// check that there are no invalid characters in the URL
    ///
    /// For any attemps that are not valid, the relevant form controls are
    /// highlighted so the user knows what needs to be corrected
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 1
    /// - date: 2015-12-06
    /// - seealso: formatHAPURL
    ///
    /// - returns: Are all of the textboxes validated and filled in properly
    func textboxesValid() -> Bool {
        var valid = true
        
        // Length validation checks
        if (tblHAPServer.text == "") {
            valid = false
            tblHAPServer.textColor = UIColor.flatRed()
            tblHAPServer.layer.borderColor = UIColor.flatYellowColorDark().cgColor
            tblHAPServer.layer.borderWidth = 2
            logger.warning("HAP+ server address missing")
        } else {
            tblHAPServer.textColor = UIColor.flatBlack()
            tblHAPServer.layer.borderColor = UIColor.flatBlack().cgColor
            tblHAPServer.layer.borderWidth = 0
        }
        
        if (tblUsername.text == "") {
            valid = false
            tblUsername.textColor = UIColor.flatRed()
            tblUsername.layer.borderColor = UIColor.flatYellowColorDark().cgColor
            tblUsername.layer.borderWidth = 2
            logger.warning("Username missing")
        } else {
            tblUsername.textColor = UIColor.flatBlack()
            tblUsername.layer.borderColor = UIColor.flatBlack().cgColor
            tblUsername.layer.borderWidth = 0
        }
        
        if (tbxPassword.text == "") {
            valid = false
            tbxPassword.textColor = UIColor.flatRed()
            tbxPassword.layer.borderColor = UIColor.flatYellowColorDark().cgColor
            tbxPassword.layer.borderWidth = 2
            logger.warning("Password missing")
        } else {
            tbxPassword.textColor = UIColor.flatBlack()
            tbxPassword.layer.borderColor = UIColor.flatBlack().cgColor
            tbxPassword.layer.borderWidth = 0
        }
        
        // URL Regex checking
        // See: http://code.tutsplus.com/tutorials/8-regular-expressions-you-should-know--net-6149
        // See: http://stackoverflow.com/a/24207852
        let urlPattern = "(https:\\/\\/)((\\w|\\d|-)+\\.)+(\\w|\\d){2,6}(\\/(\\w|\\d|\\+|-)+)*"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlPattern])
        if (predicate.evaluate(with: hapServerAddress) == false) {
            valid = false
            tblHAPServer.textColor = UIColor.flatRed()
            tblHAPServer.layer.borderColor = UIColor.flatYellowColorDark().cgColor
            tblHAPServer.layer.borderWidth = 2
            logger.warning("HAP+ server address is an invalid format")
        } else {
            tblHAPServer.textColor = UIColor.flatBlack()
            tblHAPServer.layer.borderColor = UIColor.flatBlack().cgColor
            tblHAPServer.layer.borderWidth = 0
        }
        
        logger.info("Login textboxes valid: \(valid)")
        return valid
    }
    
    // MARK: MBProgressHUD
    // The following functions look after showing the HUD during the login
    // progress so that the user knows that something is happening
    // See: http://www.raywenderlich.com/97014/use-cocoapods-with-swift
    // See: https://github.com/jdg/MBProgressHUD/blob/master/Demo/Classes/HudDemoViewController.m
    // See: http://stackoverflow.com/a/26882235
    // See: http://stackoverflow.com/a/32285621
    func hudShow(_ detailLabel: String) {
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Please wait..."
        hud.detailsLabel.text = detailLabel
    }
    
    /// Updating the detail label that is shown in the HUD
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-beta
    /// - version: 1
    /// - date: 2015-12-08
    /// - seealso: hudShow
    /// - seealso: hudHide
    ///
    /// - parameter labelText: The text that should be shown for the HUD label
    func hudUpdateLabel(_ labelText: String) {
        hud.detailsLabel.text = labelText
    }
    
    func hudHide() {
        hud.hide(animated: true)
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
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications() {
        // Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWasShown(_ notification: Notification) {
        // Need to calculate keyboard exact size due to Apple suggestions
        self.sclLoginTextboxes.isScrollEnabled = true
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        self.sclLoginTextboxes.contentInset = contentInsets
        self.sclLoginTextboxes.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
        if let _ = activeField {
            if (!aRect.contains(activeField!.frame.origin)) {
                self.sclLoginTextboxes.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(_ notification: Notification) {
        // Once keyboard disappears, restore original positions
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize!.height, 0.0)
        self.sclLoginTextboxes.contentInset = contentInsets
        self.sclLoginTextboxes.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.sclLoginTextboxes.isScrollEnabled = false
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        
        // Showing the multisite picker if the relevant textbox
        // has been tapped
        if (textField == tbxHAPMultisite) {
            logger.info("Showing the multisite picker")
            self.pickUpValue(textField: textField)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
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
    
    // MARK: Log Files
    
    /// Emails log files from the app if the user cannot log in
    ///
    /// Should the user have problems with the app and need to view
    /// the log files, but cannot log in, then pressing on the
    /// app name label 10 times will zip the log files up and create
    /// an email message with them attached
    ///
    /// See: https://gist.github.com/kellyegan/49e3e11fe68b5e6b5360
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.9.0-alpha
    /// - version: 2
    /// - date: 2017-01-21
    func emailLogFiles() {
        // Seeing how many times the app name label has been pressed
        // Note: The count is not reset after the email has been
        //       attempted to prevent users repeatedly pressing the
        //       label. If the app is closed or sent to the background
        //       then this is how the counter will be reset. The +1 in
        //       the 'if' statement is due to counting beginning at 0
        appNameTapCount += 1
        if ((appNameTapCount + 1) == 10) {
            logger.info("App name has been pressed 10 times, so attempting to email log files")
            
            // Check to see the device can send email and creating a
            // zip file of all the logs
            if((MFMailComposeViewController.canSendMail()) && (zipLogFiles())) {
                logger.debug("Email can be sent from this device")
                
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                
                // Set the subject and attach the zip files
                mailComposer.setSubject("Home Access Plus+ -- App Log Files")
                
                // Generating the attachment information
                // The string replacement is needed as the file name
                // generated seems to appeand an additional ") to it
                let fileName = String(describing: settings!.string(forKey: settingsUploadPhotosLocation)).components(separatedBy: "/").last!.replacingOccurrences(of: "\")", with: "")
                let fileData = NSData(contentsOf: URL(string: settings!.string(forKey: settingsUploadPhotosLocation)!)!)
                mailComposer.addAttachmentData(fileData as Data!, mimeType: "application/zip", fileName: fileName)
                
                self.present(mailComposer, animated: true, completion: nil)
            } else {
                logger.error("There was a problem emailing the log files from the device")
            }
        }
    }
    
    /// Saves all log files on the device into a zip file to
    /// be uploaded to the current folder
    ///
    /// If file logging is enabled from the main iOS Settings
    /// app, then log files are generated on the device in the
    /// applicationSupportDirectory under a "logs" folder. When
    /// the user wants to upload these files to aid in debugging
    /// they will select the reveleant option from the upload
    /// popover to call this function. It will zip all log files
    /// together so that they can be uploaded
    ///
    /// See: http://stackoverflow.com/a/27722526
    /// See: https://github.com/marmelroy/Zip
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.9.0-alpha
    /// - version: 2
    /// - date: 2017-01-15
    ///
    /// - returns: Were the logs able to be zipped
    func zipLogFiles() -> Bool {
        logger.info("Creating zip file of all device logs")
        
        let logFileDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("logs", isDirectory: true)
        
        logger.debug("Using logs located in: \(logFileDirectory)")
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: logFileDirectory, includingPropertiesForKeys: nil, options: [])
            logger.verbose("Contents of logs directory: \(directoryContents)")
            
            let zipFile = logFileDirectory.appendingPathComponent("hap-ios-app-logs.zip")
            
            // Attempting to delete any previous zip files so that the one
            // being uploaded can be created fresh
            logger.debug("Attempting to delete any previous zip files")
            do {
                try FileManager.default.removeItem(at: zipFile)
                logger.debug("Successfully deleted previous zip file")
            }
            catch let errorMessage as NSError {
                logger.error("There was a problem deleting the file. Error: \(errorMessage)")
            }
            catch {
                logger.error("There was an unknown problem when deleting the previous zip file")
            }
            
            // Creating the zip file of all log files
            try Zip.zipFiles(paths: [logFileDirectory], zipFilePath: zipFile, password: nil, progress: nil)
            logger.debug("Logs zip file created and located at: \(zipFile)")
            
            // Due to the way the URL location of the file on the device is
            // processed in the HAPi upload function, we cannot just save the
            // zip file path to the settingsUploadFileLocation value, so it is
            // saved in the location normally used for uploading media files
            settings!.set(String(describing: zipFile), forKey: settingsUploadPhotosLocation)
            
            // Attempting to delete log files, to save space on the device and prevent
            // them appearing in future zip files
            let logFiles = directoryContents.filter{ $0.pathExtension == "log" }
            for (_, logFile) in logFiles.enumerated() {
                do {
                    try FileManager.default.removeItem(at: logFile)
                    logger.debug("Successfully deleted log file: \(logFile)")
                }
                catch let errorMessage as NSError {
                    logger.error("There was a problem deleting the file. Error: \(errorMessage)")
                }
                catch {
                    logger.error("There was an unknown problem when deleting the log file")
                }
            }
            
            return true
        } catch let error as NSError {
            logger.error("There was a problem creating the zipped logs file: \(error.localizedDescription)")
            logger.error("If we've ended up here then there's not an option to get the log files from the device")
            logger.error("Hopefully on another run of this app they are able to be collected")
            return false
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Multisite
    
    /// Saves and updates the list of HAP+ servers and site names
    /// that the app has connected to, both for this class property
    /// multisiteServerList, but also to the NSUserDefaults so that
    /// it is available between app restarts
    ///
    /// It is assumed that some sanity checking has been completed
    /// to make sure that only once instance of the site exists before
    /// attempting to save it with this function
    ///
    /// See: https://stackoverflow.com/a/36790465
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 1.1.0-alpha
    /// - version: 1
    /// - date: 2017-06-07
    func updateMultisiteList() {
        multisiteServerList[settings!.string(forKey: settingsHAPServer)!] = settings!.string(forKey: settingsSiteName)
        let archiver = NSKeyedArchiver.archivedData(withRootObject: multisiteServerList)
        settings!.set(archiver, forKey: settingsMultisiteServerList)
    }
    
    /// Loads the list of HAP+ servers and site names used by the
    /// multisite picker
    ///
    /// See: https://stackoverflow.com/a/36790465
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 1.1.0-alpha
    /// - version: 1
    /// - date: 2017-06-07
    ///
    /// - returns: Did the multisite server list load successfully
    func loadMultisiteList() -> Bool {
        
        // Check if data exists
        guard let data = settings!.object(forKey: settingsMultisiteServerList) else {
            return false
        }
        
        // Check if retrieved data has correct type
        guard let retrievedData = data as? Data else {
            return false
        }
        
        // Unarchive data
        multisiteServerList = NSKeyedUnarchiver.unarchiveObject(with: retrievedData) as! [String : String]
        logger.debug("Loaded the multisite server list: \(multisiteServerList)")
        return true
    }
    
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return hapServerPickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return hapServerPickerData[row]
    }
    
    // Processing the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        logger.debug("The following site has been selected from the multisite server picker: row \(row), server: \(hapServerPickerData[row])")
        tbxHAPMultisite.text = hapServerPickerData[row]
    }
    
    // Aligning the text to the left and reducing the font size
    // See: https://stackoverflow.com/a/32026170
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        // Manual spaces are included to pad the contents
        // of the picker
        let titleData = "   " + hapServerPickerData[row]
        
        // Using the default system font, and setting the last
        // item (add new HAP+ server) to be bold
        // See: https://stackoverflow.com/a/40797423
        var myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 17),NSForegroundColorAttributeName:UIColor.black])
        if (row == hapServerPickerData.count - 1) {
            myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 17, weight: UIFontWeightSemibold),NSForegroundColorAttributeName:UIColor.black])
        }
        pickerLabel.attributedText = myTitle
        
        return pickerLabel
    }
    
    // Aligning the text to the left and reducing the font size
    // See: https://stackoverflow.com/a/32026170
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        // Manual spaces are included to pad the contents
        // of the picker
        let titleData = "   " + hapServerPickerData[row]
        
        // Using the default system font, and setting the last
        // item (add new HAP+ server) to be bold
        // See: https://stackoverflow.com/a/40797423
        var myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 17),NSForegroundColorAttributeName:UIColor.black])
        if (row == hapServerPickerData.count - 1) {
            myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 17, weight: UIFontWeightSemibold),NSForegroundColorAttributeName:UIColor.black])
        }
        
        return myTitle
    }
    
    // Dynamically generates a picker view when the multisite
    // textbox is tapped
    // See: http://www.spidersoft.com.au/2016/dynamic-pickerview-in-swift-3/
    func pickUpValue(textField: UITextField) {
        
        logger.debug("Getting ready to display the multisite picker")
        
        // create frame and size of picker view
        pkrHAPServer = UIPickerView(frame:CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: self.view.frame.size.width, height: 216)))
        
        // deletates
        pkrHAPServer.delegate = self
        pkrHAPServer.dataSource = self
        
        // Seeing if there is a value in current text field,
        // try to find it existing list and select it
        if let currentValue = textField.text {
            var row : Int?
            row = hapServerPickerData.index(of: currentValue)
            
            // we got it, let's set select it
            if row != nil {
                pkrHAPServer.selectRow(row!, inComponent: 0, animated: true)
            }
        }
        
        pkrHAPServer.backgroundColor = UIColor.white
        textField.inputView = self.pkrHAPServer
        textField.hideAssistantBar()
        
        // toolBar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        // buttons for toolBar
        let doneButton = UIBarButtonItem(title: "Select", style: .done, target: self, action: #selector(doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
        
    }
    
    // done
    func doneClick() {
        activeField?.resignFirstResponder()
        
    }
    
    // cancel
    func cancelClick() {
        activeField?.resignFirstResponder()
    }

}

// Removes the assistant shortcuts that iOS keyboard
// contains, for use with the multisite picker
// See: https://stackoverflow.com/a/33641391
extension UITextField
{
    /// Prevents the shortcut bar being shown for the
    /// multisite picker control, as it serves no purpose
    public func hideAssistantBar()
    {
        if #available(iOS 9.0, *) {
            let assistant = self.inputAssistantItem;
            assistant.leadingBarButtonGroups = [];
            assistant.trailingBarButtonGroups = [];
        }
    }
}
