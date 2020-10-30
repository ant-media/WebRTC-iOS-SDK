//
//  WebRTCClient.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 6.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC
import ReplayKit

class WebRTCClient: NSObject {
    
    
    let VIDEO_TRACK_ID = "VIDEO"
    let AUDIO_TRACK_ID = "AUDIO"
    let LOCAL_MEDIA_STREAM_ID = "STREAM"
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    var delegate: WebRTCClientDelegate?
    var peerConnection : RTCPeerConnection?
    
    private var videoCapturer: RTCVideoCapturer?
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var remoteVideoView: RTCVideoRenderer?
    var localVideoView: RTCVideoRenderer?
    var videoSender: RTCRtpSender!
    var dataChannel: RTCDataChannel?
    
    private var token: String!
    private var streamId: String!

    private var audioEnabled: Bool = true
    private var videoEnabled: Bool = true
    private var captureScreenEnabled: Bool = false;
    private var config = Config.init()
    private var mode: AntMediaClientMode = AntMediaClientMode.join
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    private var targetWidth: Int = 480
    private var targetHeight: Int = 360
    
    public init(remoteVideoView: RTCVideoRenderer?, localVideoView: RTCVideoRenderer?, delegate: WebRTCClientDelegate) {
        super.init()
        
        self.remoteVideoView = remoteVideoView
        self.localVideoView = localVideoView
        self.delegate = delegate
        
        RTCPeerConnectionFactory.initialize()
        
        let stunServer = config.defaultStunServer()
        let defaultConstraint = config.createDefaultConstraint()
        let configuration = config.createConfiguration(server: stunServer)
        
        self.peerConnection = WebRTCClient.factory.peerConnection(with: configuration, constraints: defaultConstraint, delegate: self)
    }
    
    public convenience init(remoteVideoView: RTCVideoRenderer?, localVideoView: RTCVideoRenderer?, delegate: WebRTCClientDelegate, mode: AntMediaClientMode, cameraPosition: AVCaptureDevice.Position, targetWidth: Int, targetHeight: Int) {
        self.init(remoteVideoView: remoteVideoView, localVideoView: localVideoView, delegate: delegate,
                  mode: mode, cameraPosition: cameraPosition, targetWidth: targetWidth, targetHeight: targetHeight, videoEnabled: true, multiPeerActive:false, enableDataChannel:false)
    }
    public convenience init(remoteVideoView: RTCVideoRenderer?, localVideoView: RTCVideoRenderer?, delegate: WebRTCClientDelegate, mode: AntMediaClientMode, cameraPosition: AVCaptureDevice.Position, targetWidth: Int, targetHeight: Int, videoEnabled: Bool, multiPeerActive: Bool, enableDataChannel: Bool) {
        self.init(remoteVideoView: remoteVideoView, localVideoView: localVideoView, delegate: delegate,
                  mode: mode, cameraPosition: cameraPosition, targetWidth: targetWidth, targetHeight: targetHeight, videoEnabled: true, multiPeerActive:false, enableDataChannel:false, captureScreen: false)
    }
    
    public convenience init(remoteVideoView: RTCVideoRenderer?, localVideoView: RTCVideoRenderer?, delegate: WebRTCClientDelegate, mode: AntMediaClientMode, cameraPosition: AVCaptureDevice.Position, targetWidth: Int, targetHeight: Int, videoEnabled: Bool, multiPeerActive: Bool, enableDataChannel: Bool, captureScreen: Bool) {
        self.init(remoteVideoView: remoteVideoView, localVideoView: localVideoView, delegate: delegate)
        self.mode = mode
        self.cameraPosition = cameraPosition
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.videoEnabled = videoEnabled
        self.captureScreenEnabled = captureScreen;
        
        if (self.mode != .play && !multiPeerActive) {
            self.addLocalMediaStream()
        }
        
        if (enableDataChannel && self.mode == .publish) {
            //in publish mode, client opens the data channel
            self.dataChannel = createDataChannel()
            self.dataChannel?.delegate = self
        }
    }
    
    public func getStats(handler: @escaping (RTCStatisticsReport) -> Void) {
        
        
        self.peerConnection?.statistics(completionHandler: handler);
    }
    
