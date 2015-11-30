//
//  DetailViewController.swift
//  HomeAccessPlus
//
//  Created by Jonathan Hart on 28/11/2015.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import ChameleonFramework

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        
        // Adding navigation back button to detail view, to show the master view, as it is
        // removed from the AppDelegate.swift file
        // See: http://nshipster.com/uisplitviewcontroller/
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        // Setting the navigation bar colour
        self.navigationController!.navigationBar.barTintColor = UIColor.flatSkyBlueColorDark()
        self.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController!.navigationBar.translucent = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

