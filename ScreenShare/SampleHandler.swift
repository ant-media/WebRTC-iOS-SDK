//
//  SampleHandler.swift
//  ScreenShare
//
//  Created by mekya on 6.05.2022.
//  Copyright © 2022 AntMedia. All rights reserved.
//

import ReplayKit
import WebRTCiOSSDK
import WebRTC
import CoreVideo
import CoreImage
import CoreMedia


class SampleHandler: RPBroadcastSampleHandler, AntMediaClientDelegate {
    let sharedDefault = UserDefaults(suiteName: "group.io.antmedia.sbd.webrtc.sample")! // for test
    
    func clientHasError(_ message: String) {
        let userInfo = [NSLocalizedFailureReasonErrorKey: message]
       
        finishBroadcastWithError(NSError(domain: "ScreenShare", code: -99, userInfo: userInfo));
        
    }
    
    func publishStarted(streamId: String) {
        NSLog("Publish has started");
        self.client.setFrameCapturer { [weak self] buffer, frame in
            guard let self, let requiredFrame = self.sharedDefault.object(forKey: "screenShareFrame") as? [CGFloat] else {
                return frame
            }
            
            // topSafeArea iPhone 12 mini
            let topSafeArea: CGFloat = 44
            let convertedFrame = convertRectToBufferFrame(
                rect: .init(x: requiredFrame[0], y: requiredFrame[1] + topSafeArea, width: requiredFrame[2], height: requiredFrame[3]),
                screenSize: UIScreen.main.bounds.size,
                bufferSize: frame.size
            )
            return convertedFrame
        }
    }
    
    func convertRectToBufferFrame(rect: CGRect, screenSize: CGSize, bufferSize: CGSize) -> CGRect {
        let scaleX = bufferSize.width / screenSize.width
        let scaleY = bufferSize.height / screenSize.height
        
        let projectedX = rect.origin.x * scaleX
        let projectedY = rect.origin.y * scaleY
        let projectedWidth = rect.size.width * scaleX
        let projectedHeight = rect.size.height * scaleY
        
        return CGRect(x: projectedX, y: projectedY, width: projectedWidth, height: projectedHeight)
    }
    
    func publishFinished(streamId: String) {
        NSLog("Publish has finished");
    }
    
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    let client: AntMediaClient = AntMediaClient.init()
    
    var videoEnabled: Bool = true;
    var audioEnabled: Bool = true;
    var streamId:String = "";
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        
//        original: group.io.antmedia.ios.webrtc.sample

        streamId = sharedDefault.object(forKey: "streamId") as! String;
        let url = sharedDefault.object(forKey: "url");
//        let token = sharedDefault.object(forKey: "token") ;
        
        let videoEnabledObject = sharedDefault.object(forKey:"videoEnabled") as! String;
        if videoEnabledObject == "false" {
            videoEnabled = false;
        }
        
        let audioEnabledObject = sharedDefault.object(forKey:"audioEnabled") as! String;
        if audioEnabledObject == "false" {
            audioEnabled = false;
        }
        
        if ((streamId).isEmpty) {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: "StreamId is not specified. Please specify stream id in the container app"
            ]
           
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -1, userInfo: userInfo));
        }
        else if ((url) == nil)
        {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "URL is not specified. Please specify URL in the container app"]
            finishBroadcastWithError(NSError(domain: "ScreenShare", code: -2, userInfo: userInfo));
        }
        else {
            NSLog("----> streamId: %@ , websocket url: %@, videoEnabled: %d , audioEnabled: %d", streamId, url as! String,
                  videoEnabled, audioEnabled);
        
            self.client.delegate = self
            self.client.setDebug(true)
            self.client.setUseExternalCameraSource(useExternalCameraSource: true)
            self.client.setWebSocketServerUrl(url: url as! String)

            if (videoEnabled != false) {
                self.client.setVideoEnable(enable: videoEnabled);
                self.client.setExternalVideoCapture(externalVideoCapture: true);
            }
            
            //in some ipad versions, resolution/aspect ratio is critical to set, otherwise iOS encoder may not encode the frames and
            //server side reports publishTimeout because server cannot get the video frames
            self.client.setTargetResolution(width: 1280, height: 720);
            self.client.setMaxVideoBps(videoBitratePerSecond: 2000000)
                    
            self.client.setExternalAudio(externalAudioEnabled: true)
            
            //In some devices iphone version, frames are dropped due to encoder queue and it causes glitches in the playback
            //Decreasing the fps provides a better playback expeience.
            //Alternatively, target resolution can be decreased above to let encoder work faster
            self.client.setTargetFps(fps: 10)
                        
            self.client.publish(streamId: streamId);
            
        }
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        self.client.stop(streamId: self.streamId);
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            //NSLog("processSamplebuffer video");
            if videoEnabled {
                self.client.deliverExternalVideo(sampleBuffer: sampleBuffer)
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
