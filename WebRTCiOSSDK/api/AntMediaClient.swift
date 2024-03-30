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
    //deprecated
    case conference = 4;
    case unspecified = 5;
    
    
    func getLeaveMessage() -> String {
        switch self {
            case .join:
                return "leave"
            case .publish, .play:
                return "stop"
            case .conference:
                return "leaveRoom"
            case .unspecified:
                return "unspecified";
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
            case .conference:
                return "conference"
            case .unspecified:
                return "unspecified";
        }
    }
    
}
open class AntMediaClient: NSObject, AntMediaClientProtocol {
    
 
    internal static var isDebug: Bool = false
    public weak var delegate: AntMediaClientDelegate?

    private var wsUrl: String!
    private var publisherStreamId: String? = nil;
    /**
     mainTrackId can also be used  the roomId of the conference
     */
    private var mainTrackId: String?
    private var playerStreamId: String?
    private var p2pStreamId: String?
    private var publishToken: String?
    private var playToken: String?
    private var webSocket: WebSocket?
    //keep it for backward compatibility
    private var mode: AntMediaClientMode!
    var streamsInTheRoom:[String] = [];
    
    var roomInfoGetterTimer: Timer?;


    //private var webRTCClient: WebRTCClient?;
    private var webRTCClientMap: [String: WebRTCClient] = [:]

    private var localView: RTCVideoRenderer?
    private var remoteView: RTCVideoRenderer?
    
    private var videoContentMode: UIView.ContentMode?
    
    private static let dispatchQueue = DispatchQueue(label: "audio")
    
    static let rtcAudioSession =  RTCAudioSession.sharedInstance()
    
    private var localContainerBounds: CGRect?
    private var remoteContainerBounds: CGRect?
    
    private var cameraPosition: AVCaptureDevice.Position = .front
    
    private var targetWidth: Int = 1280
    private var targetHeight: Int = 720
    
    private var maxVideoBps: NSNumber = 0;
    
    private var videoEnable: Bool = true
    private var audioEnable: Bool = true
            
    private var enableDataChannel: Bool = true
        
    //Screen capture of the app's screen.
    private var useExternalCameraSource: Bool = false
    
    private var isWebSocketConnected: Bool = false;
    
    private var externalAudioEnabled: Bool = false;
    
    // External video capture is getting frames from Broadcast Extension.
    //In order to make the broadcast extension to work both captureScreenEnable and
    // externalVideoCapture should be true
    private var externalVideoCapture: Bool = false;
    
    private var cameraSourceFPS: Int = 30;
    
    var pingTimer: Timer?
    
    var disableTrackId:String?
    
    
    var reconnectIfRequiresScheduled: Bool = false;
        
    struct HandshakeMessage:Codable {
        var command:String?
        var streamId:String?
        var token:String?
        var video:Bool?
        var audio:Bool?
        var mode:String?
        var mainTrack:String?
        var trackList:[String]
    }
    
    public override init() {
    }
    
    public func setOptions(url: String, streamId: String, token: String = "", mode: AntMediaClientMode = .join, enableDataChannel: Bool = false, useExternalCameraSource: Bool = false) {
        self.wsUrl = url
        
        self.mode = mode
        if self.mode == AntMediaClientMode.publish {
            self.publisherStreamId = streamId;
            self.publishToken = token;
        }
        else if (self.mode == AntMediaClientMode.play) {
            self.playerStreamId = streamId;
            self.playToken = token;
        }
        else if self.mode == AntMediaClientMode.join {
            self.p2pStreamId = streamId;
        }
        self.enableDataChannel = enableDataChannel
        self.useExternalCameraSource = useExternalCameraSource
    }
    
    public func setWebSocketServerUrl(url: String) {
        self.wsUrl = url;
    }
    
    public func setRoomId(roomId: String) {
        self.mainTrackId = roomId
    }
    
    public func setEnableDataChannel(enableDataChannel: Bool) {
        self.enableDataChannel = enableDataChannel;
    }
    
    public func setUseExternalCameraSource(useExternalCameraSource: Bool) {
        self.useExternalCameraSource = useExternalCameraSource;
    }
    
    public func setMaxVideoBps(videoBitratePerSecond: NSNumber) {
        self.maxVideoBps = videoBitratePerSecond;
        self.webRTCClientMap[self.getPublisherStreamId()]?.setMaxVideoBps(maxVideoBps: videoBitratePerSecond)
    }
    
    public func setVideoEnable( enable: Bool) {
        self.videoEnable = enable
    }
    
    public func getStreamId(_ streamId:String = "") -> String {
        //backward compatibility
        if streamId.isEmpty {
            return self.publisherStreamId ?? (self.playerStreamId ?? (self.p2pStreamId ?? ""));
        }
        else {
            return streamId;
        }
    }
    
    public func getPublisherStreamId() -> String {
        return self.publisherStreamId ?? (self.p2pStreamId ?? "");
    }
    
