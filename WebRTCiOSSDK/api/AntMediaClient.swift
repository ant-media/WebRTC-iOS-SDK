//
//  WebRTCClient.swift
//  AntMediaSDK
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import AVFoundation
import Starscream
import WebRTC

let TAG: String = "AntMedia_iOS: "

public enum AntMediaClientMode: Int {
    case join = 1
    case play = 2
    case publish = 3
    
    func getLeaveMessage() -> String {
        switch self {
            case .join:
                return "leave"
            case .publish, .play:
                return "stop"
        }
    }
    
    func getName() -> String {
        switch self {
            case .join:
                return "join"
            case .play:
                return "play"
            case .publish:
                return "publish"
        }
    }
    
}

open class AntMediaClient: NSObject, AntMediaClientProtocol {
    
    internal static var isDebug: Bool = false
    public var delegate: AntMediaClientDelegate!

    private var wsUrl: String!
    private var streamId: String!
    private var token: String!
    private var webSocket: WebSocket?
    private var mode: AntMediaClientMode!
    private var webRTCClient: WebRTCClient?
    private var localView: RTCVideoRenderer?
    private var remoteView: RTCVideoRenderer?
    
    private var videoContentMode: UIView.ContentMode?
    
    private let audioQueue = DispatchQueue(label: "audio")
    
    private let rtcAudioSession =  RTCAudioSession.sharedInstance()
    
    private var localContainerBounds: CGRect?
    private var remoteContainerBounds: CGRect?
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    private var targetWidth: Int = 480
    private var targetHeight: Int = 360
    
    private let COMMAND: String = "command"
    private let STREAM_ID: String = "streamId"
    private let TOKEN_ID: String = "token"
    private let VIDEO: String = "video"
    private let AUDIO: String = "audio"
    
    private var videoEnable: Bool = true
    private var audioEnable: Bool = true
    
    private var multiPeer: Bool = false
        
    private var enableDataChannel: Bool = false
    
    private var multiPeerStreamId: String?
    
    /*
     This peer mode is used in multi peer streaming
     */
    private var multiPeerMode: String = "play"
    
    var pingTimer: Timer?
    
    struct HandshakeMessage:Codable {
        var command:String?
        var streamId:String?
        var token:String?
        var video:Bool?
        var audio:Bool?
        var mode:String?
        var multiPeer:Bool?
    }
    
    public override init() {
        self.multiPeerStreamId = nil
     
     }
    
    public func setOptions(url: String, streamId: String, token: String = "", mode: AntMediaClientMode = .join, enableDataChannel: Bool = false) {
        self.wsUrl = url
        self.streamId = streamId
        self.token = token
        self.mode = mode
        self.rtcAudioSession.add(self)
        self.enableDataChannel = enableDataChannel
    }
    
    public func setMultiPeerMode(enable: Bool, mode: String) {
        self.multiPeer = enable
        self.multiPeerMode = mode;
    }
    
    public func setVideoEnable( enable: Bool) {
        self.videoEnable = enable
    }
    
    func getHandshakeMessage() -> String {
        
        let handShakeMesage = HandshakeMessage(command: self.mode.getName(), streamId: self.streamId, token: self.token.isEmpty ? "" : self.token, video: self.videoEnable, audio:self.audioEnable, multiPeer: self.multiPeer && self.multiPeerStreamId != nil ? true : false)
        let json = try! JSONEncoder().encode(handShakeMesage)
        return String(data: json, encoding: .utf8)!
    }
    public func getLeaveMessage() -> [String: String] {
        return [COMMAND: self.mode.getLeaveMessage(), STREAM_ID: self.streamId]
    }
    
