//
//  ViewController.swift
//  AntMediaReferenceApplication
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit
import WebRTCiOSSDK
import ReplayKit

@available(iOS 12.0, *)
class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var screenRecord: RPSystemBroadcastPickerView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var logoTopAnchor: NSLayoutConstraint!
    
    @IBOutlet weak var actionContainer: UIView!;
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
                    self.sharedDefault.set(server, forKey:"url");

                }
            }
        }
    }
    
    var clientUrl: String!
    var clientRoom: String!
    var clientToken: String!
    var isConnected = false
    var tapGesture: UITapGestureRecognizer!
    // original: group.io.antmedia.ios.webrtc.sample
    let sharedDefault = UserDefaults(suiteName: "group.io.antmedia.sbd.webrtc.sample")! // for test
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set the default video and audio values for screen broadcasting extension
        sharedDefault.set("true", forKey:"videoEnabled");
        sharedDefault.set("true", forKey:"audioEnabled");
    }
    
    @IBAction func streamIdEntered(_ sender: Any)
    {
        sharedDefault.set(self.roomField.text , forKey: "streamId")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setGesture()
        
        self.screenRecord.preferredExtension = "io.antmedia.ios.WebRTC-Sample-App.ScreenShare";
        self.screenRecord.showsMicrophoneButton = false;

        self.roomField.text = "stream1"
        sharedDefault.set(self.roomField.text , forKey: "streamId")
        
    }
    
    @IBAction func connectButton(_ sender: UIButton ) {
        if roomField.text!.count == 0 {
            AlertHelper.getInstance().show("Caution!", message: "Please fill room field")
        } else if (Defaults[.server] ?? "").count < 2 {
            AlertHelper.getInstance().show("Caution!", message: "Please set server ip")
        } else {
            self.clientUrl = Defaults[.server]!
            self.clientRoom = roomField.text!
            
            self.clientToken = ""
            
            self.showVideo()
        }
    }
    
    @IBAction func refreshTapped(_ sender: UIButton) {
        if let room = Defaults[.room] {
            self.roomField.text = room
        }
    }
    
    @IBAction func serverTapped(_ sender: UIButton) {
        
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Server WebSocket URL", message: "Please enter the full url like \n ws://192.168.7.25:5080/WebRTCAppEE/websocket", preferredStyle: .alert)

        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text =  Defaults[.server]
        }

        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            guard let textValue =  alert?.textFields?.first?.text else {
                return
            }
            
            AntMediaClient.printf("Text field: \(textValue)")
            self.serverButton.setTitle("Server ip: \(textValue)", for: .normal)
            
            Defaults[.server] = textValue
            self.sharedDefault.set(textValue, forKey:"url");
        }))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }
    
    private func setGesture() {
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(WelcomeViewController.toggleContainer))
        self.tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func getMode() -> AntMediaClientMode {
        switch self.modeSelection.selectedSegmentIndex {
            case 0:
                return AntMediaClientMode.publish
            case 1:
                return AntMediaClientMode.play
            case 2:
                return AntMediaClientMode.conference
            case 3:
                return AntMediaClientMode.join
            default:
                return AntMediaClientMode.publish
        }
    }
    
    @objc private func toggleContainer() {
        self.view.endEditing(true)
    }
    
    private func showVideo()
    {
        if self.modeSelection.selectedSegmentIndex == 3 {
            self.show(ShareScreenController(), sender: nil)
            return
        }
        
        if self.getMode() != AntMediaClientMode.conference {
            let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Video") as! VideoViewController
            controller.clientUrl = self.clientUrl
            controller.clientStreamId = self.clientRoom
            controller.clientToken = self.clientToken
            controller.clientMode = self.getMode()
            self.show(controller, sender: nil)
        }
        else {
            let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Conference") as! ConferenceViewController;
            controller.clientUrl = self.clientUrl;
            controller.roomId = self.clientRoom;
            
           self.show(controller, sender: nil)
        }
         
    }
}
