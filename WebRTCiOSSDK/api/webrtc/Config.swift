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
    
    static var iceServers: [RTCIceServer] = [RTCIceServer.init(urlStrings: [stunServer], username: "", credential: "")]
    
    public static func setDefaultStunServers(_ servers: [RTCIceServer]) {
        iceServers = servers;
    }
    
    public static func addStunServer(_ server: RTCIceServer) {
        iceServers.append(server)
    }
    
    public static func setSdpSemantics(sdpSemantics:RTCSdpSemantics) {
        rtcSdpSemantics = sdpSemantics;
    }
    
    static func defaultStunServers() -> [RTCIceServer] {
        return iceServers
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
    
    static func createConfiguration(servers: [RTCIceServer]) -> RTCConfiguration {
        let config = RTCConfiguration.init()
        config.iceServers = servers
        config.sdpSemantics = rtcSdpSemantics;
        return config
    }
}
