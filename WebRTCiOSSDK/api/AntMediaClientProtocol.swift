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
let TOKEN_ID = "token"
let VIDEO = "video"
let AUDIO = "audio"
let ROOM_ID = "room";
let NOTIFICATION = "notification";
let JOINED_ROOM_DEFINITION = "joinedTheRoom";
let DEFINITION = "definition";
let STREAMS = "streams";
let ROOM_INFORMATION_COMMAND = "roomInformation";
let GET_STREAM_INFO_COMMAND = "getStreamInfo";
let STREAM_INFORMATION_COMMAND = "streamInformation";
let FORCE_STREAM_QUALITY_INFO = "forceStreamQuality";
let STREAM_HEIGHT_FIELD = "streamHeight";

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
        on the server. If it's .publish, it mean your WebRTC client will publish stream with your stream id.
        - enableDataChannel: Enable or disable data channel on the mobile side. In order to make data channel work, you also need to enable it on server side
    */
    func setOptions(url: String, streamId: String, token: String, mode: AntMediaClientMode ,enableDataChannel: Bool, captureScreenEnabled: Bool)
    
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
    func speakerOn();
    
    /**
    Set the speaker off. It works if audio session is already started so calling this method may not work if it's called too early.
    The correct place to call it in AntMediaClientDelegate's `audioSessionDidStartPlayOrRecord` method.
    */
    func speakerOff();
    
    /**
     Initializes the peer connection and opens the camera if it's publish mode but it does not start the streaming. It's not necessary to call this method. `start()` method calls this method if it's required. This method is generally used opening the camera and let the user tap a button to start publishing
     */
    func initPeerConnection()
    
    /**
    Starts the streaming according to the mode of the client.
    */
    func start();
    
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
    Stops the connection and release resources
     */
    func stop();
    
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
    func sendData(data: Data, binary: Bool);
    
    /**
    Status of the data channel. Both server and mobile side, should enable data channel to let this method return true
    - Returns: true if data channel is active, false if it's disabled
    */
    func isDataChannelActive() -> Bool;
    
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
    Toggle audio in the current stream. If it's muted, it will be unmuted. If it's unmuted, it'll be muted.
     */
    func toggleAudio();
    
    /**
     Toggle video stream(enable, disable) in the current stream.
     */
    func toggleVideo();
    
    /**
     Stream id that this client uses.
     */
    func getStreamId() -> String;
    
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
    func getStats(completionHandler: @escaping (RTCStatisticsReport) -> Void);
}


