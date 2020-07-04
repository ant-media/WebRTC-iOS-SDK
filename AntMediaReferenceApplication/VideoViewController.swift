//
//  VideoViewController.swift
//  AntMediaReferenceApplication
//
//  Created by Oğulcan on 14.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import UIKit
import WebRTC
import AVFoundation

class VideoViewController: UIViewController {
    
    @IBOutlet weak var pipVideoView: UIView!
    @IBOutlet weak var fullVideoView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var modeLabel: UILabel!
    
    // Auto Layout Constraints used for animations
    @IBOutlet weak var containerLeftConstraint: NSLayoutConstraint?
    
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

        /*
         Enable the below line if you use multi peer node for embedded sdk
         */
        //self.client.setMultiPeerMode(enable: true, mode: "play")
        /*
         Enable below line if you don't want to have mic permission dialog while playing
         */
        //dontAskMicPermissionForPlaying();
        
        if self.client.getCurrentMode() == AntMediaClientMode.join {
            self.modeLabel.text = "Mode: P2P"
            self.pipVideoView.isHidden = false
            self.fullVideoView.isHidden = false
            self.client.setLocalView(container: pipVideoView)
            self.client.setRemoteView(remoteContainer: fullVideoView)
        } else if self.client.getCurrentMode() == AntMediaClientMode.publish {
           // self.client.setVideoEnable(enable: true);
            self.pipVideoView.isHidden = false
            self.fullVideoView.isHidden = false
            self.modeLabel.text = "Mode: Publish"
            self.client.setCameraPosition(position: .front)
            self.client.setTargetResolution(width: 480, height: 360)
            self.client.setLocalView(container: fullVideoView, mode: .scaleAspectFit)
           
        } else if self.client.getCurrentMode() == AntMediaClientMode.play {
            self.fullVideoView.isHidden = false
            self.pipVideoView.isHidden = false
            self.client.setRemoteView(remoteContainer: fullVideoView, mode: .scaleAspectFit)
            self.modeLabel.text = "Mode: Play"
            self.client.setDefaultSpeakerMode(speakerOn: false)
        }
        //calling this method is not necessary. It just initializes the connection and opens the camera
        self.client.initPeerConnection()
        
        self.client.start()
    }
    
    /*
     *  WebRTC Framework ask for mic permission by default even it's only playing
     *  stream. If you run this method before starting the webrtc client in play mode,
     *  It will not ask for mic permission
     */
    private func dontAskMicPermissionForPlaying() {
        let webRTCConfiguration = RTCAudioSessionConfiguration.init()
        webRTCConfiguration.mode = AVAudioSession.Mode.moviePlayback.rawValue
        webRTCConfiguration.category = AVAudioSession.Category.playback.rawValue
        webRTCConfiguration.categoryOptions = AVAudioSession.CategoryOptions.duckOthers
                             
        RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
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
    
    
    override func viewWillDisappear(_ animated: Bool) {
        self.client.stop()
    }
    
   
}

extension VideoViewController: AntMediaClientDelegate {
    
    func clientDidConnect(_ client: AntMediaClient) {
        print("VideoViewController: Connected")
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
        print("Disconnected")
    }
    
    func remoteStreamStarted() {
        print("Remote stream started")
    }
    
    func remoteStreamRemoved() {
        print("Remote stream removed")
        if (self.client.getCurrentMode() == .join) {
            Run.afterDelay(1, block: {
                self.fullVideoView.isHidden = true
            })
        } else {
            AlertHelper.getInstance().show("Caution!", message: "Remote stream is no longer available", cancelButtonText: "OK", cancelAction: {
                //self.dismiss(animated: true, completion: nil)
                //self.fullVideoView.
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
    }
    
    func playFinished() {
        print("play finished")
        
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
                    self.pipVideoView.bringSubviewToFront(self.fullVideoView)
                }
            })
        }
    }
    
    func publishFinished() {
        
    }
    
    func audioSessionDidStartPlayOrRecord() {
       // self.client.speakerOn()
    }
}
