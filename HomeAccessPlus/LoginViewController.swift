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
    
    @IBAction func attemptLogin(sender: AnyObject) {
        //logger.debug("Attempt login result: \(api.checkAPI(tblHAPServer.text!))")
        checkAPI(tblHAPServer.text!)
    }
    
    func checkAPI(hapServer: String) -> Void {
        api.checkAPI(hapServer, callback: { (result: Bool) -> Void in
            logger.debug("Check API success: \(result)")
            if (result == false) {
                let apiFailController = UIAlertController(title: "Invalid HAP+ Address", message: "The address that you have entered for the HAP+ server is not valid", preferredStyle: UIAlertControllerStyle.Alert)
                apiFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(apiFailController, animated: true, completion: nil)
            } else {
                let apiSuccessController = UIAlertController(title: "Valid HAP+ Address", message: "The address that you have entered for the HAP+ server is valid", preferredStyle: UIAlertControllerStyle.Alert)
                apiSuccessController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(apiSuccessController, animated: true, completion: nil)
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