    // Force speaker
    public func speakerOn() {
       
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try self.rtcAudioSession.setActive(true)
            } catch let error {
                AntMediaClient.printf("Couldn't force audio to speaker: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    public func configureAudioSession() {
       
        self.audioQueue.sync { [weak self] in
            guard let self = self else {
                 debugPrint("returning ConfigureAudioSession")
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            
            do {
                 let configuration = RTCAudioSessionConfiguration.init()
               
                configuration.category = AVAudioSession.Category.ambient.rawValue;
                configuration.categoryOptions = AVAudioSession.CategoryOptions.duckOthers;
                configuration.mode = AVAudioSession.Mode.default.rawValue;
                
                if (self.rtcAudioSession.isActive) {
                    try self.rtcAudioSession.setConfiguration(configuration)
                }
                else {
                    try self.rtcAudioSession.setConfiguration(configuration, active:true)
                }
            }
            catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            
            self.rtcAudioSession.unlockForConfiguration()
        }
        
       
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    public func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
        }
    }

    
    open func start() {
        connectWebSocket()
    }
    
    /*
     Connect to websocket
     */
    open func connectWebSocket() {
        AntMediaClient.printf("Connect websocket \(String(describing: self.webSocket?.isConnected))")
        if (!(self.webSocket?.isConnected ?? false)) { //provides backward compatibility
            AntMediaClient.printf("Will connect to: \(self.getWsUrl())")
        
            webSocket = WebSocket(request: self.getRequest())
            webSocket?.delegate = self
            webSocket?.connect()
        }
        else {
            AntMediaClient.printf("WebSocket is already connected to: \(self.getWsUrl())")
        }
    }
    
    open func setCameraPosition(position: AVCaptureDevice.Position) {
        self.cameraPosition = position
    }
    
    open func setTargetResolution(width: Int, height: Int) {
        self.targetWidth = width
        self.targetHeight = height
    }
    
    /*
     Stops everything,
     Disconnects from websocket and
     stop webrtc
     */
    open func stop() {
        AntMediaClient.printf("Stop is called")
        if (self.webSocket?.isConnected ?? false) {
            let jsonString = self.getLeaveMessage().json
            webSocket?.write(string: jsonString)
            self.webSocket?.disconnect()
        }
        self.webRTCClient?.disconnect()
        self.webRTCClient = nil
    }
    
    open func initPeerConnection() {
        
        if (self.webRTCClient == nil) {
            configureAudioSession()
            AntMediaClient.printf("Has wsClient? (start) : \(String(describing: self.webRTCClient))")
            self.webRTCClient = WebRTCClient.init(remoteVideoView: remoteView, localVideoView: localView, delegate: self, mode: self.mode, cameraPosition: self.cameraPosition, targetWidth: self.targetWidth, targetHeight: self.targetHeight, videoEnabled: self.videoEnable, multiPeerActive:  self.multiPeer, enableDataChannel: self.enableDataChannel)
            
            self.webRTCClient!.setStreamId(streamId)
            self.webRTCClient!.setToken(self.token)
        }
        else {
            AntMediaClient.printf("WebRTCClient already initialized")
        }
    }
    
    /*
     Just switches the camera. It works on the fly as well
     */
    open func switchCamera() {
        self.webRTCClient?.switchCamera()
    }

    /*
     Send data through WebRTC Data channel.
     */
    open func sendData(data: Data, binary: Bool = false) {
        self.webRTCClient?.sendData(data: data, binary: binary)
    }
    
    open func isDataChannelActive() -> Bool {
        return self.webRTCClient?.isDataChannelActive() ?? false
    }
        
    open func setLocalView( container: UIView, mode:UIView.ContentMode = .scaleAspectFit) {
       
        #if arch(arm64)
        let localRenderer = RTCMTLVideoView(frame: container.frame)
        localRenderer.videoContentMode =  mode
        #else
        let localRenderer = RTCEAGLVideoView(frame: container.frame)
        localRenderer.delegate = self
        #endif
 
        localRenderer.frame = container.bounds
        self.localView = localRenderer
        self.localContainerBounds = container.bounds
        
        self.embedView(localRenderer, into: container)
    }
    
    open func setRemoteView(remoteContainer: UIView, mode:UIView.ContentMode = .scaleAspectFit) {
       
        #if arch(arm64)
        let remoteRenderer = RTCMTLVideoView(frame: remoteContainer.frame)
        remoteRenderer.videoContentMode = mode
        #else
        let remoteRenderer = RTCEAGLVideoView(frame: remoteContainer.frame)
        remoteRenderer.delegate = self
        #endif
        
        remoteRenderer.frame = remoteContainer.frame
        
        self.remoteView = remoteRenderer
        self.remoteContainerBounds = remoteContainer.bounds
        self.embedView(remoteRenderer, into: remoteContainer)
        
    }
    
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    open func isConnected() -> Bool {
        return self.webSocket?.isConnected ?? false
    }
    
    open func setDebug(_ value: Bool) {
        AntMediaClient.isDebug = value
    }
    
    open func toggleAudio() {
        self.webRTCClient?.toggleAudioEnabled()
    }
    
    open func toggleVideo() {
        self.webRTCClient?.toggleVideoEnabled()
    }
    
    open func getCurrentMode() -> AntMediaClientMode {
        return self.mode
    }
    
    open func getWsUrl() -> String {
        return wsUrl;
    }
    
    private func onConnection() {
        if (self.webSocket!.isConnected) {
            let jsonString = getHandshakeMessage()
            AntMediaClient.printf("onConnection message: \(jsonString)")
            webSocket!.write(string: jsonString)
        }
    }
    
    private func onJoined() {

    }
    
    
    private func onTakeConfiguration(message: [String: Any]) {
        var rtcSessionDesc: RTCSessionDescription
        let type = message["type"] as! String
        let sdp = message["sdp"] as! String
        
        if type == "offer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.offer, sdp: sdp)
            self.webRTCClient?.setRemoteDescription(rtcSessionDesc)
            self.webRTCClient?.sendAnswer()
        } else if type == "answer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.answer, sdp: sdp)
            self.webRTCClient?.setRemoteDescription(rtcSessionDesc)
        }
    }
    
    private func onTakeCandidate(message: [String: Any]) {
        let mid = message["id"] as! String
        let index = message["label"] as! Int
        let sdp = message["candidate"] as! String
        let candidate: RTCIceCandidate = RTCIceCandidate.init(sdp: sdp, sdpMLineIndex: Int32(index), sdpMid: mid)
        self.webRTCClient?.addCandidate(candidate)
    }
    
    private func onMessage(_ msg: String) {
        if let message = msg.toJSON() {
            guard let command = message["command"] as? String else {
                return
            }
            self.onCommand(command, message: message)
        } else {
            print("WebSocket message JSON parsing error: " + msg)
        }
    }
    
    private func onCommand(_ command: String, message: [String: Any]) {
        AntMediaClient.printf("Command: " + command)
        switch command {
            case "start":
                //if this is called, it's publisher or initiator in p2p
                self.initPeerConnection()
                self.webRTCClient?.createOffer()
                break
            case "stop":
                self.webRTCClient?.stop()
                self.webRTCClient = nil
                self.delegate.remoteStreamRemoved()
                break
            case "takeConfiguration":
                self.initPeerConnection()
                self.onTakeConfiguration(message: message)
                break
            case "takeCandidate":
                self.onTakeCandidate(message: message)
                break
            case "connectWithNewId":
                self.multiPeerStreamId = message["streamId"] as? String
                let jsonString = getHandshakeMessage()
                webSocket!.write(string: jsonString)
                break
            case "notification":
                guard let definition = message["definition"] as? String else {
                    return
                }
                
                if definition == "joined" {
                    AntMediaClient.printf("Joined: Let's go")
                    self.onJoined()
                }
                else if definition == "play_started" {
                    AntMediaClient.printf("Play started: Let's go")
                    self.delegate.playStarted()
                }
                else if definition == "play_finished" {
                    AntMediaClient.printf("Playing has finished")
                    self.delegate.playFinished()
                }
                else if definition == "publish_started" {
                    AntMediaClient.printf("Publish started: Let's go")
                    self.delegate.publishStarted()
                }
                else if definition == "publish_finished" {
                    AntMediaClient.printf("Play finished: Let's close")
                    self.delegate.publishFinished()
                }
                break
            case "error":
                guard let definition = message["definition"] as? String else {
                    self.delegate.clientHasError("An error occured, please try again")
                    return
                }
                
                self.delegate.clientHasError(AntMediaError.localized(definition))
                break
            default:
                break
        }
    }
    
    private func getRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: self.getWsUrl())!)
        request.timeoutInterval = 5
        return request
    }
    
    public static func printf(_ msg: String) {
        if (AntMediaClient.isDebug) {
            debugPrint("--> AntMediaSDK: " + msg)
        }
    }
}