    func getHandshakeMessage(streamId: String, mode: AntMediaClientMode, token:String = "") -> String {
        
        var trackList:[String] = [];
        AntMediaClient.printf("disable track id is \(String(describing: self.disableTrackId))");
        if let trackId = self.disableTrackId {
            AntMediaClient.printf("appending track id to the tracklist \(String(describing: self.disableTrackId))");
            trackList.append("!" + trackId);
        }
        else {
            AntMediaClient.printf("Disable track id is not set \(String(describing: self.disableTrackId))");
        }
        
        let handShakeMesage = HandshakeMessage(command: mode.getName(), streamId: streamId, token: token, video: self.videoEnable, audio:self.audioEnable, mainTrack: self.mainTrackId, trackList: trackList)
        
        let json = try! JSONEncoder().encode(handShakeMesage)
        return String(data: json, encoding: .utf8)!
    }
    public func getLeaveMessage(streamId: String, mode:AntMediaClientMode) -> [String: String] {
        return [COMMAND: mode.getLeaveMessage(), STREAM_ID: streamId]
    }
    
    // Force speaker
    public static func speakerOn() {
       
        dispatchQueue.async {() in
          
            rtcAudioSession.lockForConfiguration()
            do {
                try rtcAudioSession.overrideOutputAudioPort(.speaker)
                try rtcAudioSession.setActive(true)
            } catch let error {
                AntMediaClient.printf("Couldn't force audio to speaker: \(error)")
            }
            rtcAudioSession.unlockForConfiguration()
        }
    }
    
    // Fallback to the default playing device: headphones/bluetooth/ear speaker
    public static func speakerOff() {
        dispatchQueue.async {() in
            
            rtcAudioSession.lockForConfiguration()
            do {
                try rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                debugPrint("Error setting AVAudioSession category: \(error)")
            }
            rtcAudioSession.unlockForConfiguration()
        }
    }

    
    open func start() {
        initPeerConnection(streamId: self.getStreamId(), mode: self.mode, token: self.publishToken ?? (self.playToken ?? ""))
        if (!isWebSocketConnected) {
            connectWebSocket()
        }
        else {
            self.websocketConnected();
        }
    }
    
    /**
    Join P2P call
     */
    public func join(streamId:String)
    {
        self.p2pStreamId = streamId;
        resetDefaultWebRTCAudioConfiguation();
        initPeerConnection(streamId: streamId, mode: AntMediaClientMode.join)
        if (!isWebSocketConnected) {
            connectWebSocket();
        }
        else {
            sendJoinCommand(streamId)
        }
    }
    
    /**
     Leave from p2p call
     */
    public func leave(streamId:String) {
        if (!isWebSocketConnected) {
            let leaveMessage =  [
                COMMAND: "leave",
                STREAM_ID: streamId] as [String : Any]
        
            webSocket?.write(string:leaveMessage.json)
        }
        self.webRTCClientMap.removeValue(forKey: streamId)?.disconnect();
    }
    
    public func joinRoom(roomId:String, streamId: String = "") {
        self.mainTrackId = roomId;
        self.publisherStreamId = streamId;
        self.mode = AntMediaClientMode.conference;
        if (!isWebSocketConnected) {
            connectWebSocket()
        }
        else {
            sendJoinConferenceCommand()
        }
        //start periodic check
        roomInfoGetterTimer?.invalidate()
        roomInfoGetterTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { pingTimer in
            let jsonString =
            [ COMMAND: "getRoomInfo",
              ROOM_ID: roomId,
              STREAM_ID: self.publisherStreamId ?? ""
            ] as [String: Any]
            
            if (self.isWebSocketConnected) {
                self.webSocket?.write(string: jsonString.json)
            }
            else {
                self.connectWebSocket()
                AntMediaClient.printf("Websocket is not connected to get room info")
            }
            
            //send current video and audio status perodically
            
            if let videoEnabled = self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.isVideoEnabled() {
                self.sendVideoTrackStatusNotification(enabled: videoEnabled)
            }
            
            if let audioEnabled = self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.isAudioEnabled() {
                self.sendAudioTrackStatusNotification(enabled: audioEnabled)
            }
            
            
        }
       
    }
    
    /**
     Called when the server responds with "joined room notification" as a response to "join room" command
     */
    private func joinedRoom(streamId:String, streams:[String]) {
        
        self.publisherStreamId = streamId;
        self.delegate?.streamIdToPublish(streamId: streamId);
        self.streamsInTheRoom = streams;
        
        if (self.streamsInTheRoom.count > 0) {
            self.delegate?.newStreamsJoined(streams:  streams);
        }
        
        reconnectIfRequires()
        
    }
    
    public func leaveFromRoom() {
        roomInfoGetterTimer?.invalidate()
        if (isWebSocketConnected)
        {
            if let roomId = self.mainTrackId {
                let leaveRoomMessage =  [
                    COMMAND: "leaveFromRoom",
                    ROOM_ID: roomId,
                    STREAM_ID: self.publisherStreamId ?? "" ] as [String : Any]
                
                webSocket?.write(string: leaveRoomMessage.json)
                AntMediaClient.printf("Sending leaveRoom message \(leaveRoomMessage.json)");
            }
            else {
                AntMediaClient.printf("Websocket is not connected to send leave from room message");
            }
        }
        if let tmpStreamId = self.publisherStreamId {
            self.webRTCClientMap.removeValue(forKey: tmpStreamId)?.disconnect();
        }
        
        if let tmpStreamId = self.playerStreamId {
            self.webRTCClientMap.removeValue(forKey: tmpStreamId)?.disconnect()
        }
    }
    
