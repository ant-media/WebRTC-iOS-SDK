//
//  AntMediaClientProtocol.swift
//  WebRTCiOSSDK
//
//  Created by mekya on 8.08.2020.
//  Copyright © 2020 AntMedia. All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC

let COMMAND = "command"
let STREAM_ID = "streamId"
let TRACK_ID = "trackId"
let ENABLED = "enabled"
let TOKEN_ID = "token"
let VIDEO = "video"
let AUDIO = "audio"
let ROOM_ID = "room";
let MODE = "mode";
let NOTIFICATION = "notification";
let JOINED_ROOM_DEFINITION = "joinedTheRoom";
let DEFINITION = "definition";
let STREAMS = "streams";
let STREAM_LIST_IN_ROOM = "streamList";
let ROOM_INFORMATION_COMMAND = "roomInformation";
let GET_STREAM_INFO_COMMAND = "getStreamInfo";
let STREAM_INFORMATION_COMMAND = "streamInformation";
let FORCE_STREAM_QUALITY_INFO = "forceStreamQuality";
let STREAM_HEIGHT_FIELD = "streamHeight";
let EVENT_TYPE = "eventType";
let EVENT_TYPE_MIC_MUTED = "MIC_MUTED"
let EVENT_TYPE_MIC_UNMUTED = "MIC_UNMUTED";
let EVENT_TYPE_CAM_TURNED_OFF = "CAM_TURNED_OFF";
let EVENT_TYPE_CAM_TURNED_ON = "CAM_TURNED_ON";

let STATUS_MIC = "mic"
let STATUS_CAM = "camera"
let STATUS_PIN = "isPinned"
let STATUS_SCREEN_SHARE = "isScreenShared"

let ENABLE_TRACK_COMMAND = "enableTrack"
let ENABLE_VIDEO_TRACK_COMMAND = "toggleVideo"
let ENABLE_AUDIO_TRACK_COMMAND = "toggleAudio"

let UPDATE_STATUS = "UPDATE_STATUS"

let AUDIO_LEVEL_CHANGED = "UPDATE_AUDIO_LEVEL"

let AUDIO_LEVEL = "audioLevel"

public protocol AntMediaClientProtocol {
        
    /**
     Sets the required options to for Ant Media Client to Run
     - Parameters:
        - url: Full Ant Media Server's websocket url. You can use ws or wss . It should be something
        ws://your_server_address:5080/WebRTCAppEE/websocket
        wss://your_server_address:5443/WebRTCAppEE/websocket
        - streamId: The stream id that you use in your connection. You either play or publish with this stream id.
        - token: If you active one-time token on server side, you should enter token value in here. If one-time token is not activated, just leave empty
        - mode: The Mode of the Client. It should .play, .publish or .join. If it's .play, it means your WebRTC client will play a stream with your streamId
        - streamerName: Streamer name
        on the server. If it's .publish, it mean your WebRTC client will publish stream with your stream id.
        - enableDataChannel: Enable or disable data channel on the mobile side. In order to make data channel work, you also need to enable it on server side
        - useExternalCameraSource: If useExternalCameraSource is false, it opens the local camera. If it's true, it does not open the local camera.
        When it's set to true, it can record the screen in-app or you can give external frames through your application or BroadcastExtension. If you give external frames or you use BroadcastExtension, you need to set the externalVideoCapture to true as well
        - meta: Additional information to be sent to the server as Json String
    */
    @available(*, deprecated, message: "Use setEnableDataChannel and useExternalCameraSource.")
    func setOptions(url: String, streamId: String, streamerName: String, token: String, mode: AntMediaClientMode ,enableDataChannel: Bool, useExternalCameraSource: Bool, meta: String?)
    
    /**
     Set room Id to use in video conferencing
     */
    @available(*, deprecated, message: "Use joinRoom command as in the sample ")
    func setRoomId(roomId:String);
    
    /**
     Set websocket srver url such as wss://example.com:5443/WebRTCAppEE/websocket
     */
    func setWebSocketServerUrl(url: String)
    
    /**
     Enable/disable data channel before starting the connection
     */
    func setEnableDataChannel(enableDataChannel: Bool)
    
    /**
     Enable to use external camera source to publish stream
     */
    func setUseExternalCameraSource(useExternalCameraSource: Bool);
        
    /**
     Enable or disable video completely in the WebRTC Client.  It should be called before `initPeerConnection()` and `start()` method.
     It's generally used for disabling video in order to have only audio streaming. If video is disabled by this method, it's not enabled in the same session again. Video is enabled by default.
     - Parameters:
         enable: Enable or disable video in the connection.
     */
    func setVideoEnable( enable: Bool)
    
