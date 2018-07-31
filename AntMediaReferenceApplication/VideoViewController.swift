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
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerStatusLabel: UILabel!
    @IBOutlet weak var footerInfoLabel: UILabel!
    
    // Auto Layout Constraints used for animations
    @IBOutlet weak var remoteViewTopConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewRightConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var remoteViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet weak var containerLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var footerViewBoomConstraint: NSLayoutConstraint?
    
    let client: AntMediaClient = AntMediaClient.init()
    var clientUrl: String!
    var clientStreamId: String!
    var clientMode: AntMediaClientMode!
    var tapGesture: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.client.delegate = self
        self.client.setOptions(url: self.clientUrl, streamId: self.clientStreamId, mode: self.clientMode)
        
        if self.client.getCurrentMode() == AntMediaClientMode.join {
            self.modeLabel.text = "Mode: P2P"
            self.client.setVideoViews(local: localVideoView, remote: remoteVideoView)
        } else if self.client.getCurrentMode() == AntMediaClientMode.publish {
            self.localVideoView.isHidden = true
            self.modeLabel.text = "Mode: Publish"
            self.client.setVideoViews(local: remoteVideoView, remote: localVideoView)
        } else if self.client.getCurrentMode() == AntMediaClientMode.play {
            self.remoteVideoView.isHidden = false
            self.localVideoView.isHidden = true
            self.client.setVideoViews(local: localVideoView, remote: remoteVideoView)
            self.modeLabel.text = "Mode: Play"
        }
        
        self.client.connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Run.onMainThread {
            print(self.client.getWsUrl())
            self.footerStatusLabel.text = "Connecting to: \(self.client.getWsUrl())"
        }
    }
    
    @IBAction func audioTapped(_ sender: UIButton!) {
        sender.isSelected = !sender.isSelected
        self.client.toggleAudio()
    }
    
    @IBAction func videoTapped(_ video: UIButton!) {
        video.isSelected = !video.isSelected
        self.client.toggleVideo()
    }
    
    @IBAction func closeTapped(_ sender: UIButton!) {
        self.client.disconnect()
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
        print("VideoViewController: Connected")
        self.client.start()
    }
    
    func clientDidDisconnect(_ message: String) {
        print("VideoViewController: Disconnected: \(message)")
    }
    
    func clientHasError(_ message: String) {
        AlertHelper.getInstance().show("Error!", message: message, cancelButtonText: "OK", cancelAction: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func remoteStreamStarted() {
        Run.onMainThread {
            if self.client.getCurrentMode() != .publish {
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
                    self.remoteVideoView.isHidden = false
                })
            }
            
            Run.afterDelay(3, block: {
                Run.onMainThread {
                    UIView.animate(withDuration: 0.4, animations: {
                        self.footerViewBoomConstraint?.constant = 80
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            })
        }
    }
    
    func remoteStreamRemoved() {
        print("Remote stream removed")
        if (self.client.getCurrentMode() == .join) {
            Run.afterDelay(1, block: {
                UIView.animate(withDuration: 0.4, animations: {
                    self.footerViewBoomConstraint?.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.remoteVideoView.isHidden = true
                })
            })
        } else {
            AlertHelper.getInstance().show("Caution!", message: "Remote stream is no longer available", cancelButtonText: "OK", cancelAction: {
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    func localStreamStarted() {
        print("Local stream added")
        self.remoteVideoView.isHidden = false
    }
}