    //this configuration don't ask for mic permission it's useful for playback
    public func dontAskMicPermissionForPlaying() {
        let webRTCConfiguration = RTCAudioSessionConfiguration.init()
        webRTCConfiguration.mode = AVAudioSession.Mode.moviePlayback.rawValue
        webRTCConfiguration.category = AVAudioSession.Category.playback.rawValue
        webRTCConfiguration.categoryOptions = AVAudioSession.CategoryOptions.duckOthers
                             
        RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
    }
    
    //this configuration ask mic permission and capture mic record
    public func resetDefaultWebRTCAudioConfiguation() {
        RTCAudioSessionConfiguration.setWebRTC(RTCAudioSessionConfiguration.init())
    }
    
    public func publish(streamId: String, token: String = "", mainTrackId: String = "") {
    
        self.publisherStreamId = streamId;
        //reset default webrtc audio configuation to capture audio and mic
        resetDefaultWebRTCAudioConfiguation();
        initPeerConnection(streamId: streamId, mode: AntMediaClientMode.publish, token: token)
        if (!mainTrackId.isEmpty) {
            self.mainTrackId = mainTrackId
        }
        if (!token.isEmpty) {
            self.publishToken = token;
        }
        if (!isWebSocketConnected) {
            connectWebSocket();
        }
        else {
            sendPublishCommand(streamId)
        }
    }
    
    public func play(streamId: String, token: String = "") {
        
        self.playerStreamId = streamId;
        if (!token.isEmpty) {
            self.playToken = token;
        }
        
        if let streamId = self.publisherStreamId
        {
            if (self.webRTCClientMap[streamId] == nil)
            {
                //if there is not publisherStreamId, don't ask mic permission for playing
                dontAskMicPermissionForPlaying();
            }
        }
        else {
            //if there is not publisherStreamId, don't ask mic permission for playing
            dontAskMicPermissionForPlaying();
        }
        
        
        
        initPeerConnection(streamId: streamId, mode: AntMediaClientMode.play, token: token)
        if (!isWebSocketConnected) {
            connectWebSocket();
        }
        else {
            sendPlayCommand(streamId)
        }
    }
    
    
    /*
     Connect to websocket.
     */
    open func connectWebSocket()
    {
        AntMediaClient.dispatchQueue.async
        {
            AntMediaClient.printf("Connect websocket to \(self.getWsUrl())")
            if (!self.isWebSocketConnected) { //provides backward compatibility
                self.streamsInTheRoom.removeAll();
                AntMediaClient.printf("Will connect to: \(self.getWsUrl()) for stream: \(self.getStreamId())")
                
                self.webSocket = WebSocket(request: self.getRequest())
                self.webSocket?.delegate = self
                self.webSocket?.connect()
                
                
            }
            else {
                AntMediaClient.printf("WebSocket is already connected to: \(self.getWsUrl())")
            }
        }
    }
    
    open func setCameraPosition(position: AVCaptureDevice.Position) {
        self.cameraPosition = position
    }
    
    open func setTargetResolution(width: Int, height: Int) {
        self.targetWidth = width
        self.targetHeight = height
    }
    
    open func setTargetFps(fps: Int) {
        self.cameraSourceFPS = fps;
    }
    
    /*
     Get a default value to make it compatible with old version
     */
    open func stop(streamId:String = "") {
        AntMediaClient.rtcAudioSession.remove(self);
        let tmpStreamId = getStreamId(streamId)
        
        AntMediaClient.printf("Stop is called for \(tmpStreamId)")
                            
        if tmpStreamId == self.p2pStreamId
        {
            //provide backward compatibility
            if tmpStreamId == streamId {
                leave(streamId: tmpStreamId)
            }
        }
        else {
            //removing means that user requests to stop
            self.webRTCClientMap.removeValue(forKey: tmpStreamId)?.disconnect();
            
            if (isWebSocketConnected) {
                let command =  [
                    COMMAND: "stop",
                    STREAM_ID: tmpStreamId] as [String : String];
                
                webSocket?.write(string: command.json)
            }
            else {
                AntMediaClient.printf("Websocket is not connected to stop stream:\(tmpStreamId)")
            }
            
            if (self.publisherStreamId == tmpStreamId) {
                self.publisherStreamId = nil
            }
            else if (self.playerStreamId == tmpStreamId) {
                self.playerStreamId = nil;
            }
        }
        
    }
    
    open func initPeerConnection(streamId: String = "", mode:AntMediaClientMode=AntMediaClientMode.unspecified, token: String = "") {
        
        let id = getStreamId(streamId);
        
        if (self.webRTCClientMap[id] == nil) {
            AntMediaClient.printf("Has wsClient? (start) : \(String(describing: self.webRTCClientMap[id]))")
            
            self.webRTCClientMap[id] = WebRTCClient.init(remoteVideoView: remoteView, localVideoView: localView, delegate: self, mode: mode != .unspecified ? mode : self.mode , cameraPosition: self.cameraPosition, targetWidth: self.targetWidth, targetHeight: self.targetHeight, videoEnabled: self.videoEnable, enableDataChannel: self.enableDataChannel, useExternalCameraSource: self.useExternalCameraSource, externalAudio: self.externalAudioEnabled, externalVideoCapture: self.externalVideoCapture, cameraSourceFPS: self.cameraSourceFPS, streamId:id);
            
            self.webRTCClientMap[id]?.setToken(token)
            
            AntMediaClient.rtcAudioSession.add(self);
        }
        else {
            //it may initialized without correct token parameter because of backward compatibility
            self.webRTCClientMap[id]?.setToken(token)
            AntMediaClient.printf("WebRTCClient already initialized for id:\(id) and mode:\(mode.getName())")
        }
    }
    