    public func setStreamId(_ streamId: String) {
        self.streamId = streamId
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    
    public func setRemoteDescription(_ description: RTCSessionDescription) {
        self.peerConnection?.setRemoteDescription(description, completionHandler: {
            (error) in
            if (error != nil) {
                AntMediaClient.printf("Error (setRemoteDescription): " + error!.localizedDescription + " debug description: " + error.debugDescription)
                
            }
        })
    }
    
    public func addCandidate(_ candidate: RTCIceCandidate) {
        self.peerConnection?.add(candidate)
    }
    
    public func sendData(data: Data, binary: Bool = false) {
        if (self.dataChannel?.readyState == .open) {
            let dataBuffer = RTCDataBuffer.init(data: data, isBinary: binary);
            self.dataChannel?.sendData(dataBuffer);
        }
        else {
            AntMediaClient.printf("Data channel is nil or state is not open. State is \(String(describing: self.dataChannel?.readyState)) Please check that data channel is enabled in server side ")
        }
    }
    
    public func isDataChannelActive() -> Bool {
        return self.dataChannel?.readyState == .open;
    }

    
    public func sendAnswer() {
        let constraint = self.config.createAudioVideoConstraints()
        self.peerConnection?.answer(for: constraint, completionHandler: { (sdp, error) in
            if (error != nil) {
                AntMediaClient.printf("Error (sendAnswer): " + error!.localizedDescription)
            } else {
                AntMediaClient.printf("Got your answer")
                if (sdp?.type == RTCSdpType.answer) {
                    self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                        (error) in
                        if (error != nil) {
                            AntMediaClient.printf("Error (sendAnswer/closure): " + error!.localizedDescription)
                        }
                    })
                    
                    var answerDict = [String: Any]()
                    
                    if (self.token.isEmpty) {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!] as [String : Any]
                    } else {
                        answerDict =  ["type": "answer",
                                       "command": "takeConfiguration",
                                       "sdp": sdp!.sdp,
                                       "streamId": self.streamId!,
                                       "token": self.token] as [String : Any]
                    }
                    
                    self.delegate?.sendMessage(answerDict)
                }
            }
        })
    }
    
    public func createOffer() {
        let constraint = self.config.createAudioVideoConstraints()

        self.peerConnection?.offer(for: constraint, completionHandler: { (sdp, error) in
            if (sdp?.type == RTCSdpType.offer) {
                AntMediaClient.printf("Got your offer")
                
                self.peerConnection?.setLocalDescription(sdp!, completionHandler: {
                    (error) in
                    if (error != nil) {
                        AntMediaClient.printf("Error (createOffer): " + error!.localizedDescription)
                    }
                })
                
                AntMediaClient.printf("offer sdp: " + sdp!.sdp)
                var offerDict = [String: Any]()
                
                if (self.token.isEmpty) {
                    offerDict =  ["type": "offer",
                                  "command": "takeConfiguration",
                                  "sdp": sdp!.sdp,
                                  "streamId": self.streamId!] as [String : Any]
                } else {
                    offerDict =  ["type": "offer",
                                      "command": "takeConfiguration",
                                      "sdp": sdp!.sdp,
                                      "streamId": self.streamId!,
                                      "token": self.token] as [String : Any]
                }
                
                self.delegate?.sendMessage(offerDict)
            }
        })
    }
    
    public func stop() {
        disconnect();
        
    }
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        guard let dataChannel = self.peerConnection?.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            AntMediaClient.printf("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }

    public func disconnect() {
        //TODO: how to clear all resources
      //  self.localVideoTrack?.remove(self.localVideoView!)
        self.remoteVideoTrack?.remove(self.remoteVideoView!)
      //  self.localVideoView?.renderFrame(nil)
        self.remoteVideoView?.renderFrame(nil)
        self.localVideoTrack = nil
        self.remoteVideoTrack = nil
        (self.videoCapturer as? RTCCustomFrameCapturer)?.stopCapture()
        self.peerConnection?.close()
    }
    
    public func toggleAudioEnabled() {
        self.audioEnabled = !self.audioEnabled
        if (self.localAudioTrack != nil) {
            self.localAudioTrack.isEnabled = self.audioEnabled
        }
    }
    
    public func toggleVideoEnabled() {
        self.videoEnabled = !self.videoEnabled
        if(self.localVideoTrack != nil) {
            self.localVideoTrack.isEnabled = self.videoEnabled
        }
    }
    
    
    private func startCapture() -> Bool {
        
         let camera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == self.cameraPosition })
        
        if (camera != nil) {
            let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: camera!)
            var currentDiff = INT_MAX
            var selectedFormat: AVCaptureDevice.Format? = nil
            for supportedFormat in supportedFormats {
                let dimension = CMVideoFormatDescriptionGetDimensions(supportedFormat.formatDescription)
                let diff = abs(Int32(targetWidth) - dimension.width) + abs(Int32(targetHeight) - dimension.height);
                if (diff < currentDiff) {
                    selectedFormat = supportedFormat
                    currentDiff = diff
                }
            }
            
            if (selectedFormat != nil) {
                
                var maxSupportedFramerate: Float64 = 0;
                for fpsRange in selectedFormat!.videoSupportedFrameRateRanges {
                    maxSupportedFramerate = fmax(maxSupportedFramerate, fpsRange.maxFrameRate);
                }
                let fps = fmin(maxSupportedFramerate, 30.0);
                
                 let dimension = CMVideoFormatDescriptionGetDimensions(selectedFormat!.formatDescription)
                
                AntMediaClient.printf("Camera resolution: " + String(dimension.width) + "x" + String(dimension.height)
                    + " fps: " + String(fps))
                
                let cameraVideoCapturer = self.videoCapturer as? RTCCameraVideoCapturer;
                
                
                cameraVideoCapturer?.startCapture(with: camera!,
                                                  format: selectedFormat!,
                                                  fps: Int(fps))
                return true
            }
            else {
                AntMediaClient.printf("Cannot open camera not suitable format")
            }
        }
        else {
            AntMediaClient.printf("Not Camera Found")
        }
    
        return false;
        
    }
    
    private func createVideoTrack() -> RTCVideoTrack?  {
        let videoSource = WebRTCClient.factory.videoSource()
        
        if captureScreenEnabled
        {
            self.videoCapturer = RTCCustomFrameCapturer.init(delegate: videoSource, height: targetHeight)
            (self.videoCapturer as? RTCCustomFrameCapturer)?.startCapture()
        }
        else {
            #if TARGET_OS_SIMULATOR
            self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
            #else
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            let captureStarted = startCapture()
            if (!captureStarted) {
                return nil;
            }
            #endif
        }
        
        let videoTrack = WebRTCClient.factory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    private func addLocalMediaStream() -> Bool {
        
        
        AntMediaClient.printf("Add local media streams")
        if (self.videoEnabled) {
            self.localVideoTrack = createVideoTrack();

            self.videoSender = self.peerConnection?.add(self.localVideoTrack,  streamIds: [LOCAL_MEDIA_STREAM_ID])
        }
        let audioSource = WebRTCClient.factory.audioSource(with: self.config.createTestConstraints())
        self.localAudioTrack = WebRTCClient.factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
        
        self.peerConnection?.add(self.localAudioTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
        
        if (self.localVideoTrack != nil) {
            self.localVideoTrack.add(localVideoView!)
        }
        self.delegate?.addLocalStream()
        return true
    }
    
    public func switchCamera() {
        
        if self.videoSender != nil {
            peerConnection?.removeTrack(self.videoSender)
        }
        if self.cameraPosition == .front {
            self.cameraPosition = .back
        }
        else {
            self.cameraPosition = .front
        }
        
        self.localVideoTrack.remove(localVideoView!)
        self.localVideoTrack = createVideoTrack()
        
        self.localVideoTrack.add(localVideoView!)
        
        self.videoSender = self.peerConnection?.add(self.localVideoTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
        
    }
      
}

extension WebRTCClient: RTCDataChannelDelegate
{
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.dataReceivedFromDataChannel(didReceiveData: buffer)
    }
    
    func dataChannelDidChangeState(_ parametersdataChannel: RTCDataChannel)  {
        if (parametersdataChannel.readyState == .open) {
            AntMediaClient.printf("Data channel state is open")
        }
        else if  (parametersdataChannel.readyState == .connecting) {
            AntMediaClient.printf("Data channel state is connecting")
        }
        else if  (parametersdataChannel.readyState == .closing) {
            AntMediaClient.printf("Data channel state is closing")
        }
        else if  (parametersdataChannel.readyState == .closed) {
            AntMediaClient.printf("Data channel state is closed")
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        
    }
    
    
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    // signalingStateChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //AntMediaClient.printf("---> StateChanged:\(stateChanged.rawValue)")
    }
    
    // addedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        AntMediaClient.printf("AddedStream")
        
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            return
        }
        
        if (stream.videoTracks.count == 1) {
            AntMediaClient.printf("stream has video track");
            if (remoteVideoView != nil) {
                remoteVideoTrack = stream.videoTracks[0]
                
                //remoteVideoTrack.setEnabled(true)
                remoteVideoTrack.add(remoteVideoView!)
                AntMediaClient.printf("Has delegate??? (signalingStateChanged): \(String(describing: self.delegate))")
            }
            delegate?.addRemoteStream()
        }
        else {
            
        }
    }
    
    // removedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        AntMediaClient.printf("RemovedStream")
        remoteVideoTrack = nil
        remoteAudioTrack = nil
    }
    
    // GotICECandidate
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateJson = ["command": "takeCandidate",
                             "type" : "candidate",
                             "streamId": self.streamId,
                             "candidate" : candidate.sdp,
                             "label": candidate.sdpMLineIndex,
                             "id": candidate.sdpMid] as [String : Any]
        self.delegate?.sendMessage(candidateJson)
    }
    
    // iceConnectionChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        AntMediaClient.printf("---> iceConnectionChanged: \(newState.rawValue) for stream: \(self.streamId)")
        self.delegate?.connectionStateChanged(newState: newState)
    }
    
    // iceGatheringChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //AntMediaClient.printf("---> iceGatheringChanged")
    }
    
    // didOpen dataChannel
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        AntMediaClient.printf("---> dataChannel opened")
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
        
    }
    
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //AntMediaClient.printf("---> peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //AntMediaClient.printf("---> didRemove")
    }
}
