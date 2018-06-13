//
//  ViewController.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 11.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var logoTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var actionContainer: UIView! {
        didSet {
            self.actionContainer.alpha = 0
        }
    }
    @IBOutlet weak var roomField: UITextField!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var modeSelection: UISegmentedControl!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var serverButton: UIButton! {
        didSet {
            if let server = Defaults[.server] {
                if (server.count > 0) {
                    self.serverButton.setTitle("Server ip: http://\(server)/", for: .normal)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut, animations: {
            self.logoTopAnchor.constant = 40
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            UIView.animate(withDuration: 0.5, animations: {
                self.actionContainer.alpha = 1
                self.view.layoutIfNeeded()
            })
        })
    }
    
    @IBAction func refreshTapped(_ sender: UIButton) {
        if let room = Defaults[.room] {
            self.roomField.text = room
        }
    }
    
    @IBAction func connectButton(_ sender: UIButton ) {
        
    }
    
    @IBAction func serverTapped(_ sender: UIButton) {
        AlertHelper.getInstance().addOption("Save", onSelect: {
            (address) in
            if (address!.count > 0) {
                self.serverButton.setTitle("Server ip: http://\(address!)/", for: .normal)
                Defaults[.server] = address
            } else {
                self.serverButton.setTitle("Set server ip", for: .normal)
                Defaults[.server] = ""
            }
        })
        AlertHelper.getInstance().showInput(self, title: "IP Address", message: "Please enter your server address (no need protocol)")
    }
}