    /*
     Just switches the camera. It works on the fly as well
     */
    open func switchCamera() {
        self.webRTCClientMap[(self.publisherStreamId ?? (self.p2pStreamId)) ?? ""]?.switchCamera()
    }

    /*
     Send data through WebRTC Data channel.
     */
    open func sendData(data: Data, binary: Bool = false, streamId: String = "") {
        self.webRTCClientMap[getStreamId(streamId)]?.sendData(data: data, binary: binary)
    }
    
    open func isDataChannelActive(streamId: String = "") -> Bool {
       
        return self.webRTCClientMap[getStreamId(streamId)]?.isDataChannelActive() ?? false
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
        
        AntMediaClient.embedView(localRenderer, into: container)
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
        AntMediaClient.embedView(remoteRenderer, into: remoteContainer)
        
    }
    
    open func disableTrack(trackId:String) {
        self.disableTrackId = trackId;
    }
    
    public static func embedView(_ view: UIView, into containerView: UIView) {
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
        return isWebSocketConnected;
    }
    
    open func setDebug(_ value: Bool) {
        AntMediaClient.isDebug = value
    }
    
    public static func setDebug(_ value: Bool) {
         AntMediaClient.isDebug = value
    }
    
    /*
     Toggle publisher audo
     */
    open func toggleAudio() {
        self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.toggleAudioEnabled()
        
        if let audioEnabled = self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.isAudioEnabled() {
            self.sendAudioTrackStatusNotification(enabled: audioEnabled)
        }
    }
    
    func sendAudioTrackStatusNotification(enabled:Bool)
    {
        var eventType = EVENT_TYPE_MIC_MUTED;
        if (enabled) {
            eventType = EVENT_TYPE_MIC_UNMUTED;
        }
        if let streamId = self.publisherStreamId {
            self.sendNotification(eventType: eventType, streamId:streamId);
        }
    }
    /*
     Set publisher audio track
     */
    open func setAudioTrack(enableTrack: Bool) {
        self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.setAudioEnabled(enabled: enableTrack);
        self.sendAudioTrackStatusNotification(enabled:enableTrack);
    }
    
    func sendNotification(eventType:String, streamId: String = "") {
        let notification =  [
            EVENT_TYPE: eventType,
            STREAM_ID: self.getStreamId()].json;
        
        if let data = notification.data(using: .utf8) {
            self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.sendData(data: data);
        }
       
    }
    
    open func setMicMute( mute: Bool, completionHandler:@escaping(Bool, Error?)->Void)
    {
        AntMediaClient.dispatchQueue.async { () in
           
            AntMediaClient.rtcAudioSession.lockForConfiguration()
            do {
                var category:String;
                if (mute) {
                    category = AVAudioSession.Category.soloAmbient.rawValue;
                }
                else {
                    category = AVAudioSession.Category.playAndRecord.rawValue;
                }
                try AntMediaClient.rtcAudioSession.setCategory(category);
                //playAndRecord category defaults receiver to set to speaker
                try AntMediaClient.rtcAudioSession.overrideOutputAudioPort(.speaker)
                try AntMediaClient.rtcAudioSession.setActive(true);
                self.webRTCClientMap[self.getPublisherStreamId()]?.setAudioEnabled(enabled: !mute);
                self.sendNotification(eventType: mute ? EVENT_TYPE_MIC_MUTED : EVENT_TYPE_MIC_UNMUTED);
                completionHandler(mute, nil);
                
            } catch let error {
                AntMediaClient.printf("Couldn't set to mic status: \(error)")
                completionHandler(mute, error);
            }
            AntMediaClient.rtcAudioSession.unlockForConfiguration()
        }
    }
    
    open func toggleVideo() {
        self.webRTCClientMap[getPublisherStreamId()]?.toggleVideoEnabled()
        
        if let videoEnabled = self.webRTCClientMap[self.publisherStreamId ?? (self.p2pStreamId ?? "")]?.isVideoEnabled() {
            self.sendVideoTrackStatusNotification(enabled: videoEnabled)
        }
    }
    
    func sendVideoTrackStatusNotification(enabled:Bool) {
        var eventType = EVENT_TYPE_CAM_TURNED_OFF;
        if (enabled) {
            eventType = EVENT_TYPE_CAM_TURNED_ON;
        }
        if let streamId = self.publisherStreamId {
            self.sendNotification(eventType: eventType, streamId:streamId);
        }
    }
    
