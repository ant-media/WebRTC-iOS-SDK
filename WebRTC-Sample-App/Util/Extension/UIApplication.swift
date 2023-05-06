//
//  UIApplication.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 11.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit

public extension UIApplication {
    
    static func presentView(_ view: UIViewController) {
        if (view.isBeingPresented) {
            return
        }
        
        let window = UIApplication.shared.keyWindow!
        
        if let modalVC = window.rootViewController?.presentedViewController {
            modalVC.present(view, animated: true, completion: nil)
        } else {
            window.rootViewController!.present(view, animated: true, completion: nil)
        }
    }
}
