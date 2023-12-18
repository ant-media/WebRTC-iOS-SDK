//
//  AntMediaClientDelegate.swift
//  AntMediaSDK
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import WebRTC

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
public protocol AntMediaClientDelegate: AnyObject {

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
     Called when stream is added to peer connection.
     */
    func remoteStreamStarted(streamId: String)
    
    /**
     Called when stream is removed from peer to peer connection
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
    
    /**
     It's called when there is an event happen such microphone is muted or unmuted for the specific streamId
    - Parameters
     - streamId: The id of the stream that the event happened
     - evenType: The type of the event
     */
    func eventHappened(streamId:String, eventType:String);
    
    func statusChangedMic(streamId: String, value:Bool)
    
    func statusChangedCam(streamId: String, value:Bool)
    
    func statusChangedPin(streamId: String, value:Bool)
    
    func statusChangedShareScreen(streamId: String, value:Bool)
    
    func audioLevelChanged(streamId: String, value:Double)
    
    /**
     It's called when a new track is added to the stream. It works both on multirack streaming and conferencing
     */
    func trackAdded(track:RTCMediaStreamTrack, stream:[RTCMediaStream])
    
    /**
     It's called when a tack is removed. It works both on multitrack streaming and conferencing
     */
    func trackRemoved(track:RTCMediaStreamTrack)
    
    /**
     It's called after join to the room.
     - streamId: the id of the stream tha can be used to publish stream.
        It's not an obligation to publish a stream. It changes according to the project
     */
    func streamIdToPublish(streamId: String);
    
    /**
      Called when new streams join to the room
     - streams:  stream id array of the streams that join to the room
     */
    func newStreamsJoined(streams: [String]);
    
    /**
     Called when some streams leaves from the room. So that players can be removed from the user interface
     - streams: stream id array of the stream that leaves from the room
     */
    func streamsLeft(streams: [String]);
    
}

public extension AntMediaClientDelegate {
    
    func clientDidConnect(_ client: AntMediaClient) {
        AntMediaClient.printf("Websocket is connected for \(client.getStreamId())")
    }
        
    func eventHappened(streamId: String, eventType: String) {
        AntMediaClient.printf("Event: \(eventType) happened in stream: \(streamId) ")
    }
    
    func clientDidDisconnect(_ message: String) {
        AntMediaClient.printf("Websocket is disconnected with this problem:\(message)");
    }
    
    func trackAdded(track:RTCMediaStreamTrack, stream:[RTCMediaStream]) {
        AntMediaClient.printf("Track is added with id:\(track.trackId) and kind:\(track.kind)")
    }
    
    func trackRemoved(track:RTCMediaStreamTrack) {
        AntMediaClient.printf("Track is removed with id:\(track.trackId) and kind:\(track.kind)")
    }
    
    func playFinished(streamId: String) {
        AntMediaClient.printf("Play finished for stream with id:\(streamId)")
    }

    func playStarted(streamId: String) {
        AntMediaClient.printf("Play started for stream with id:\(streamId)")
    }

    func remoteStreamStarted(streamId: String) {
        AntMediaClient.printf("Remote stream is started for stream with id:\(streamId)")
    }
    
    func remoteStreamRemoved(streamId: String) {
        AntMediaClient.printf("Remote stream is removed for stream with id:\(streamId)")
    }
    
    func localStreamStarted(streamId: String) {
        AntMediaClient.printf("Local stream is started for stream with id:\(streamId)")
    }
    
    func disconnected(streamId: String) {
        AntMediaClient.printf("Peer connections is disconnected for stream with id:\(streamId)")
    }
    
    func audioSessionDidStartPlayOrRecord(streamId: String) {
        AntMediaClient.printf("Audio session is started to play or record for stream with id:\(streamId)")
    }
    
    func streamInformation(streamInfo: [StreamInformation]) {
        AntMediaClient.printf("Stream information has received")
        for result in streamInfo {
            AntMediaClient.printf("resolution width:\(result.streamWidth) heigh:\(result.streamHeight) video " + "bitrate:\(result.videoBitrate) audio bitrate:\(result.audioBitrate) codec:\(result.videoCodec)");
        }
    }
    
    func streamIdToPublish(streamId: String) {
        AntMediaClient.printf("Joined the room and stream Id to publish is \(streamId)")
    }
    
    /**
      Called when new streams join to the room
     - streams:  stream id array of the streams that join to the room
     */
    func newStreamsJoined(streams: [String]) {
        for stream in streams {
            AntMediaClient.printf("New stream in the room: \(stream)")
        }
    }
    
    /**
     Called when some streams leaves from the room. So that players can be removed from the user interface
     - streams: stream id array of the stream that leaves from the room
     */
    func streamsLeft(streams: [String]) {
        for stream in streams {
            AntMediaClient.printf("Stream: \(stream) left from the room")
        }
    }
    
    func statusChangedMic(streamId: String, value:Bool) {
//        AntMediaClient.printf("Mic status changed for stream with id:\(streamId) value:\(value)")
    }
    
    func statusChangedCam(streamId: String, value:Bool) {
//        AntMediaClient.printf("Camera status changed for stream with id:\(streamId) value:\(value)")
    }
    
    func statusChangedPin(streamId: String, value:Bool) {
//        AntMediaClient.printf("Pin status changed for stream with id:\(streamId) value:\(value)")
    }
    
    func statusChangedShareScreen(streamId: String, value:Bool) {
//        AntMediaClient.printf("Share screen status changed for stream with id:\(streamId) value:\(value)")
    }
    
    func audioLevelChanged(streamId: String, value:Double) {
        
    }
}