    open func setVideoTrack(enableTrack: Bool)
    {
        self.webRTCClientMap[getPublisherStreamId()]?.setVideoEnabled(enabled: enableTrack);
        self.sendVideoTrackStatusNotification(enabled:enableTrack);
    }
    
    open func getCurrentMode() -> AntMediaClientMode {
        return self.mode
    }
    
    open func getWsUrl() -> String {
        return wsUrl;
    }
    
    fileprivate func sendPublishCommand(_ streamId: String) {
        if isWebSocketConnected {
            let jsonString = getHandshakeMessage(streamId: streamId, mode: AntMediaClientMode.publish, token:self.publishToken ?? "");
            webSocket?.write(string: jsonString)
            AntMediaClient.printf("Send Publish onConnection message: \(jsonString)")
            //Add 3 seconds delay here and reconnectIfRequires has also 3 seconds delay
            AntMediaClient.dispatchQueue.asyncAfter(deadline: .now() + 5.0) {
                self.reconnectIfRequires();
            };
        }
        else {
            AntMediaClient.printf("Websocket is not connected to send Publish message for stream\(streamId)")
        }
    }
    
    func sendJoinConferenceCommand()
    {
        if isWebSocketConnected
        {
            if let roomId = self.mainTrackId {
                let joinRoomMessage =  [
                    COMMAND: "joinRoom",
                    ROOM_ID: roomId,
                    MODE: "multitrack",
                    STREAM_ID: self.publisherStreamId ?? "" ] as [String : String]
                webSocket?.write(string: joinRoomMessage.json)
            }
            else {
                AntMediaClient.printf("mainTrackId is not specified to join the room ");
            }
        }
        else {
            AntMediaClient.printf("Websocket is not connected to send joinConferece message for room \(String(describing: self.mainTrackId))")
        }
    }
    
    fileprivate func sendPlayCommand(_ streamId: String) {
        if (isWebSocketConnected) {
            let jsonString = getHandshakeMessage(streamId: streamId, mode: AntMediaClientMode.play, token: self.playToken ?? "");
            webSocket?.write(string: jsonString)
            AntMediaClient.printf("Play onConnection message: \(jsonString)")
            
            //Add 3 seconds delay here and reconnectIfRequires has also 3 seconds delay
            AntMediaClient.dispatchQueue.asyncAfter(deadline: .now() + 5.0) {
                self.reconnectIfRequires();
            };
            
        }
        else {
            AntMediaClient.printf("Websocket is not connected to send play message for stream: \(streamId)")
        }
    }
    
    fileprivate func sendJoinCommand(_ streamId: String) {
        let jsonString = getHandshakeMessage(streamId: streamId, mode: AntMediaClientMode.join)
        webSocket?.write(string: jsonString)
        AntMediaClient.printf("P2P onConnection message: \(jsonString)")
    }
    
    private func websocketConnected() {
        
        if (isWebSocketConnected) {
            if mode == AntMediaClientMode.conference {
                sendJoinConferenceCommand();
            }
            else if let streamId = self.publisherStreamId {
                sendPublishCommand(streamId)
            }
            else if let streamId = self.playerStreamId {
                sendPlayCommand(streamId)
            }
            else if let streamId = self.p2pStreamId {
                sendJoinCommand(streamId)
            }
        }
        
        self.setupAudioNotifications()
    }
    
    private func websocketDisconnected(message:String, code:UInt16) {
        self.delegate?.clientDidDisconnect(message)
        self.reconnectIfRequires()
        self.removeAudioNotifications()
    }
    
