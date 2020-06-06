//
//  Config.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 6.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import WebRTC

class Config: NSObject {
    
    private let stunServer : String = "stun:stun.l.google.com:19302"
    private let constraints: [String: String] = ["OfferToReceiveAudio": "true",
                                                 "OfferToReceiveVideo": "true",]
    private let defaultConstraints: [String: String] = ["DtlsSrtpKeyAgreement": "true"]
    
    func defaultStunServer() -> RTCIceServer {
        let iceServer = RTCIceServer.init(urlStrings: [stunServer], username: "", credential: "")
        return iceServer
    }
    
    func createAudioVideoConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints.init(mandatoryConstraints: constraints, optionalConstraints: defaultConstraints)
    }
    
    func createDefaultConstraint() -> RTCMediaConstraints {
        return RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: defaultConstraints)
    }
    
    func createTestConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: constraints)
    }
    
    func createConfiguration(server: RTCIceServer) -> RTCConfiguration {
        let config = RTCConfiguration.init()
        config.iceServers = [server]
        return config
    }
}
