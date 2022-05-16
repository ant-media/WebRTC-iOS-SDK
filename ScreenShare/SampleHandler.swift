//
//  SampleHandler.swift
//  ScreenShare
//
//  Created by mekya on 6.05.2022.
//  Copyright © 2022 AntMedia. All rights reserved.
//

import ReplayKit
import WebRTC
import WebRTCiOSSDK

class SampleHandler: RPBroadcastSampleHandler, AntMediaClientDelegate {
    func clientDidConnect(_ client: AntMediaClient) {
        
    }
    
    func clientDidDisconnect(_ message: String) {
        
    }
    
    func clientHasError(_ message: String) {
        let userInfo = [NSLocalizedFailureReasonErrorKey: message]
       
        finishBroadcastWithError(NSError(domain: "ScreenShare", code: -99, userInfo: userInfo));
        
    }
    
    func remoteStreamStarted(streamId: String) {
        
    }
    
    func remoteStreamRemoved(streamId: String) {
        
    }
    
    func localStreamStarted(streamId: String) {
        
    }
    
    func playStarted(streamId: String) {
       
    }
    
    func playFinished(streamId: String) {
        
    }
    
    func publishStarted(streamId: String) {
        NSLog("Publish has started");
    }
    
    func publishFinished(streamId: String) {
        NSLog("Publish has finished");
    }
    
    func disconnected(streamId: String) {
        
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) {
        
    }
    
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    func streamInformation(streamInfo: [StreamInformation]) {
        
    }
    

    let client: AntMediaClient = AntMediaClient.init()
    
    var videoEnabled: Bool = true;
    var audioEnabled: Bool = true;
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        
        let sharedDefault = UserDefaults(suiteName: "group.com.antmedia.ios.sdk")!

        let streamId = sharedDefault.object(forKey: "streamId");
        let url = sharedDefault.object(forKey: "url");
        let token = sharedDefault.object(forKey: "token");
        
        let videoEnabledObject = sharedDefault.object(forKey:"videoEnabled") as! String;
        if videoEnabledObject == "false"
        {
            videoEnabled = false;
        }
        
        let audioEnabledObject = sharedDefault.object(forKey:"audioEnabled") as! String;
        if audioEnabledObject == "false" {
            audioEnabled = false;
        }
        
        if ((streamId) == nil)
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "StreamId is not specified. Please specify stream id in the container app"]
           
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: userInfo));
        }
        else if ((url) == nil)
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "URL is not specified. Please specify URL in the container app"]
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -2, userInfo: userInfo));
        }
        else {
            NSLog("----> streamId: %@ , websocket url: %@, videoEnabled: %d , audioEnabled: %d", streamId as! String, url as! String,
                  videoEnabled, audioEnabled);
            
            self.client.delegate = self
            self.client.setDebug(true)
            self.client.setOptions(url: url as! String, streamId: streamId as! String, token: token as? String ?? "", mode: AntMediaClientMode.publish, enableDataChannel: true, captureScreenEnabled: true);
            
            if (videoEnabled != nil) {
                self.client.setVideoEnable(enable: videoEnabled as! Bool);
                self.client.setExternalVideoCapture(externalVideoCapture: true);
            }
            
            self.client.setExternalAudio(externalAudioEnabled: true)
            
            self.client.initPeerConnection();
            
            self.client.start();
            
        }
        

    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        self.client.stop();
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            //NSLog("processSamplebuffer video");
            if videoEnabled {
                self.client.deliverExternalVideo(sampleBuffer: sampleBuffer);
            }
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            //NSLog("processSamplebuffer audio");
            if audioEnabled {
                self.client.deliverExternalAudio(sampleBuffer: sampleBuffer);
            }
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio.
            // You can choose
           // NSLog("processSamplebuffer audio mic");
           // if audioEnabled {
           //     self.client.deliverExternalAudio(sampleBuffer: sampleBuffer);
           // }
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
