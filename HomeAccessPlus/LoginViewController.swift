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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var lblAppName: UILabel!
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var tblHAPServer: UITextField!
    @IBOutlet weak var lblHAPServer: UILabel!
    @IBOutlet weak var tblUsername: UITextField!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var tbxPassword: UITextField!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var btnLogin: UIButton!
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // Seeing if all of the login checks have completed successfully
    var successfulLogin = false
    
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
            return successfulLogin
        }
        
        // By default, perform the transition
        return true
    }
    
    @IBAction func attemptLogin(sender: AnyObject) {
        // Checking if there is an available Internet connection,
        // and if so, attempt to log the user into the HAP+ server
        if(api.checkConnection()) {
            checkAPI(tblHAPServer.text!, attempt: 1)
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
            if (result == false) {
                let apiFailController = UIAlertController(title: "Invalid HAP+ Address", message: "The address that you have entered for the HAP+ server is not valid", preferredStyle: UIAlertControllerStyle.Alert)
                apiFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(apiFailController, animated: true, completion: nil)
            } else {
                // Successful HAP+ API check, so continue with the login attempt
                // - TODO: Remove this as it's just in for testing, and replace with next login check
                self.successfulLogin = true
                self.performSegueWithIdentifier("login.btnLoginSegue", sender: self)
            }
        })
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
