//
//  WebRTCClient.swift
//  AntMediaSDK
//
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
    
    private var audioDeviceModule: RTCAudioDeviceModule?
    
    private var factory: RTCPeerConnectionFactory
    
    weak var delegate: WebRTCClientDelegate?
    
    var peerConnection: RTCPeerConnection?
    
    private var videoCapturer: RTCVideoCapturer?
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var remoteVideoView: RTCVideoRenderer?
    var localVideoView: RTCVideoRenderer?
    var videoSender: RTCRtpSender?
    var dataChannel: RTCDataChannel?
    
    private var token: String!
    private var streamId: String!
    
    private var audioEnabled: Bool = true
    private var videoEnabled: Bool = true
    
    /**
     If useExternalCameraSource is false, it opens the local camera
     If it's true, it does not open the local camera. When it's set to true, it can record the screen in-app or you can give external frames through your application or BroadcastExtension. If you give external frames or through BroadcastExtension, you need to set the externalVideoCapture to true as well
     */
    private var useExternalCameraSource: Bool = false
    
    private var enableDataChannel: Bool = false
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    private var targetWidth: Int = 480
    private var targetHeight: Int = 360
    
    private var externalVideoCapture: Bool = false
    
    private var externalAudio: Bool = false
    
    private var cameraSourceFPS: Int = 30
    
    /*
     State of the connection
     */
    var iceConnectionState: RTCIceConnectionState = .new
    
    private var degradationPreference: RTCDegradationPreference = .maintainResolution
    
    // this is not an ideal method to get current capture device, we need more legit solution
    var captureDevice: AVCaptureDevice? {
        if videoEnabled {
          return (RTCCameraVideoCapturer.captureDevices().first { $0.position == self.cameraPosition })
        }
        else {
          return nil;
        }
    }
    
    public init(remoteVideoView: RTCVideoRenderer?, localVideoView: RTCVideoRenderer?, delegate: WebRTCClientDelegate, externalAudio: Bool) {
        RTCInitializeSSL()
        
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        self.externalAudio = externalAudio
        self.audioDeviceModule = RTCAudioDeviceModule()
        self.audioDeviceModule?.setExternalAudio(externalAudio)
        
        self.factory = RTCPeerConnectionFactory(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory,
            audioDeviceModule: audioDeviceModule!
        )
        
        super.init()
        
        self.remoteVideoView = remoteVideoView
        self.localVideoView = localVideoView
        self.delegate = delegate
        
        let stunServer = Config.defaultStunServer()
        let defaultConstraint = Config.createDefaultConstraint()
        let configuration = Config.createConfiguration(server: stunServer)
        
        self.peerConnection = factory.peerConnection(with: configuration, constraints: defaultConstraint, delegate: self)
    }
    
    public convenience init(
        remoteVideoView: RTCVideoRenderer?,
        localVideoView: RTCVideoRenderer?,
        delegate: WebRTCClientDelegate,
        cameraPosition: AVCaptureDevice.Position,
        targetWidth: Int,
        targetHeight: Int,
        streamId: String
    ) {
        self.init(remoteVideoView: remoteVideoView,
                  localVideoView: localVideoView,
                  delegate: delegate,
                  cameraPosition: cameraPosition,
                  targetWidth: targetWidth,
                  targetHeight: targetHeight,
                  videoEnabled: true,
                  enableDataChannel: false,
                  streamId: streamId
        )
    }
    
    public convenience init(
        remoteVideoView: RTCVideoRenderer?,
        localVideoView: RTCVideoRenderer?,
        delegate: WebRTCClientDelegate,
        cameraPosition: AVCaptureDevice.Position,
        targetWidth: Int,
        targetHeight: Int,
        videoEnabled: Bool,
        enableDataChannel: Bool,
        streamId: String
    ) {
        self.init(remoteVideoView: remoteVideoView,
                  localVideoView: localVideoView,
                  delegate: delegate,
                  cameraPosition: cameraPosition,
                  targetWidth: targetWidth,
                  targetHeight: targetHeight,
                  videoEnabled: true,
                  enableDataChannel: false,
                  useExternalCameraSource: false,
                  streamId: streamId
        )
    }
    
    public convenience init(
        remoteVideoView: RTCVideoRenderer?,
        localVideoView: RTCVideoRenderer?,
        delegate: WebRTCClientDelegate,
        cameraPosition: AVCaptureDevice.Position,
        targetWidth: Int,
        targetHeight: Int,
        videoEnabled: Bool,
        enableDataChannel: Bool,
        useExternalCameraSource: Bool,
        externalAudio: Bool = false,
        externalVideoCapture: Bool = false,
        cameraSourceFPS: Int = 30,
        streamId: String,
        degradationPreference: RTCDegradationPreference = .maintainResolution
    ) {
        
        self.init(remoteVideoView: remoteVideoView, localVideoView: localVideoView, delegate: delegate, externalAudio: externalAudio)
        self.cameraPosition = cameraPosition
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.videoEnabled = videoEnabled
        self.useExternalCameraSource = useExternalCameraSource
        self.enableDataChannel = enableDataChannel
        self.externalVideoCapture = externalVideoCapture
        self.cameraSourceFPS = cameraSourceFPS
        self.streamId = streamId
        self.degradationPreference = degradationPreference
    }
    
    public func externalVideoCapture(externalVideoCapture: Bool) {
        self.externalVideoCapture = externalVideoCapture
    }
    
    private func initFactory() -> RTCPeerConnectionFactory {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        if audioDeviceModule == nil {
            return RTCPeerConnectionFactory(
                encoderFactory: videoEncoderFactory,
                decoderFactory: videoDecoderFactory
            )
        } else {
            return RTCPeerConnectionFactory(
                encoderFactory: videoEncoderFactory,
                decoderFactory: videoDecoderFactory,
                audioDeviceModule: audioDeviceModule!
            )
        }
    }
    
    public func setMaxVideoBps(maxVideoBps: NSNumber) {
        AntMediaClient.printf("In setMaxVideoBps:\(maxVideoBps)")
        if maxVideoBps.intValue > 0 {
            AntMediaClient.printf("setMaxVideoBps:\(maxVideoBps)")
            self.peerConnection?.setBweMinBitrateBps(nil, currentBitrateBps: nil, maxBitrateBps: maxVideoBps)
        }
    }
    
    public func getStats(handler: @escaping (RTCStatisticsReport) -> Void) {
        self.peerConnection?.statistics(completionHandler: handler)
    }
    
    public func setStreamId(_ streamId: String) {
        self.streamId = streamId
    }
    
    public func setToken(_ token: String) {
        self.token = token
    }
    
    public func setRemoteDescription(_ description: RTCSessionDescription, completionHandler: @escaping RTCSetSessionDescriptionCompletionHandler) {
        self.peerConnection?.setRemoteDescription(description, completionHandler: completionHandler)
    }
    
    public func addCandidate(_ candidate: RTCIceCandidate) {
        self.peerConnection?.add(candidate)
    }
    
    public func sendData(data: Data, binary: Bool = false) {
        if self.dataChannel?.readyState == .open {
            let dataBuffer = RTCDataBuffer(data: data, isBinary: binary)
            self.dataChannel?.sendData(dataBuffer)
        } else {
            AntMediaClient.printf("Data channel is nil or state is not open. State is \(String(describing: self.dataChannel?.readyState)) Please check that data channel is enabled in server side ")
        }
    }
    
    public func isDataChannelActive() -> Bool {
        return self.dataChannel?.readyState == .open
    }
    
    public func sendAnswer() {
        let constraint = Config.createAudioVideoConstraints()
        self.peerConnection?.answer(for: constraint, completionHandler: { sdp, error in
            if error != nil {
                AntMediaClient.printf("Error (sendAnswer): " + error!.localizedDescription)
            } else {
                AntMediaClient.printf("Got your answer")
                if sdp?.type == RTCSdpType.answer {
                    self.peerConnection?.setLocalDescription(sdp!, completionHandler: { error in
                        if error != nil {
                            AntMediaClient.printf("Error (sendAnswer/closure): " + error!.localizedDescription)
                        }
                    })
                    
                    var answerDict = [String: Any]()
                    
                    if self.token.isEmpty {
                        answerDict = ["type": "answer",
                                      "command": "takeConfiguration",
                                      "sdp": sdp!.sdp,
                                      "streamId": self.streamId!] as [String: Any]
                    } else {
                        answerDict = ["type": "answer",
                                      "command": "takeConfiguration",
                                      "sdp": sdp!.sdp,
                                      "streamId": self.streamId!,
                                      "token": self.token] as [String: Any]
                    }
                    
                    self.delegate?.sendMessage(answerDict)
                }
            }
        })
    }
    
    public func createOffer() {
        
        // let the one who creates offer also create data channel.
        // by doing that it will work both in publish-play and peer-to-peer mode
        if enableDataChannel {
            self.dataChannel = createDataChannel()
            self.dataChannel?.delegate = self
        }
        
        let constraint = Config.createAudioVideoConstraints()
        
        self.peerConnection?.offer(for: constraint, completionHandler: { sdp, error in
            if sdp?.type == RTCSdpType.offer {
                AntMediaClient.printf("Got your offer")
                
                self.peerConnection?.setLocalDescription(sdp!, completionHandler: { error in
                    if error != nil {
                        AntMediaClient.printf("Error (createOffer): " + error!.localizedDescription)
                    }
                })
                
                AntMediaClient.printf("offer sdp: " + sdp!.sdp)
                var offerDict = [String: Any]()
                
                if self.token.isEmpty {
                    offerDict = ["type": "offer",
                                 "command": "takeConfiguration",
                                 "sdp": sdp!.sdp,
                                 "streamId": self.streamId!] as [String: Any]
                } else {
                    offerDict = ["type": "offer",
                                 "command": "takeConfiguration",
                                 "sdp": sdp!.sdp,
                                 "streamId": self.streamId!,
                                 "token": self.token] as [String: Any]
                }
                
                self.delegate?.sendMessage(offerDict)
            }
        })
    }
    
    public func stop() {
        disconnect()
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
        AntMediaClient.printf("disconnecting and releasing resources for \(streamId)")
        
        if let view = self.localVideoView {
            self.localVideoTrack?.remove(view)
        }
        
        if let view = self.remoteVideoView {
            self.remoteVideoTrack?.remove(view)
        }
        
        self.remoteVideoView?.renderFrame(nil)
        self.localVideoTrack = nil
        self.remoteVideoTrack = nil
        
        if self.videoCapturer is RTCCameraVideoCapturer {
            (self.videoCapturer as? RTCCameraVideoCapturer)?.stopCapture()
        } else if self.videoCapturer is RTCCustomFrameCapturer {
            (self.videoCapturer as? RTCCustomFrameCapturer)?.stopCapture()
        }
        
        self.videoCapturer = nil
        
        self.peerConnection?.close()
        self.peerConnection = nil
        AntMediaClient.printf("disconnected and released resources for \(streamId)")
    }
    
    public func toggleAudioEnabled() {
        self.setAudioEnabled(enabled: !self.audioEnabled)
    }
    
    public func setAudioEnabled(enabled: Bool) {
        self.audioEnabled = enabled
        if self.localAudioTrack != nil {
            self.localAudioTrack.isEnabled = self.audioEnabled
        }
    }
    
    public func isAudioEnabled() -> Bool {
        return self.audioEnabled
    }
    
    public func toggleVideoEnabled() {
        self.setVideoEnabled(enabled: !self.videoEnabled)
    }
    
    func isVideoEnabled() -> Bool {
        return self.videoEnabled
    }
    
    public func setVideoEnabled(enabled: Bool) {
        self.videoEnabled = enabled
        
        if self.localVideoTrack != nil {
            self.localVideoTrack.isEnabled = self.videoEnabled
        }
    }
    
    public func getIceConnectionState() -> RTCIceConnectionState {
        return iceConnectionState
    }
    
    private func startCapture() -> Bool {
      
        
        if captureDevice != nil {
            let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: captureDevice!)
            
            var currentDiff = INT_MAX
            
            var selectedFormat: AVCaptureDevice.Format?
            
            for supportedFormat in supportedFormats {
                let dimension = CMVideoFormatDescriptionGetDimensions(supportedFormat.formatDescription)
                let diff = abs(Int32(targetWidth) - dimension.width) + abs(Int32(targetHeight) - dimension.height)
                if diff < currentDiff {
                    selectedFormat = supportedFormat
                    currentDiff = diff
                }
            }
            
            if selectedFormat != nil {
                
                var maxSupportedFramerate: Float64 = 0
                for fpsRange in selectedFormat!.videoSupportedFrameRateRanges {
                    maxSupportedFramerate = fmax(maxSupportedFramerate, fpsRange.maxFrameRate)
                }
                let fps = fmin(maxSupportedFramerate, Double(self.cameraSourceFPS))
                
                let dimension = CMVideoFormatDescriptionGetDimensions(selectedFormat!.formatDescription)
                
                AntMediaClient.printf("Camera resolution: " + String(dimension.width) + "x" + String(dimension.height)
                                      + " fps: " + String(fps))
                
                let cameraVideoCapturer = self.videoCapturer as? RTCCameraVideoCapturer
                
                cameraVideoCapturer?.startCapture(with: captureDevice!,
                                                  format: selectedFormat!,
                                                  fps: Int(fps))
                
                return true
            } else {
                AntMediaClient.printf("Cannot open camera not suitable format")
            }
        } else {
            AntMediaClient.printf("Not Camera Found")
        }
        
        return false
    }
    
    private func createVideoTrack() -> RTCVideoTrack? {
        if useExternalCameraSource {
            // try with screencast video source
            let videoSource = factory.videoSource(forScreenCast: true)
            
            self.videoCapturer = RTCCustomFrameCapturer(
                delegate: videoSource,
                height: targetHeight,
                externalCapture: externalVideoCapture,
                videoEnabled: videoEnabled,
                audioEnabled: externalAudio,
                fps: self.cameraSourceFPS
            )
            
            (self.videoCapturer as? RTCCustomFrameCapturer)?.setWebRTCClient(webRTCClient: self)
            (self.videoCapturer as? RTCCustomFrameCapturer)?.startCapture()
            let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
            return videoTrack
        } else {
            let videoSource = factory.videoSource()
            #if TARGET_OS_SIMULATOR
            self.videoCapturer = RTCFileVideoCapturer(delegate: videoSource)
            #else
            self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            let captureStarted = startCapture()
            if !captureStarted {
                return nil
            }
            #endif
            let videoTrack = factory.videoTrack(with: videoSource, trackId: "video0")
            return videoTrack
        }
    }
    
    public func addLocalMediaStream() -> Bool {
        AntMediaClient.printf("Add local media streams")
        if self.videoEnabled {
            self.localVideoTrack = createVideoTrack()
            
            self.videoSender = self.peerConnection?.add(self.localVideoTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
            
            if let params = videoSender?.parameters {
                params.degradationPreference = (self.degradationPreference.rawValue) as NSNumber
                videoSender?.parameters = params
            } else {
                AntMediaClient.printf("DegradationPreference cannot be set")
            }
        }
        
        let audioSource = factory.audioSource(with: Config.createTestConstraints())
        self.localAudioTrack = factory.audioTrack(with: audioSource, trackId: AUDIO_TRACK_ID)
        
        self.peerConnection?.add(self.localAudioTrack, streamIds: [LOCAL_MEDIA_STREAM_ID])
        
        if self.localVideoTrack != nil && self.localVideoView != nil {
            self.localVideoTrack.add(localVideoView!)
        }
        
        self.delegate?.addLocalStream(streamId: self.streamId)
        return true
    }
    
    public func getLocalVideoTrack() -> RTCVideoTrack {
        return self.localVideoTrack
    }
    
    public func getLocalAudioTrack() -> RTCAudioTrack {
        return self.localAudioTrack
    }
    
    public func setDegradationPreference(degradationPreference: RTCDegradationPreference) {
        self.degradationPreference = degradationPreference
    }
    
    public func switchCamera() {
        let cameraVideoCapturer = self.videoCapturer as? RTCCameraVideoCapturer
        cameraVideoCapturer?.stopCapture()
        
        if self.cameraPosition == .front {
            self.cameraPosition = .back
        } else {
            self.cameraPosition = .front
        }
        
        startCapture()
    }
    
    public func deliverExternalAudio(sampleBuffer: CMSampleBuffer) {
        self.audioDeviceModule?.deliverRecordedData(sampleBuffer)
    }
    
    public func getVideoCapturer() -> RTCVideoCapturer? {
        return videoCapturer
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.dataReceivedFromDataChannel(didReceiveData: buffer, streamId: self.streamId)
    }
    
    func dataChannelDidChangeState(_ parametersdataChannel: RTCDataChannel) {
        if parametersdataChannel.readyState == .open {
            AntMediaClient.printf("Data channel state is open")
        } else if parametersdataChannel.readyState == .connecting {
            AntMediaClient.printf("Data channel state is connecting")
        } else if parametersdataChannel.readyState == .closing {
            AntMediaClient.printf("Data channel state is closing")
        } else if parametersdataChannel.readyState == .closed {
            AntMediaClient.printf("Data channel state is closed")
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    // signalingStateChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        // AntMediaClient.printf("---> StateChanged:\(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        AntMediaClient.printf("didAdd track:\(String(describing: rtpReceiver.track?.kind)) media streams count:\(mediaStreams.count) ")
        
        if let track = rtpReceiver.track {
            self.delegate?.trackAdded(track: track, stream: mediaStreams)
        } else {
            AntMediaClient.printf("New track added but it's nil")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
        AntMediaClient.printf("didRemove track:\(String(describing: rtpReceiver.track?.kind))")
        
        if let track = rtpReceiver.track {
            self.delegate?.trackRemoved(track: track)
        } else {
            AntMediaClient.printf("New track removed but it's nil")
        }
    }
    
    // addedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        AntMediaClient.printf("addedStream. Stream has \(stream.videoTracks.count) video tracks and \(stream.audioTracks.count) audio tracks")
        
        if stream.videoTracks.count == 1 {
            AntMediaClient.printf("stream has video track")
            if remoteVideoView != nil {
                remoteVideoTrack = stream.videoTracks[0]
                
                // remoteVideoTrack.setEnabled(true)
                remoteVideoTrack.add(remoteVideoView!)
                AntMediaClient.printf("Has delegate??? (signalingStateChanged): \(String(describing: self.delegate))")
            }
        }
        
        delegate?.remoteStreamAdded(streamId: self.streamId)
    }
    
    // removedStream
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        AntMediaClient.printf("RemovedStream")
        delegate?.remoteStreamRemoved(streamId: self.streamId)
        remoteVideoTrack = nil
        remoteAudioTrack = nil
    }
    
    // GotICECandidate
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidateJson = ["command": "takeCandidate",
                             "type": "candidate",
                             "streamId": self.streamId,
                             "candidate": candidate.sdp,
                             "label": candidate.sdpMLineIndex,
                             "id": candidate.sdpMid] as [String: Any]
        
        self.delegate?.sendMessage(candidateJson)
    }
    
    // iceConnectionChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        AntMediaClient.printf("---> iceConnectionChanged: \(newState.rawValue) for stream: \(String(describing: self.streamId))")
        self.iceConnectionState = newState
        self.delegate?.connectionStateChanged(newState: newState, streamId: self.streamId)
    }
    
    // iceGatheringChanged
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        // AntMediaClient.printf("---> iceGatheringChanged")
    }
    
    // didOpen dataChannel
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        AntMediaClient.printf("---> dataChannel opened")
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        // AntMediaClient.printf("---> peerConnectionShouldNegotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        // AntMediaClient.printf("---> didRemove")
    }
}