    /**
     Re-connection Scenario based on Ice Connection State because No matter websocket is disconnected or webrtc is disconnected
     , ice Connection states changes to disconnected and below `reconnectIfRequires` method is called when ice connection is disconnected.
     
     `reconnectIfRequires` checks if connection is in the map because if the connection is stopped by the user, it's removed from the map, then there is nothing to do.
     If it's not removed from the map and its state is closed, disconnected or failed it means that is a reconnect scenario is required.
     
    This method is also called after joining a room to check if it requires to reconnect
     
     */
    private func reconnectIfRequires() {
       
        if (self.reconnectIfRequiresScheduled) {
            AntMediaClient.printf("ReconnectIfRequires is already scheduled and it will work soon")
            return;
        }
        
        self.reconnectIfRequiresScheduled = true;
        
        AntMediaClient.dispatchQueue.asyncAfter(deadline: .now() + 3.0) {
            
            self.reconnectIfRequiresScheduled = false;
            
            if let streamId = self.publisherStreamId {
                //if there is a webRTCClient in the map, it means it's disconnected due to network issue
                if (self.webRTCClientMap[streamId] != nil)
                {
                    let iceState = self.webRTCClientMap[streamId]?.getIceConnectionState();
                    
                    //check the ice state if this method is triggered consequently
                    if ( iceState == RTCIceConnectionState.closed ||
                         iceState == RTCIceConnectionState.disconnected ||
                         iceState == RTCIceConnectionState.failed ||
                         iceState == RTCIceConnectionState.new
                    )
                    {
                        //clean the connection
                        self.webRTCClientMap.removeValue(forKey: streamId)?.disconnect()
                        AntMediaClient.printf("Reconnecting to publish the stream:\(streamId)");
                        self.publish(streamId:streamId)
                    }
                    else {
                        AntMediaClient.printf("Not trying to reconnect to publish the stream:\(streamId) because ice connection state is not disconnected");
                    }
                }
            }
            
            if let streamId = self.playerStreamId {
                //if there is a webRTCClient in the map, it means it's disconnected due to network issue
                
                let iceState = self.webRTCClientMap[streamId]?.getIceConnectionState();
                //check the ice state if this method is triggered consequently
                if ( iceState == RTCIceConnectionState.closed ||
                     iceState == RTCIceConnectionState.disconnected ||
                     iceState == RTCIceConnectionState.failed ||
                     iceState == RTCIceConnectionState.new
                )
                {
                    //clean the connection
                    self.webRTCClientMap.removeValue(forKey: streamId)?.disconnect()
                    AntMediaClient.printf("Reconnecting to play the stream:\(streamId)");
                    self.play(streamId:streamId)
                }
                else {
                    AntMediaClient.printf("Not trying to reconnect to play the stream:\(streamId) because ice connection state is not disconnected");
                }
            }
            
            if let streamId = self.p2pStreamId {
                //if there is a webRTCClient in the map, it means it's disconnected due to network issue
                if (self.webRTCClientMap[streamId] != nil) {
                    
                    let iceState = self.webRTCClientMap[streamId]?.getIceConnectionState();
                    //check the ice state if this method is triggered consequently
                    if ( iceState == RTCIceConnectionState.closed ||
                         iceState == RTCIceConnectionState.disconnected ||
                         iceState == RTCIceConnectionState.failed
                    )
                    {
                        //clean the connection
                        self.webRTCClientMap.removeValue(forKey: streamId)?.disconnect()
                        AntMediaClient.printf("Reconnecting to join the stream:\(streamId) because ice connection state is not disconnected");
                        self.join(streamId:streamId)
                    }
                }
            }
        }
    }
    
