//
//  LaunchScreenViewController.swift
//  Chores
//
//  Created by Edmund Tian on 1/8/17.
//  Copyright © 2017 Edmoneh. All rights reserved.
//

import UIKit

class LaunchScreenViewController: UIViewController {
    
    @IBOutlet weak var houseLogo: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let screen = self.view.frame
        // Do any additional setup after loading the view.
        houseLogo.frame = CGRect(x: 0, y: 0, width: screen.height * 0.25, height: screen.height * 0.25)
        houseLogo.center.x = self.view.center.x
        houseLogo.center.y = self.view.center.y
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
