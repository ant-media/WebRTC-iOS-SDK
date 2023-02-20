//
//  Config.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 6.06.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation
import WebRTC

public class Config: NSObject {
    
    private static let stunServer : String = "stun:stun.l.google.com:19302"
    private static let constraints: [String: String] = ["OfferToReceiveAudio": "true",
                                                 "OfferToReceiveVideo": "true",]
    private static let defaultConstraints: [String: String] = ["DtlsSrtpKeyAgreement": "true"]
    
    private static var rtcSdpSemantics = RTCSdpSemantics.unifiedPlan;
    
    static var iceServer:RTCIceServer = RTCIceServer.init(urlStrings: [stunServer], username: "", credential: "")
    
    public static func setDefaultStunServer(server: RTCIceServer) {
        iceServer = server;
    }
    
    public static func setSdpSemantics(sdpSemantics:RTCSdpSemantics) {
        rtcSdpSemantics = sdpSemantics;
    }
    
    static func defaultStunServer() -> RTCIceServer {
        return iceServer
    }
    
    static func createAudioVideoConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints.init(mandatoryConstraints: constraints, optionalConstraints: defaultConstraints)
    }
    
    static func createDefaultConstraint() -> RTCMediaConstraints {
        return RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: defaultConstraints)
    }
    
    static func createTestConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: constraints)
    }
    
    static func createConfiguration(server: RTCIceServer) -> RTCConfiguration {
        let config = RTCConfiguration.init()
        config.iceServers = [server]
        config.sdpSemantics = rtcSdpSemantics;
        return config
    }
}
