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
    
    init(delegate: RTCVideoCapturerDelegate, height: Int) {
        self.targetHeight = height
        super.init(delegate: delegate)
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
            
            var adaptedWidth = (width * Int32(self.targetHeight)) / height;
            if (adaptedWidth % 2 == 1) {
                adaptedWidth+=1;
            }
            
            let rtcPixelBuffer = RTCCVPixelBuffer(
                pixelBuffer: pixelBuffer,
                adaptedWidth:adaptedWidth,
                adaptedHeight: Int32(self.targetHeight),
                cropWidth: width,
                cropHeight: height,
                cropX: 0,
                cropY: 0)
            
                        
            let timeStampNs = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) *
                kNanosecondsPerSecond;
            
            let rtcVideoFrame = RTCVideoFrame(buffer: rtcPixelBuffer, rotation: RTCVideoRotation._0, timeStampNs: Int64(timeStampNs))
            
            self.delegate?.capturer(self, didCapture: rtcVideoFrame)
           
        }
        
    }
    
    public func startCapture() {
        let recorder = RPScreenRecorder.shared();
       
        if #available(iOS 11.0, *) {
            recorder.startCapture { (buffer, bufferType, error) in
                if bufferType == RPSampleBufferType.video
                {
                    self.capture(buffer)
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
    
    public func stopCapture()
    {
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

