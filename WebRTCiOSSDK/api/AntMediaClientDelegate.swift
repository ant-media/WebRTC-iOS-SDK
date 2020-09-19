//
//  AntMediaClientDelegate.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 25.05.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation

public class StreamInformation {
   public let streamWidth: Int
   public let streamHeight: Int
   public let videoBitrate: Int
   public let audioBitrate: Int
   public let videoCodec: String
    
    init(json: [String: Any]!) {
        self.streamWidth = json["streamWidth"] as! Int;
        self.streamHeight = json["streamHeight"] as! Int;
        self.videoBitrate = json["videoBitrate"] as! Int;
        self.audioBitrate = json["audioBitrate"] as! Int;
        self.videoCodec = json["videoCodec"] as! String;
    }
}
public protocol AntMediaClientDelegate {

    /**
     Called when websocket is connected
     */
    func clientDidConnect(_ client: AntMediaClient)

    /**
     Called when websocket is disconnected
     */
    func clientDidDisconnect(_ message: String)
    
    /**
     Called when websocket connection has error
     */
    func clientHasError(_ message: String)
    
    /**
     Called when stream is added to peer to peer connection.
     This is a low level communicatin and it's good to use in P2P mode.
     Not good to use in publish and play mode
     */
    func remoteStreamStarted(streamId: String)
    
    /**
     Called when stream is removed from peer to peer connection
     This is a low level notification and it's good to use in P2P mode.
     Not good to use in publish and play mode
    */
    func remoteStreamRemoved(streamId: String)
    
    /**
     Called when local audio and video is started
     */
    func localStreamStarted(streamId: String)
    
    
    /**
     Called when playing is started.
     Triggered by server.
     */
    func playStarted(streamId: String)
    
    /**
     Called when playing is finished.
     Triggered by server.
     */
    func playFinished(streamId: String)
    
    /**
     Called when publish is started.
     Triggered by server.
     */
    func publishStarted(streamId: String)
    
    /**
     Called when publish is finished.
     Triggered by server.
     */
    func publishFinished(streamId: String)
    
    /**
     Called when peer to peer connection is failed, disconnected or closed
    */
    func disconnected(streamId: String)
    
    /**
     Called when audio session start play or record
     */
    func audioSessionDidStartPlayOrRecord(streamId: String)
    
    /**
     Called when data is received from webrtc data channel.
     You can convert data to String as follows
       String(decoding: data, as: UTF8.self)
     
     If you receive json data you can parse it after converting string this
       let message = msg.toJSON();
     Then you can access each field by their values like.
     
     Assume that  {"command":"message","content":"hello"} is received.
     
     Convert it to String and then parse the json
       let rawJSON =  String(decoding: data, as: UTF8.self)
       let json = rawJSON.toJSON();
     
     Access command and content as follows
     json["command"]
     json["content"]
     
     */
    func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool)
    
    func streamInformation(streamInfo: [StreamInformation])
}