    private func onJoined() {

    }
    
    
    private func onTakeConfiguration(message: [String: Any], streamId:String) {
        var rtcSessionDesc: RTCSessionDescription
        let type = message["type"] as! String
        let sdp = message["sdp"] as! String
        
        if type == "offer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.offer, sdp: sdp)
            self.webRTCClientMap[streamId]?.setRemoteDescription(rtcSessionDesc, completionHandler: {
                (error) in
                if (error == nil) {
                    self.webRTCClientMap[streamId]?.sendAnswer()
                }
                else {
                    AntMediaClient.printf("Error (setRemoteDescription): " + error!.localizedDescription + " debug description: " + error.debugDescription)
                    
                }
            })
            
        } else if type == "answer" {
            rtcSessionDesc = RTCSessionDescription.init(type: RTCSdpType.answer, sdp: sdp)
            self.webRTCClientMap[streamId]?.setRemoteDescription(rtcSessionDesc, completionHandler: { (error ) in
                
                
            })
        }
    }
    
    private func onTakeCandidate(message: [String: Any], streamId:String) {
        let mid = message["id"] as! String
        let index = message["label"] as! Int
        let sdp = message["candidate"] as! String
        let candidate: RTCIceCandidate = RTCIceCandidate.init(sdp: sdp, sdpMLineIndex: Int32(index), sdpMid: mid)
        self.webRTCClientMap[streamId]?.addCandidate(candidate)
    }
    
    private func onMessage(_ msg: String) {
        if let message = msg.toJSON() {
            guard let command = message[COMMAND] as? String else {
                return
            }
            self.onCommand(command, message: message)
        } else {
            print("WebSocket message JSON parsing error: " + msg)
        }
    }
    
    private func onCommand(_ command: String, message: [String: Any]) {
        
        switch command {
            case "start":
                //if this is called, it's publisher or initiator in p2p
                let streamId = message[STREAM_ID] as! String
                self.webRTCClientMap[streamId]?.createOffer()
                break
            case "stop":
                let streamId = message[STREAM_ID] as! String
                AntMediaClient.dispatchQueue.async {
                    self.webRTCClientMap.removeValue(forKey: streamId)?.disconnect()
                }
                break
            case "takeConfiguration":
                let streamId = message[STREAM_ID] as! String
                self.onTakeConfiguration(message: message, streamId: streamId)
                break
            case "takeCandidate":
                let streamId = message[STREAM_ID] as! String
                self.onTakeCandidate(message: message, streamId: streamId)
                break
            case STREAM_INFORMATION_COMMAND:
                AntMediaClient.printf("stream information command")
                var streamInformations: [StreamInformation] = [];
                
                if let streamInformationArray = message["streamInfo"] as? [Any]
                {
                    for result in streamInformationArray
                    {
                        if let resultObject = result as? [String:Any]
                        {
                            streamInformations.append(StreamInformation(json: resultObject))
                        }
                    }
                }
                self.delegate?.streamInformation(streamInfo: streamInformations);
                
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
                    let streamId = message[STREAM_ID] as! String
                    AntMediaClient.printf("Play started: Let's go")
                    self.delegate?.playStarted(streamId: streamId)
                }
                else if definition == "play_finished" {
                    AntMediaClient.printf("Playing has finished")
                    self.streamsInTheRoom.removeAll();
                    self.delegate?.playFinished(streamId: message[STREAM_ID] as! String)
                }
                else if definition == "publish_started" {
                    let streamId = message[STREAM_ID] as! String
                    AntMediaClient.printf("Publish started: Let's go")
                    self.webRTCClientMap[streamId]?.setMaxVideoBps(maxVideoBps: self.maxVideoBps)
                    self.delegate?.publishStarted(streamId: message[STREAM_ID] as! String)
                }
                else if definition == "publish_finished" {
                    let streamId = message[STREAM_ID] as! String
                    AntMediaClient.printf("Publish finished: Let's close")
                    self.delegate?.publishFinished(streamId: streamId)
                }
                else if definition == JOINED_ROOM_DEFINITION
                {
                    let streamId = message[STREAM_ID] as! String;
                    let streams = message[STREAMS] as! [String];
                    self.joinedRoom(streamId: streamId, streams:streams);
                }
            
                break;
            case ROOM_INFORMATION_COMMAND:
                if let updatedStreamsInTheRoom = message[STREAMS] as? [String] {
                   //check that there is a new stream exists
                    var newStreams:[String] = []
                    var leftStreams: [String] = []
                    for stream in updatedStreamsInTheRoom
                    {
                       // AntMedia.printf("stream in updatestreamInTheRoom \(stream)")
                        if (!self.streamsInTheRoom.contains(stream)) {
                            newStreams.append(stream)
                        }
                    }
                    //check that any stream is left
                   for stream in self.streamsInTheRoom {
                       if (!updatedStreamsInTheRoom.contains(stream)) {
                           leftStreams.append(stream)
                       }
                   }
                    
                    self.streamsInTheRoom = updatedStreamsInTheRoom
                    
                    if (newStreams.count > 0) {
                        self.delegate?.newStreamsJoined(streams: newStreams)
                    }
                    
                    if (leftStreams.count > 0) {
                        self.delegate?.streamsLeft(streams: leftStreams)
                    }
                            
                }
                
                break;
            case "error":
                guard let definition = message["definition"] as? String else {
                    self.delegate?.clientHasError("An error occured, please try again")
                    return
                }
                
                self.delegate?.clientHasError(AntMediaError.localized(definition))
                break
            default:
                AntMediaClient.printf("Unknown message received -> \(message)");
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
    
    public func getStreamInfo()
    {
        if (self.isWebSocketConnected)
        {
            self.webSocket?.write(string: [COMMAND: GET_STREAM_INFO_COMMAND, STREAM_ID: self.playerStreamId].json)
        }
        else {
            AntMediaClient.printf("Websocket is not connected")
        }
    }
    
    public func forStreamQuality(resolutionHeight: Int)
    {
        if (self.isWebSocketConnected)
        {
            self.webSocket?.write(string: [COMMAND: FORCE_STREAM_QUALITY_INFO, STREAM_ID: (self.playerStreamId!), STREAM_HEIGHT_FIELD: resolutionHeight].json)
        }
        else {
            AntMediaClient.printf("Websocket is not connected")
        }
    }
    
    public func getStats(completionHandler: @escaping (RTCStatisticsReport) -> Void, streamId:String = "") {
        self.webRTCClientMap[self.getStreamId(streamId)]?.getStats(handler: completionHandler)
    }
    
    public func getStatistics(
        for streamId: String = "",
        completion: @escaping (ClientStatistics) -> Void
    ) {
        getStats(completionHandler: { report in
            completion(.init(items: report.statistics.extractRTCStatItems()))
        }, streamId: streamId)
    }
    
    public func deliverExternalAudio(sampleBuffer: CMSampleBuffer)
    {
        self.webRTCClientMap[getPublisherStreamId()]?.deliverExternalAudio(sampleBuffer: sampleBuffer);
    }
    
    
    public func setExternalAudio(externalAudioEnabled: Bool) {
        self.externalAudioEnabled = externalAudioEnabled;
    }
    
    public func setExternalVideoCapture(externalVideoCapture: Bool) {
        self.externalVideoCapture = externalVideoCapture;
    }
    
    public func deliverExternalVideo(sampleBuffer: CMSampleBuffer, rotation:Int = -1)
    {
        (self.webRTCClientMap[self.getPublisherStreamId()]?.getVideoCapturer() as? RTCCustomFrameCapturer)?.capture(sampleBuffer, externalRotation: rotation);
    }
    
    public func deliverExternalPixelBuffer(pixelBuffer: CVPixelBuffer, rotation:RTCVideoRotation, timestampNs: Int64) {
        (self.webRTCClientMap[self.getPublisherStreamId()]?.getVideoCapturer() as? RTCCustomFrameCapturer)?.capture(pixelBuffer, rotation: rotation, timeStampNs: timestampNs);
    }
    

    public func enableVideoTrack(trackId:String, enabled:Bool){
        if (isWebSocketConnected) {
            
            let jsonString =  [
                COMMAND: ENABLE_VIDEO_TRACK_COMMAND,
                TRACK_ID: trackId,
                STREAM_ID: self.playerStreamId!,
                ENABLED: enabled].json;
            
            webSocket?.write(string: jsonString);
        }
    }
    
    public func enableAudioTrack(trackId:String, enabled:Bool){
        if (isWebSocketConnected) {
            
            let jsonString =  [
                COMMAND: ENABLE_AUDIO_TRACK_COMMAND,
                TRACK_ID: trackId,
                STREAM_ID: self.playerStreamId!,
                ENABLED: enabled].json;
            
            webSocket?.write(string: jsonString);
        }
    }
    
    public func enableTrack(trackId:String, enabled:Bool){
        if (isWebSocketConnected)
        {
            let jsonString =  [
                COMMAND: ENABLE_TRACK_COMMAND,
                TRACK_ID: trackId,
                STREAM_ID: self.playerStreamId!,
                ENABLED: enabled].json;
            
            webSocket?.write(string: jsonString);
        }
        else {
            AntMediaClient.printf("Websocket is not connected to enableTRack for track: \(trackId) in stream: \(self.playerStreamId)")
        }
    }
    
    public func disconnect() {
        for (streamId, webrtcClient) in self.webRTCClientMap {
            webrtcClient.disconnect()
        }
             
        self.webRTCClientMap.removeAll();
        self.webSocket?.disconnect();
        self.webSocket = nil;
        
    }
    
}

