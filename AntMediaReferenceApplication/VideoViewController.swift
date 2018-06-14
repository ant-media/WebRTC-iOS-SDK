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
    
    var client: AntMediaClient!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
