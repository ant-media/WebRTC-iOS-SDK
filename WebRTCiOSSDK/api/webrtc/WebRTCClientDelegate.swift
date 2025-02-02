//
//  WebRTCClientDelegate.swift
//  AntMediaSDK
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import WebRTC

internal protocol WebRTCClientDelegate: AnyObject {
    
    func sendMessage(_ message: [String: Any])
    
    /**
     It's triggered when remote stream is added to the peer connection.
     */
    func remoteStreamAdded(streamId: String)
    
    /**
     It's called when remote steram is removed from the peer connection
     */
    func remoteStreamRemoved(streamId: String)
    
    /**
     It's called when a new track is added to the stream
     */
    func trackAdded(track: RTCMediaStreamTrack, stream: [RTCMediaStream])
    
    /**
     It's called when a tack is removed
     */
    func trackRemoved(track: RTCMediaStreamTrack)
    
    func addLocalStream(streamId: String)
    
    func connectionStateChanged(newState: RTCIceConnectionState, streamId: String)
    
    func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer, streamId: String)
}
