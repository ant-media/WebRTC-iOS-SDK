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
import WebRTCiOSSDK

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
        self.client.setOptions(url: self.clientUrl, streamId: self.clientStreamId, token: self.clientToken, mode: self.clientMode, enableDataChannel: true)

        /*
         Enable the below line if you use multi peer node for embedded sdk
         */
        //self.client.setMultiPeerMode(enable: true, mode: "play")
        /*
         Enable below line if you don't want to have mic permission dialog while playing
         Please pay attention that if you enable below method, it will not use microphone.
         Which means if you are publishing and playing at the same time, you should not enable
         the below method
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
        }
        //calling this method is not necessary. It just initializes the connection and opens the camera
        self.client.initPeerConnection()
        
        self.client.start()
    }
    
    /*
     *  WebRTC Framework ask for mic permission by default even it's only playing
     *  stream. If you run this method before starting the webrtc client in play mode,
     *  It will not ask for mic permission
     *
     *  ATTENTION: Calling this method in sending stream cause not sending the audio. So if you publish
     *  and play stream at the same time, don't use this method
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
    
    @IBAction func messageButtonTapped(_ sender: Any) {
        //show alert window if data channel is enabled
        if self.client.isDataChannelActive()
        {
            
            let alert = UIAlertController(title: "Send Message", message: "Send message with WebRTC Datachannel", preferredStyle: .alert)

            alert.addTextField { (textField) in
                textField.text =  ""
            }

            alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak alert] (_) in
                guard let textValue  =  alert?.textFields?.first?.text else {
                           return
                }
                     
                if let data = textValue.data(using: .utf8) {
                    /*
                     Send data through data channel
                    */
                    self.client.sendData(data: data, binary: false)
                    
                    /*
                     You can either use some simple JSON formatting in order to have better
                     let candidateJson = ["command": "message",
                                          "content" : textValue,
                                          ] as [String : Any]
                     self.client.sendData(data: candidateJson.json.data(using: .utf8) ?? Data.init(capacity: 1), binary: false)
                     */
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (_) in
                alert?.dismiss(animated: false, completion: nil)
            }))

            self.present(alert, animated: true, completion: nil)
        }
        else {
             AlertHelper.getInstance().show("Warning", message: "Data channel is not active. Please make sure data channel is enabled in both server side and mobile sdk ")
        }
        
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
    
    
    func disconnected(streamId: String) {
        print("Disconnected -> \(streamId)")
    }
    
    func remoteStreamStarted(streamId: String) {
        print("Remote stream started -> \(streamId)")
    }
    
    func remoteStreamRemoved(streamId: String) {
        print("Remote stream removed -> \(streamId)")
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
    
    func localStreamStarted(streamId: String) {
        print("Local stream added")
        self.fullVideoView.isHidden = false
    }
    
    
    func playStarted(streamId: String)
    {
        print("play started");
    }
    
    func playFinished(streamId: String) {
        print("play finished")
        
        AlertHelper.getInstance().show("Caution!", message: "Remote stream is no longer available", cancelButtonText: "OK", cancelAction: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    func publishStarted(streamId: String)
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
    
    func publishFinished(streamId: String) {
        
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) {
        self.client.speakerOn()
    }
    
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        AntMediaClient.printf("Data is received from stream: \(streamId) is binary:\(binary) content: " + String(decoding: data, as: UTF8.self))
        
        Run.onMainThread {
            self.showToast(controller: self, message:  String(decoding: data, as: UTF8.self), seconds: 1.0)
        }
        
    }
    
    func streamInformation(streamInfo: [StreamInformation]) {
        AntMediaClient.printf("Incoming stream infos")
        for result in streamInfo {
            AntMediaClient.printf("resolution width:\(result.streamWidth) heigh:\(result.streamHeight) video " + "bitrate:\(result.videoBitrate) audio bitrate:\(result.audioBitrate) codec:\(result.videoCodec)");
        }
    }
    
    func showToast(controller: UIViewController, message : String, seconds: Double)
    {
        let alert = UIAlertController(title: "Received Message", message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15

        controller.present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}
