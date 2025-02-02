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
    
    let kNanosecondsPerSecond: Float64 = 1_000_000_000
    var nanoseconds: Float64 = 0
    var lastSentFrameTimeStampNanoSeconds: Int64 = 0
    private var targetHeight: Int
        
    private var videoEnabled: Bool = true
    private var audioEnabled: Bool = true
    
    private var webRTCClient: WebRTCClient?
    
    private var frameRateIntervalNanoSeconds: Float64 = 0
    
    // if externalCapture is true, it means that capture method is called from an external component.
    // externalComponent is the BroadcastExtension
    private var externalCapture: Bool
    
    private var fps: Int
    
    init(delegate: RTCVideoCapturerDelegate, height: Int, externalCapture: Bool = false, videoEnabled: Bool = true, audioEnabled: Bool = false, fps: Int = 30) {
        self.targetHeight = height
        self.externalCapture = externalCapture
        
        // if external capture is enabled videoEnabled and audioEnabled are ignored
        self.videoEnabled = videoEnabled
        self.audioEnabled = audioEnabled
        self.frameRateIntervalNanoSeconds = kNanosecondsPerSecond / Double(fps)
        self.fps = fps
            
        super.init(delegate: delegate)
    }
    
    public func setWebRTCClient(webRTCClient: WebRTCClient) {
        self.webRTCClient = webRTCClient
    }
    
    public func capture(_ pixelBuffer: CVPixelBuffer, rotation: RTCVideoRotation, timeStampNs: Int64 ) {
        if (Double(timeStampNs) - Double(lastSentFrameTimeStampNanoSeconds)) < frameRateIntervalNanoSeconds {
            AntMediaClient.verbose("Dropping frame because high fps than the configured fps: \(fps). Incoming timestampNs:\(timeStampNs) last sent timestampNs:\(lastSentFrameTimeStampNanoSeconds) frameRateIntervalNs:\(frameRateIntervalNanoSeconds)")
            return
        }
        
        let width = Int32(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int32(CVPixelBufferGetHeight(pixelBuffer))
        
        var scaledWidth = (width * Int32(self.targetHeight)) / height
        
        if scaledWidth % 2 == 1 {
            scaledWidth += 1
        }
        
        let rtcPixelBuffer = RTCCVPixelBuffer(
            pixelBuffer: pixelBuffer,
            adaptedWidth: scaledWidth,
            adaptedHeight: Int32(self.targetHeight),
            cropWidth: width,
            cropHeight: height,
            cropX: 0,
            cropY: 0
        )
        
        let rtcVideoFrame = RTCVideoFrame(
                    buffer: rtcPixelBuffer,
                    rotation: rotation,
                    timeStampNs: Int64(timeStampNs)
                )
        
        self.delegate?.capturer(self, didCapture: rtcVideoFrame.newI420())
        lastSentFrameTimeStampNanoSeconds = Int64(timeStampNs)
    }
    
    public func capture(_ sampleBuffer: CMSampleBuffer, externalRotation: Int = -1) {
        
        if CMSampleBufferGetNumSamples(sampleBuffer) != 1 || !CMSampleBufferIsValid(sampleBuffer) || !CMSampleBufferDataIsReady(sampleBuffer) {
            NSLog("Buffer is not ready and dropping")
            return
        }
        
        let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * kNanosecondsPerSecond
                
        if (Double(timeStampNs) - Double(lastSentFrameTimeStampNanoSeconds)) < frameRateIntervalNanoSeconds {
            AntMediaClient.verbose("Dropping frame because high fps than the configured fps: \(fps). Incoming timestampNs:\(timeStampNs) last sent timestampNs:\(lastSentFrameTimeStampNanoSeconds) frameRateIntervalNs:\(frameRateIntervalNanoSeconds)")
            return
        }
        
        let _pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        if let pixelBuffer = _pixelBuffer {
            // NSLog("Incoming frame width:\(width) height:\(height) adapted width:\(scaledWidth) height:\(self.targetHeight)")
            
            var rotation = RTCVideoRotation._0
            
            if externalRotation == -1 {
                if #available(iOS 11.0, *) {
                    if let orientationAttachment = CMGetAttachment(sampleBuffer, key: RPVideoSampleOrientationKey as CFString, attachmentModeOut: nil) as? NSNumber {
                        let orientation = CGImagePropertyOrientation(rawValue: orientationAttachment.uint32Value)
                        switch orientation {
                        case .up:
                            rotation = RTCVideoRotation._0
                        case .down:
                            rotation = RTCVideoRotation._180
                        case .left:
                            rotation = RTCVideoRotation._90
                        case .right:
                            rotation = RTCVideoRotation._270
                        default:
                            NSLog("orientation NOT FOUND")
                        }
                    } else {
                        NSLog("CANNOT get image rotation")
                    }
                } else {
                    NSLog("CANNOT get image rotation becaue iOS version is older than 11")
                }
            } else {
                rotation = RTCVideoRotation(rawValue: externalRotation) ?? RTCVideoRotation._0
            }

            capture(pixelBuffer, rotation: rotation, timeStampNs: Int64(timeStampNs))
            // NSLog("Device orientation width: %d, height:%d ", width, height);
        } else {
            NSLog("Cannot get image buffer")
        }
    }
    
    public func startCapture() {
        if !externalCapture {
            let recorder = RPScreenRecorder.shared()
           
            if #available(iOS 11.0, *) {
                recorder.startCapture { buffer, bufferType, _ in
                    if bufferType == RPSampleBufferType.video && self.videoEnabled {
                        self.capture(buffer)
                    } else if bufferType == RPSampleBufferType.audioApp && self.audioEnabled {
                        self.webRTCClient?.deliverExternalAudio(sampleBuffer: buffer)
                        
                    }
                } completionHandler: { error in
                    guard error == nil else {
                        AntMediaClient.printf("Screen capturer is not started")
                        return
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    public func stopCapture() {
        if !externalCapture {
            let recorder = RPScreenRecorder.shared()
            if recorder.isRecording {
                 if #available(iOS 11.0, *) {
                     recorder.stopCapture { error in
                         guard error == nil else {
                             AntMediaClient.printf("Cannot stop capture \(String(describing: error))")
                             return
                         }
                     }
                 } else {
                     
                 }
             }
        }
    }
}
