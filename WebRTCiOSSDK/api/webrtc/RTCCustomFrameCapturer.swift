//
//  RTCCustomFrameCapturer.swift
//  WebRTCiOSSDK
//
//  Created by mekya on 27.09.2020.
//  Copyright © 2020 AntMedia. All rights reserved.
//

import Foundation
import WebRTC
import ReplayKit

class RTCCustomFrameCapturer: RTCVideoCapturer {
    
    let kNanosecondsPerSecond: Float64 = 1000000000
    var nanoseconds: Float64 = 0
    private var targetHeight: Int
        
    private var videoEnabled: Bool = true;
    private var audioEnabled: Bool = true;
    
    private var webRTCClient: WebRTCClient?;
    
    
    // if externalCapture is true, it means that capture method is called from an external component.
    // externalComponent is the BroadcastExtension
    private var externalCapture: Bool;
    
    
    init(delegate: RTCVideoCapturerDelegate, height: Int, externalCapture: Bool = false, videoEnabled: Bool = true, audioEnabled: Bool = false)
    {
        self.targetHeight = height
        self.externalCapture = externalCapture;
        
        //if external capture is enabled videoEnabled and audioEnabled are ignored
        self.videoEnabled = videoEnabled;
        self.audioEnabled = audioEnabled;
            
        super.init(delegate: delegate)
        
    }
    
    public func setWebRTCClient(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
    }
    
    public func capture(_ sampleBuffer: CMSampleBuffer) {
        
        if (CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) ||
            !CMSampleBufferDataIsReady(sampleBuffer)) {
          return;
        }
        
        let _pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if let pixelBuffer = _pixelBuffer
        {
            
            let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
            let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
            
            var scaledWidth = (width * Int32(self.targetHeight)) / height;
            if (scaledWidth % 2 == 1) {
                scaledWidth+=1;
            }
            
            //NSLog("Incoming frame width:\(width) height:\(height) adapted width:\(scaledWidth) height:\(self.targetHeight)")
            
            let rtcPixelBuffer = RTCCVPixelBuffer(
                pixelBuffer: pixelBuffer,
                adaptedWidth:scaledWidth,
                adaptedHeight: Int32(self.targetHeight),
                cropWidth: width,
                cropHeight: height,
                cropX: 0,
                cropY: 0)
            
                        
            let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
                kNanosecondsPerSecond;
            
            var rotation = RTCVideoRotation._0;
            if #available(iOS 11.0, *) {
                if let orientationAttachment =  CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber
                {
                    let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value)
                    switch orientation {
                               case .up:
                                rotation = RTCVideoRotation._0;
                                break;
                               case .down:
                                rotation = RTCVideoRotation._180;
                                break;
                                case .left:
                                rotation = RTCVideoRotation._90;
                                break;
                               case .right:
                                rotation = RTCVideoRotation._270;
                                break;
                             
                                default:
                                NSLog("orientation NOT FOUND");
                    }
                }
                else {
                    NSLog("CANNOT get image rotation")
                    
                }
            } else {
                NSLog("CANNOT get image rotation becaue iOS version is older than 11")
            }

            //NSLog("Device orientation width: %d, height:%d ", width, height);
            
            let rtcVideoFrame = RTCVideoFrame(buffer: rtcPixelBuffer,
                                              
                                              rotation: rotation, timeStampNs: Int64(timeStampNs))
            
            
            self.delegate?.capturer(self, didCapture: rtcVideoFrame.newI420())
           
        }
        
    }
    
    public func startCapture()
    {
        if !externalCapture
        {
            let recorder = RPScreenRecorder.shared();
           
            if #available(iOS 11.0, *) {
                recorder.startCapture { (buffer, bufferType, error) in
                    if bufferType == RPSampleBufferType.video && self.videoEnabled
                    {
                        self.capture(buffer)
                    }
                    else if bufferType == RPSampleBufferType.audioApp && self.audioEnabled {
                        self.webRTCClient?.deliverExternalAudio(sampleBuffer: buffer);
                        
                    }
                } completionHandler: { (error) in
                    guard error == nil else {
                        AntMediaClient.printf("Screen capturer is not started")
                        return;
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    public func stopCapture()
    {
        if !externalCapture {
            let recorder = RPScreenRecorder.shared();
            if (recorder.isRecording) {
                 if #available(iOS 11.0, *) {
                     recorder.stopCapture { (error) in
                         guard error == nil else {
                             AntMediaClient.printf("Cannot stop capture \(String(describing: error))");
                             return;
                         }
                     }
                 } else {
                     
                 }
             }
        }
    }
    
   
}

