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
import AVFoundation

class VideoViewController: UIViewController {
    
    @IBOutlet weak var pipVideoView: UIView!
    @IBOutlet weak var fullVideoView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerStatusLabel: UILabel!
    @IBOutlet weak var footerInfoLabel: UILabel!
    
    // Auto Layout Constraints used for animations
    @IBOutlet weak var containerLeftConstraint: NSLayoutConstraint?
    @IBOutlet weak var footerViewBoomConstraint: NSLayoutConstraint?
    
    let client: AntMediaClient = AntMediaClient.init()
    var clientUrl: String!
    var clientStreamId: String!
    var clientToken: String!
    var clientMode: AntMediaClientMode!
    var tapGesture: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGesture()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.client.delegate = self
        self.client.setDebug(true)
        self.client.setOptions(url: self.clientUrl, streamId: self.clientStreamId, token: self.clientToken, mode: self.clientMode)
        
        if self.client.getCurrentMode() == AntMediaClientMode.join {
            self.modeLabel.text = "Mode: P2P"
            self.client.setLocalView(container: pipVideoView)
            self.client.setRemoteView(remoteContainer: fullVideoView)
        } else if self.client.getCurrentMode() == AntMediaClientMode.publish {
            self.pipVideoView.isHidden = false
            self.fullVideoView.isHidden = false
            self.modeLabel.text = "Mode: Publish"
            self.client.setCameraPosition(position: .front)
            self.client.setTargetResolution(width: 480, height: 360)
            self.client.setLocalView(container: fullVideoView)
           
        } else if self.client.getCurrentMode() == AntMediaClientMode.play {
            self.fullVideoView.isHidden = false
            self.pipVideoView.isHidden = false
            self.client.setRemoteView(remoteContainer: fullVideoView)
            self.modeLabel.text = "Mode: Play"
        }
        
        self.client.connectWebSocket()
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
        self.client.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setGesture() {
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoViewController.toggleContainer))
        self.tapGesture.numberOfTapsRequired = 1
        self.fullVideoView.addGestureRecognizer(tapGesture)
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
    
    
    func disconnected() {
        
    }
    
    func remoteStreamStarted() {
        print("Remote stream started")
    }
    
    func remoteStreamRemoved() {
        print("Remote stream removed")
        if (self.client.getCurrentMode() == .join) {
            Run.afterDelay(1, block: {
                UIView.animate(withDuration: 0.4, animations: {
                    self.footerViewBoomConstraint?.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: { _ in
                    self.fullVideoView.isHidden = true
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
        self.fullVideoView.isHidden = false
    }
    
    
    func playStarted()
    {
        print("play started");
        
         Run.onMainThread {

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
    
    func playFinished() {
        AlertHelper.getInstance().show("Caution!", message: "Remote stream is no longer available", cancelButtonText: "OK", cancelAction: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    func publishStarted()
    {
        Run.onMainThread
        {
            Run.afterDelay(3, block: {
                Run.onMainThread {
                    
                    self.pipVideoView.bringSubview(toFront: self.fullVideoView)
                    
                    
                    UIView.animate(withDuration: 0.4, animations: {
                        self.footerViewBoomConstraint?.constant = 80
                        self.view.layoutIfNeeded()
                    }, completion: nil)
                }
            })
        }
    }
    
    func publishFinished() {
        
    }
}