extension AntMediaClient: WebRTCClientDelegate {

    public func sendMessage(_ message: [String : Any]) {
        self.webSocket?.write(string: message.json)
    }
    
    public func addLocalStream() {
        self.delegate.localStreamStarted()
    }
    
    public func addRemoteStream() {
        self.delegate.remoteStreamStarted()
    }
    
    public func connectionStateChanged(newState: RTCIceConnectionState) {
        if newState == RTCIceConnectionState.closed ||
            newState == RTCIceConnectionState.disconnected ||
            newState == RTCIceConnectionState.failed
        {
            AntMediaClient.printf("connectionStateChanged: \(newState.rawValue)")
            self.delegate.disconnected();
        }
    }
    
    public func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer) {
        self.delegate.dataReceivedFromDataChannel(streamId: streamId, data: data.data, binary: data.isBinary);
    }
    
}

extension AntMediaClient: WebSocketDelegate {
    
    
    public func getPingMessage() -> [String: String] {
           return [COMMAND: "ping"]
       }
       
    
    public func websocketDidConnect(socket: WebSocketClient) {
        AntMediaClient.printf("WebSocketDelegate->Connected: \(socket.isConnected)")
        //no need to init peer connection but it opens camera and other stuff so that some users want at first
        self.initPeerConnection()
        self.onConnection()
        self.delegate?.clientDidConnect(self)
        
        //too keep the connetion alive send ping command for every 10 seconds
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { pingTimer in
            let jsonString = self.getPingMessage().json
            self.webSocket?.write(string: jsonString)
        }
    }
    

    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
       
