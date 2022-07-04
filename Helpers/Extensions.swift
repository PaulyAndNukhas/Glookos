//
//  Extensions.swift
//  GlucoseDirectApp
//
//  Created by Paul Silver on 02/07/2022.
//

import Foundation
import SwiftUI

// MARK: Customisation Options for Navigation Bar
extension View{
    
    func setNavbarColor(color: Color) {
     
        // MARK: Updating Nav Bar Color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            
            NotificationCenter.default.post(name: NSNotification.Name("UPDATENAVBAR"), object: nil, userInfo: [
                "color": color
            ])
              
        }
    }
    func resetNavBar() {
        // MARK: Reset the Navbar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            
            NotificationCenter.default.post(name: NSNotification.Name("UPDATENAVBAR"), object: nil)
              
        }
    }
    func setNavbarTitleColor(color: Color) {
        
    }
}


extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        
       // navigationBar.largeTitleTextAttributes = [.foregroundColor : UIColor.green]
       // navigationBar.titleTextAttributes = [.foregroundColor : UIColor.blue]
        
        //MARK: Notification Observer
        NotificationCenter.default.addObserver(self, selector: #selector(updateNavBar(notification: )), name: NSNotification.Name("UPDATENAVBAR"), object: nil)
    }
    
    @objc
    func updateNavBar(notification: Notification){
        if let info = notification.userInfo{
            
            let color = info["color"] as! Color
            let apperance = UINavigationBarAppearance()
            
            apperance.backgroundColor = UIColor(color)
            
            navigationBar.standardAppearance = apperance
            navigationBar.scrollEdgeAppearance = apperance
            navigationBar.compactAppearance = apperance
            
        } else {
            // MARK: Reset Nav Bar
            let apperance = UINavigationBarAppearance()
            
            navigationBar.standardAppearance = apperance
            navigationBar.scrollEdgeAppearance = apperance
            navigationBar.compactAppearance = apperance
            
        }
    }
}