extension AntMediaClient: WebRTCClientDelegate {

        
    func trackAdded(track: RTCMediaStreamTrack, stream: [RTCMediaStream]) {
        self.delegate?.trackAdded(track: track, stream: stream)
    }
    
    func trackRemoved(track: RTCMediaStreamTrack) {
        self.delegate?.trackRemoved(track: track)
    }
    
    
    public func sendMessage(_ message: [String : Any]) {
        self.webSocket?.write(string: message.json)
    }
    
    public func addLocalStream(streamId:String) {
        self.delegate?.localStreamStarted(streamId: streamId)
    }
    
    public func remoteStreamAdded(streamId:String) {
        self.delegate?.remoteStreamStarted(streamId: streamId)
    }
    
    func remoteStreamRemoved(streamId:String) {
        self.delegate?.remoteStreamRemoved(streamId: streamId)
    }
    
    
    public func connectionStateChanged(newState: RTCIceConnectionState, streamId:String) {
        if newState == RTCIceConnectionState.closed ||
            newState == RTCIceConnectionState.disconnected ||
            newState == RTCIceConnectionState.failed
        {
            var state:String = "closed"
            if (newState == RTCIceConnectionState.disconnected) {
                state = "disconnected";
            }
            else {
                state = "failed";
            }
            
            AntMediaClient.printf("connectionStateChanged: \(state) for stream: \(String(describing:streamId))")
            AntMediaClient.dispatchQueue.async {
                self.reconnectIfRequires()
                self.delegate?.disconnected(streamId: streamId);
            }
        }
    }
    
    public func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer, streamId:String) {
        
        let rawJSON = String(decoding: data.data, as: UTF8.self)
        let json = rawJSON.toJSON();
      
        if let eventType = json?[EVENT_TYPE] {
            //event happened
            if let incomingStreamId = json?[STREAM_ID] {
                self.delegate?.eventHappened(streamId:incomingStreamId as! String , eventType:eventType as! String);
            }
            else {
                AntMediaClient.printf("Incoming message does not have streamId:\(json)")
            }
        }
        else {
            self.delegate?.dataReceivedFromDataChannel(streamId: streamId, data: data.data, binary: data.isBinary);
        }
    }
    
}

extension AntMediaClient: WebSocketDelegate {
    public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected(let headers):
            isWebSocketConnected = true;
            AntMediaClient.printf("websocket is connected: \(headers)")
            self.websocketConnected()
            self.delegate?.clientDidConnect(self)
            
            //too keep the connetion alive send ping command for every 10 seconds
            pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { pingTimer in
                let jsonString = self.getPingMessage().json
                self.webSocket?.write(string: jsonString)
            }
            break;
        case .disconnected(let reason, let code):
            isWebSocketConnected = false;
            AntMediaClient.printf("websocket is disconnected: \(reason) with code: \(code)")
            pingTimer?.invalidate()
            self.websocketDisconnected(message:reason, code:code)
          
            break;
        case .text(let string):
            //AntMediaClient.printf("Received text: \(string)");
            self.onMessage(string)
            break;
        case .binary(let data):
            AntMediaClient.printf("Received data: \(data.count)")
            break;
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isWebSocketConnected = false;
            pingTimer?.invalidate()
            webSocket?.disconnect();
           
            AntMediaClient.printf("Websocket is cancelled");
            break;
        case .error(let error):
            isWebSocketConnected = false;
            pingTimer?.invalidate()
            webSocket?.disconnect();
            self.websocketDisconnected(message: String(describing: error), code:0);
            AntMediaClient.printf("Error occured on websocket connection \(String(describing: error))");
            break;
        default:
            AntMediaClient.printf("Unexpected command received from websocket");
            break;
        }
    }
    
    public func getPingMessage() -> [String: String] {
        return [COMMAND: "ping"]
    }
}

extension AntMediaClient: RTCAudioSessionDelegate
{
    
    public func audioSessionDidStartPlayOrRecord(_ session: RTCAudioSession) {
        self.delegate?.audioSessionDidStartPlayOrRecord(streamId: self.getStreamId())
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