        pingTimer?.invalidate()
        AntMediaClient.printf("WebSocketDelegate->Disconnected connected: \(socket.isConnected) \(self.webSocket?.isConnected)")
        
        if let e = error as? WSError {
            self.delegate?.clientDidDisconnect(e.message)
        } else if let e = error {
            self.delegate?.clientDidDisconnect(e.localizedDescription)
        } else {
            self.delegate?.clientDidDisconnect("Disconnected")
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        AntMediaClient.printf("Receive Message: \(text)")
        self.onMessage(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        //AntMediaClient.printf("Receive Data: " + String(data: data, encoding: .utf8)!)
    }
}

extension AntMediaClient: RTCAudioSessionDelegate
{
    
    public func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        self.delegate.audioSessionDidStartPlayOrRecord()
    }

}

/*
 This delegate used non arm64 versions. In other words it's used for RTCEAGLVideoView
 */
extension AntMediaClient: RTCVideoViewDelegate {
    
    private func resizeVideoFrame(bounds: CGRect, size: CGSize, videoView: UIView) {
    
        let defaultAspectRatio: CGSize = CGSize(width: size.width, height: size.height)
    
        let videoFrame: CGRect = AVMakeRect(aspectRatio: defaultAspectRatio, insideRect: bounds)
    
        videoView.bounds = videoFrame
    
    }
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        
        AntMediaClient.printf("Video size changed to " + String(Int(size.width)) + "x" + String(Int(size.height)))
        
        var bounds: CGRect?
        if videoView.isEqual(localView)
        {
            bounds = self.localContainerBounds ?? nil
        }
        else if videoView.isEqual(remoteView)
        {
            bounds = self.remoteContainerBounds ?? nil
        }
       
        if (bounds != nil)
        {
            resizeVideoFrame(bounds: bounds!, size: size, videoView: (videoView as? UIView)!)
        }
    }
}
