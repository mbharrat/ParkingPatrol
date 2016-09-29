//
//  MyTabBarControllerViewController.swift
//  ParkApp
//
//  Created by Michael Bharrat on 7/13/16.
//  Copyright © 2016 Michael Bharrat. All rights reserved.
//

import UIKit

class MyTabBarControllerViewController: UITabBarController, UITabBarControllerDelegate {

    
    @IBOutlet var tabber: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = delegate

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func tabBar(tabBar: UITabBar, didBeginCustomizingItems items: [UITabBarItem]) {
        print("Selected item")
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
