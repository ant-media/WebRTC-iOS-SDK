//
//  VideoViewController.swift
//  AntMediaReferenceApplication
//
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
    
    var client: AntMediaClient?;
    var clientUrl: String!
    var clientStreamId: String!
    var clientToken: String!
    var clientMode: AntMediaClientMode!
    var tapGesture: UITapGestureRecognizer!
    
    var readerOutput: AVAssetReaderTrackOutput?;
    var reader: AVAssetReader?;
    
    var audioFileUrl: URL? = nil ;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //NOTE for the one who wants to sends mp3. Just comment out below lines and return the method including return below 
        //let audioFileURL = Bundle.main.url(forResource: "michael_jackson_audio_mono", withExtension: "mp3")!
        //self.initAntMediaClientForExternalAudio(fileUrl: audioFileURL);
        //self.modeLabel.text = "Mode: Audio Sending"
        //return;
        
        self.client = AntMediaClient.init()
        self.client!.delegate = self
        self.client!.setDebug(true)
        self.client!.setOptions(url: self.clientUrl, streamId: self.clientStreamId, token: self.clientToken, mode: self.clientMode, enableDataChannel: true, useExternalCameraSource:false)
        
        //this should be enabled when an audio app or broadcast extension is used.
        //Please check the sample in ScreenShare
        self.client!.setExternalAudio(externalAudioEnabled: false);
        
        
        //set default stunserver or turn server
        //let iceServer:RTCIceServer = RTCIceServer.init(urlStrings: ["stun:stun.l.google.com:19302"], username: "", credential: "")
        //Config.setDefaultStunServer(server: iceServer);
        
        //self.client.setMaxVideoBps(videoBitratePerSecond: 500000)

        /*
         Enable the below line if you use multi peer node for embedded sdk
         */
        //self.client.setMultiPeerMode(enable: true, mode: "play")

        
        if self.client!.getCurrentMode() == AntMediaClientMode.join {
            self.modeLabel.text = "Mode: P2P"
            self.pipVideoView.isHidden = false
            self.fullVideoView.isHidden = false
            self.client!.setLocalView(container: pipVideoView)
            self.client!.setRemoteView(remoteContainer: fullVideoView)
            self.client!.start();
        } else if self.client!.getCurrentMode() == AntMediaClientMode.publish {
           // self.client.setVideoEnable(enable: true);
            self.pipVideoView.isHidden = false
            self.fullVideoView.isHidden = false
            self.modeLabel.text = "Mode: Publish"
            self.client!.setCameraPosition(position: .front)
            self.client!.setTargetResolution(width: 640, height: 360)
            self.client!.setLocalView(container: fullVideoView, mode: .scaleAspectFit)
            
            //calling this method is not necessary. It just initializes the connection and opens the camera
            self.client!.initPeerConnection(streamId: self.clientStreamId);
            
            //Enable below method to have the mirror effect
            //self.mirrorView(view: fullVideoView);
                    
            self.client!.publish(streamId: self.clientStreamId);
           
        } else if self.client!.getCurrentMode() == AntMediaClientMode.play {
            
            self.fullVideoView.isHidden = false
            self.pipVideoView.isHidden = false
            self.client!.setRemoteView(remoteContainer: fullVideoView, mode: .scaleAspectFit)
            self.modeLabel.text = "Mode: Play"
            
            self.client!.play(streamId:self.clientStreamId);
        }
       
        
        
        
         
    }
    
    /*
     * Mirror the view. fullVideoView or pipViewVideo can provided as parameter
     */
    private func mirrorView(view:UIView) {
        view.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
        
    @IBAction func audioTapped(_ sender: UIButton!) {
        sender.isSelected = !sender.isSelected
        
        if (self.client?.getCurrentMode() == .play) {
            AntMediaClient.printf("It's in play mode and calling to mute/unmute the incoming stream with enableAudioTrack:\(!sender.isSelected) ");
            //mute/unmute the incoming stream audio
            self.client?.enableAudioTrack(trackId: self.clientStreamId, enabled: !sender.isSelected);
        }
        else {
            AntMediaClient.printf("It's in publis mode and calling to mute/unmute the local audio to send");

            //mute/unmute the microphone for the publisher
            self.client?.setAudioTrack(enableTrack: !sender.isSelected);
        }
        
        
        
        
    }
    
    @IBAction func videoTapped(_ video: UIButton!) {
        video.isSelected = !video.isSelected
        //self.client.toggleVideo()
        
        self.client?.switchCamera()
    }
    
    @IBAction func closeTapped(_ sender: UIButton!) {
        self.client?.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func messageButtonTapped(_ sender: Any) {
        //show alert window if data channel is enabled
        let active = self.client?.isDataChannelActive()
        if (active == true)
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
                    self.client?.sendData(data: data, binary: false)
                    
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
        self.client?.stop()
    }
   
}

extension VideoViewController: AntMediaClientDelegate {
        
    func clientHasError(_ message: String) {
        AlertHelper.getInstance().show("Error!", message: message, cancelButtonText: "OK", cancelAction:  { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        })
    }
    
    
    func disconnected(streamId: String) {
        print("Disconnected -> \(streamId)")
    }
    
    func remoteStreamRemoved(streamId: String) {
        print("Remote stream removed -> \(streamId)")
        if (self.client?.getCurrentMode() == .join) {
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
        
        if let audioFile = self.audioFileUrl {
            sendMp3File(url: audioFile);
        }
    }
    
    func publishFinished(streamId: String) {
        
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) {
        AntMediaClient.speakerOn()
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
    
    func eventHappened(streamId: String, eventType: String) {
        
    }
    
    func initAntMediaClientForExternalAudio(fileUrl: URL) {
      
        client = AntMediaClient.init();
        client?.delegate = self
        client?.setDebug(true)
        client?.setUseExternalCameraSource(useExternalCameraSource: false)
        client?.setWebSocketServerUrl(url: self.clientUrl);
        
        client?.setVideoEnable(enable: false);
        client?.setExternalVideoCapture(externalVideoCapture: false);
    
        client?.setExternalAudio(externalAudioEnabled: true)
        
        client?.publish(streamId: self.clientStreamId);
        self.audioFileUrl = fileUrl;
        
    }
    
    func sendMp3File(url: URL) {
        
        let asset = AVAsset(url: url)
        let track = asset.tracks(withMediaType: .audio).first!
        
        do {
            reader = try AVAssetReader(asset: asset)
            
            /*
             mSampleRate: 44100.0, mFormatID: 1819304813,
             mFormatFlags: 14, mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2,
             mBitsPerChannel: 16, mReserved: 0
             */
            
            readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: true
            ])
            
            if let localReader = readerOutput {
                reader?.add(localReader)
                reader?.startReading()
                
                if let buffer = localReader.copyNextSampleBuffer() {
                    sendCMSampleBuffer(sampleBuffer: buffer);
                }
            }
        } catch {
            print("Error occurred: \(error)")
        }
        
    }
    
    func sendCMSampleBuffer(sampleBuffer:CMSampleBuffer)
    {
        
        client?.deliverExternalAudio(sampleBuffer: sampleBuffer)
        
        if let buffer = readerOutput?.copyNextSampleBuffer()
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + CMTimeGetSeconds(CMSampleBufferGetDuration(sampleBuffer)))
            {
                self.sendCMSampleBuffer(sampleBuffer: buffer);
            }
        }
    }
    
}