    /**
     Set the speaker on. It works if audio session is already started so calling this method may not work if it's called too early.
     The correct place to call it in AntMediaClientDelegate's `audioSessionDidStartPlayOrRecord` method.
     */
    static func speakerOn();
    
    /**
    Set the speaker off. It works if audio session is already started so calling this method may not work if it's called too early.
    The correct place to call it in AntMediaClientDelegate's `audioSessionDidStartPlayOrRecord` method.
    */
    static func speakerOff();
    
    /**
     Initializes the peer connection and opens the camera if it's publish mode but it does not start the streaming. It's not necessary to call this method. `start()` method calls this method if it's required. This method is generally used opening the camera and let the user tap a button to start publishing
     - Parameters
     streamId: is the id of the stream to be initialized
     */
    func initPeerConnection(streamId:String, mode:AntMediaClientMode, token: String)
    
    /**
    Starts the streaming according to the mode of the client.
     @Deprecated use `publish` and `play` method
    */
    func start();
    
    /// Publish stream to the server with streamId and roomId.
    /// - Parameters:
    /// - streamId: the id of the stream that is going to be published.
    /// - streamerName: Streamer name
    /// - mainTrackId: the id of the main stream or conference room  that this stream will be published. It's optional value
    /// - token: token for securing streaming
    /// - streamerMeta: streaming additional info as Json String
    func publish(streamId: String, streamerName: String, token: String, mainTrackId: String, streamerMeta: String);
    
    /**
     Starts to play a stream on the server side
     - Parameters
       - streamId: the id of the stream or id of the conference room. It supports playing both of them
    */
    func play(streamId:String, token:String)
    
    /**
    Sets the camera position front or back. This method is effective if it's called before `initPeerConnection()` and `start()` method.
     - Parameters:
        - position: The camera position to open
     */
    func setCameraPosition(position: AVCaptureDevice.Position);
    
    /**
    Sets the camera resolution. This method is effective if it's called before `initPeerConnection()` and `start()` method.
     - Parameters:
        - width: Resolution width
        - height:Resolution height
     */
    func setTargetResolution(width: Int, height: Int);
    
    /**
     Set target camera fps(frame per second). It's 30fps by default
     */
    func setTargetFps(fps:Int);
    
    /**
    Stops the connection and release resources. It is a common method to stop publishing, stop playing, stop p2p and conferencing
     */
    func stop(streamId:String);
    
    /**
    Switches camera on the fly.
     */
    func switchCamera()
    
    /**
    Sends data via WebRTC's Data Channel.
     - Parameters:
        - data: The Data to send via data channel
        - binary:  The type of data. It should be true, if it's binary
     */
    func sendData(data: Data, binary: Bool, streamId: String);
    
    /**
    Status of the data channel. Both server and mobile side, should enable data channel to let this method return true
    - Returns: true if data channel is active, false if it's disabled
    */
    func isDataChannelActive(streamId:String) -> Bool;
    
    /**
     The UIView element that local camera view will be rendered to.
     - Parameters
        - container: The UI View element
        -  mode: Scale mode of the view. 
     */
    func setLocalView( container: UIView, mode:UIView.ContentMode)
    
    /**
    The UIView element that remote stream(playing stream) will be rendered to.
    - Parameters
       - container: The UI View element
       -  mode: Scale mode of the view.
    */
    func setRemoteView(remoteContainer: UIView, mode:UIView.ContentMode)
    
    /**
     - Returns: true if websocket is connected, false if websocket is not connected
     */
    func isConnected() -> Bool;
    
    /**
     Set the debug mode. If it's true, log messages will be available.
     */
    @available(*, deprecated, message: "Use static version of setDebug")
    func setDebug(_ value: Bool);
    
    
    /**
      Set the debug mode.  If it's true, log messages will be written to the console. It's disabled by default.
     */
    static func setDebug(_ value: Bool);
    
    /**
     Toggle audio mute/unmuted in the local stream that is being published to the AMS.. If it's muted, it will be unmuted. If it's unmuted, it'll be muted.
      Alternatively you can use ``setAudioTrack(enableTrack:)`` to have the same functionality.
      It does not mute/unmute the microphone. If you need to mute/unmute microphone, use ``setMicMute(mute:completionHandler:)``
        
    */
    func toggleAudio();
    
    /**
     Set the local audio track enable/disable. It does not change the mic status. It just enable/disable the local audio track.
     This method is just another version of ``toggleAudio()``
     If you need to mute/unmute microphone, use ``setMicMute(mute:completionHandler:)``
     */
    func setAudioTrack(enableTrack:Bool);
    
