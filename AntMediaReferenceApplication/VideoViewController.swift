//
//  VideoViewController.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 14.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit
import AntMediaSDK
import WebRTC

class VideoViewController: UIViewController {
    
    @IBOutlet weak var localVideoView: RTCEAGLVideoView!
    @IBOutlet weak var remoteVideoView: RTCEAGLVideoView!
    
    var client: AntMediaClient! {
        didSet {
            self.client.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.client.setVideoViews(local: localVideoView, remote: remoteVideoView)
        self.client.start()
    }
    
    @IBAction func closeTapped(_ sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension VideoViewController: AntMediaClientDelegate {
    
    func clientDidConnect(_ client: AntMediaClient) {
        print("Connected")
    }
    
    func clientDidDisconnect(_ message: String) {
        print("Disconnected")
    }
    
}
