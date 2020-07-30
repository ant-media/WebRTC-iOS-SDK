//
//  WebRTCClientDelegate.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 6.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import WebRTC

internal protocol WebRTCClientDelegate {
    
    func sendMessage(_ message: [String: Any])
    
    func addRemoteStream()
    
    func addLocalStream()
    
    func connectionStateChanged(newState: RTCIceConnectionState);
    
    func dataReceivedFromDataChannel(didReceiveData data: RTCDataBuffer);
}