    /**
     Swith the audio muted/unmuted. If mute is true, audio is being set to mute. If mute is false, audio bis being set to unmute
     */
    func setMicMute( mute: Bool, completionHandler:@escaping(Bool, Error?)->Void)

    
    /**
     Toggle video stream(enable, disable) in the current stream for local video
     */
    func toggleVideo();
    
    /**
     Set the video track status enable/disable. It does not open/close the camera status. Just disable/enable the in the local video track
     */
    func setVideoTrack(enableTrack:Bool);
    
    /**
     Stream id that this client uses. There maybe more than one  stream id in the client such publish and play. It returns the one that is set.
     */
    func getStreamId(_ streamId:String) -> String;
   
    /**
     Gets the stream info from the server side. Return information includes width, height, video bitrate, audio bitrates and video codec.
     If there are more than one bitrate or resolution, it will provides a stream information list.
     This method triggers streamInformation delegate method to be called. If there is no stream with initialized WebRTCClient, it will not trigger streamInformation.
     Server return no stream exists error through websocket.
     
     With the information in the message of streamInformation, you can call the forceStreamQuality method.
     */
    func getStreamInfo();
    
    /**
      It forces a specific resolution to be played. You can get the resolution height values by calling getStreamInfo.
      If the resolution is set to 0, then automatic stream quality will be used according to the measured network speed.
     */
    func forStreamQuality(resolutionHeight:Int);
    /**
     It get webrtc statistis and calls completionHandler.  There is a sample code for below to get the audio level
     in the application latyer
     
     self.client.getStats { (statisticsReport) in
         
         for stat in statisticsReport.statistics {
            
             if (stat.value.type == "track") {
                 for value in stat.value.values
                 {
                     if (value.key == "audioLevel") {
                         AntMediaClient.printf("audio level: \(value.value)");
                     }
                 }
             }
         }
     };
     */
    func getStats(completionHandler: @escaping (RTCStatisticsReport) -> Void, streamId:String);
    
    /**
     Set the max video bitrate for publishing the stream
     */
    func setMaxVideoBps(videoBitratePerSecond: NSNumber);
    
    //
    //Deliver external audio to the Ant Media Client. It's likely coming from Broadcast Extension
    //
    func deliverExternalAudio(sampleBuffer: CMSampleBuffer);
    
    //
    //Set external audio if audio is coming from Broadcast Extension.
    //It initializes the WebRTC client accordingly
    //
    func setExternalAudio(externalAudioEnabled: Bool);
    
    //
    //Set external video if video is coming from Broadcast Extension
    //
    func setExternalVideoCapture(externalVideoCapture: Bool);
    
    /**
     Deliver external video to the webrtc stack.
     - sampleBuffer: Raw video frame buffer to pass to webrtc stack to be encoded
     - rotation: The rotation of the frame. If you give -1 as parameter, then it will be tried to get rotation from sampleBuffer
        you can give 0 for up,  180 for down, 90 for left, 270 for right
     */
    func deliverExternalVideo(sampleBuffer: CMSampleBuffer, rotation:Int);
    
    /**
     Deliver external pixel buffer to the capturer.
     */
    func deliverExternalPixelBuffer(pixelBuffer: CVPixelBuffer, rotation:RTCVideoRotation, timestampNs: Int64);
    
    /**
     Enable/disable  to play the video track. If it's disabled, then server does not send video frames for the track.
     - Parameters
        - trackId
     */
    func enableVideoTrack(trackId:String, enabled:Bool);
    
    /**
     Enable/disable to play the audio track. If it's disabled, then server does not send audio frame for the track.
     */
    func enableAudioTrack(trackId:String, enabled:Bool);
    
    /**
     Enable/disable to play the  track(video,audio) track together.  If it's disabled, then server does not send audio frame for the track.
     */
    func enableTrack(trackId:String, enabled:Bool)
    
    /**
     Call this method to join a conference room
     - Parameters
     - roomId: The id of the room to join.
     - streamId: The willing id of the stream to be published. It's optional. Server may accept the streamId or return with another streamId in streamIdToPublish method
     - streamerName: The name of the streamer. It's optional
     - meta: Meta data to be sent to the server. It's optional
     */
    func joinRoom(roomId:String, streamId: String, streamerName: String, meta: String?)
    
    /**
     Leave from a room. It stops both publishing and playing. If you just would like to stop publish or play, just call stop command with your streamId parameter
     */
    func leaveFromRoom()
    
    /**
    Join a P2P call
     */
    func join(streamId:String)
    
    /**
      Disconnects  websocket connection
     */
    func disconnect();
    
}
