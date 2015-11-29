//
//  LoginViewController.swift
//  HomeAccessPlus
//
//  Created by Jonathan Hart on 29/11/2015.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import ChameleonFramework

class LoginViewController: UIViewController {
    
    @IBOutlet weak var lblAppName: UILabel!
    @IBOutlet weak var btnLogin: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setting up the colours for the login scene
        view.backgroundColor = UIColor.flatSkyBlueColorDark()
        lblAppName.textColor = UIColor.flatWhiteColor()
        btnLogin.tintColor = UIColor.flatWhiteColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
