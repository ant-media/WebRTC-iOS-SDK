//
//  ViewController.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 11.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit
import AntMediaSDK

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var logoTopAnchor: NSLayoutConstraint!
    @IBOutlet weak var actionContainer: UIView! {
        didSet {
            self.actionContainer.alpha = 0
        }
    }
    @IBOutlet weak var roomField: UITextField!
    @IBOutlet weak var tokenField: UITextField!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var modeSelection: UISegmentedControl!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var serverButton: UIButton! {
        didSet {
            if let server = Defaults[.server] {
                if (server.count > 0) {
                    self.serverButton.setTitle("Server ip: \(server)", for: .normal)
                }
            }
        }
    }
    @IBOutlet weak var helpButton: UIButton! {
        didSet {
            self.helpButton.alpha = 0
        }
    }
    
    let client = AntMediaClient.init()
    var clientUrl: String!
    var clientRoom: String!
    var clientToken: String!
    var isConnected = false
    var tapGesture: UITapGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        client.delegate = self
        client.setDebug(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setGesture()
        
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut, animations: {
            self.logoTopAnchor.constant = 40
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            UIView.animate(withDuration: 0.5, animations: {
                self.actionContainer.alpha = 1
                self.helpButton.alpha = 1
                self.view.layoutIfNeeded()
            })
        })
    }
    
    @IBAction func connectButton(_ sender: UIButton ) {
        if roomField.text!.count == 0 {
            AlertHelper.getInstance().show("Caution!", message: "Please fill room field")
        } else if (Defaults[.server] ?? "").count < 2 {
            AlertHelper.getInstance().show("Caution!", message: "Please set server ip")
        } else {
            self.clientUrl = Defaults[.server]!
            self.clientRoom = roomField.text!
            
            if (!tokenField.text!.isEmpty) {
                self.clientToken = tokenField.text!
            } else {
                self.clientToken = ""
            }
            
            if client.isConnected() {
                self.showVideo()
            } else {
                client.delegate = self
                client.setOptions(url: self.clientUrl, streamId: self.clientRoom, token: self.clientToken, mode: self.getMode())
                client.connect()
            }
        }
    }
    
    @IBAction func refreshTapped(_ sender: UIButton) {
        if let room = Defaults[.room] {
            self.roomField.text = room
        }
    }
    
    @IBAction func serverTapped(_ sender: UIButton) {
        AlertHelper.getInstance().addOption("Save", onSelect: {
            (address) in
            if (address!.count > 0) {
                self.serverButton.setTitle("Server ip: \(address!)", for: .normal)
                Defaults[.server] = address
            } else {
                self.serverButton.setTitle("Set server ip", for: .normal)
                Defaults[.server] = ""
            }
        })
        AlertHelper.getInstance().showInput(self, title: "IP Address", message: "Please enter your server address with protocol (ws or wss)")
    }
    
    private func setGesture() {
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(WelcomeViewController.toggleContainer))
        self.tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func getMode() -> AntMediaClientMode {
        switch self.modeSelection.selectedSegmentIndex {
            case 0:
                return AntMediaClientMode.join
            case 1:
                return AntMediaClientMode.play
            case 2:
                return AntMediaClientMode.publish
            default:
                return AntMediaClientMode.join
        }
    }
    
    @objc private func toggleContainer() {
        self.view.endEditing(true)
    }
    
    private func showVideo() {
        let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Video") as! VideoViewController
        controller.clientUrl = self.clientUrl
        controller.clientStreamId = self.clientRoom
        controller.clientToken = self.clientToken
        controller.clientMode = self.getMode()
        self.show(controller, sender: nil)
    }
}

extension WelcomeViewController: AntMediaClientDelegate {

    func clientDidConnect(_ client: AntMediaClient) {
        print("WelcomeViewController: Connected")
        Defaults[.room] = roomField.text!
        self.isConnected = true
        self.showVideo()
    }
    
    func clientDidDisconnect(_ message: String) {
        print("WelcomeViewController: Disconnected: \(message)")
        self.isConnected = false
        AlertHelper.getInstance().show("Caution!", message: "Could not connect: \(message)")
    }
    
    func clientHasError(_ message: String) {
        print("clientHasError: \(message)")
    }
    
    func remoteStreamRemoved() {}
    func remoteStreamStarted() {}
    func localStreamStarted() {}
}
