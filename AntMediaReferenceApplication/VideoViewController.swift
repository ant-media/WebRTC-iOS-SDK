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
    @IBOutlet weak var containerView: UIView!
    
    // Auto Layout Constraints used for animations
    @IBOutlet weak var remoteViewTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewRightConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var containerLeftConstraint: NSLayoutConstraint?
    
    var client: AntMediaClient! {
        didSet {
            self.client.setDebug(false)
            self.client.delegate = self
        }
    }
    var tapGesture: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.client.setVideoViews(local: localVideoView, remote: remoteVideoView)
        self.client.start()
        self.setGesture()
    }
    
    @IBAction func audioTapped(_ sender: UIButton!) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func videoTapped(_ video: UIButton!) {
        video.isSelected = !video.isSelected
    }
    
    @IBAction func closeTapped(_ sender: UIButton!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setGesture() {
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoViewController.toggleContainer))
        self.tapGesture.numberOfTapsRequired = 1
        self.remoteVideoView.addGestureRecognizer(tapGesture)
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleContainer() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if (self.containerLeftConstraint!.constant <= -45.0) {
                self.containerLeftConstraint!.constant = 15.0
                self.containerView.alpha = 1.0
            } else {
                self.containerLeftConstraint!.constant = -45.0
                self.containerView.alpha = 0.0
            }
            self.view.layoutIfNeeded()
        })
    }
}

extension VideoViewController: AntMediaClientDelegate {
    
    func clientDidConnect(_ client: AntMediaClient) {
        print("Connected")
    }
    
    func clientDidDisconnect(_ message: String) {
        print("Disconnected")
    }
    
    func remoteStreamStarted() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                let containerWidth: CGFloat = self.view.frame.size.width
                let containerHeight: CGFloat = self.view.frame.size.height
                let defaultAspectRatio: CGSize = CGSize(width: 4, height: 3)
                
                let aspectRatio: CGSize = defaultAspectRatio
                let videoRect: CGRect = self.view.bounds
                let videoFrame: CGRect = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                
                self.remoteViewTopConstraint!.constant = (containerHeight / 2.0 - videoFrame.size.height / 2.0)
                self.remoteViewBottomConstraint!.constant = (containerHeight / 2.0 - videoFrame.size.height / 2.0) * -1
                self.remoteViewLeftConstraint!.constant = (containerWidth / 2.0 - videoFrame.size.width / 2.0)
                self.remoteViewRightConstraint!.constant = (containerWidth / 2.0 - videoFrame.size.width / 2.0)
            }, completion: { _ in
                self.localVideoView.bringSubview(toFront: self.remoteVideoView)
            })
        }
    }
    
    func localStreamStarted() {
        print("Local stream added")
    }
}
