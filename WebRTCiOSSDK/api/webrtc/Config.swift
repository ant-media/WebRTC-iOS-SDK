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
    
    //You can also set the turn server address for this
    private static var stunServer: String = "stun:stun.l.google.com:19302"
    private static var username: String = ""
    private static var password: String = ""

    private static let constraints: [String: String] = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
    private static let defaultConstraints: [String: String] = ["DtlsSrtpKeyAgreement": "true"]
    
    private static var rtcSdpSemantics = RTCSdpSemantics.unifiedPlan
    
    /**
     * You can set the turn server as well. If you need to add username and password, please use the setDefaultStunServer(server: String, user:String, pass:String)
     */
    public static func setDefaultStunServer(server: String) {
        stunServer = server
    }
    /**
     * You can set the turn server as well. If you need to add username and password
     */
    public static func setDefaultStunServer(server: String, user:String, pass:String) {
        stunServer = server
        username = user
        password = pass
    }
    
    public static func setSdpSemantics(sdpSemantics: RTCSdpSemantics) {
        rtcSdpSemantics = sdpSemantics
    }
    
    static func defaultStunServer() -> RTCIceServer {
        return RTCIceServer(urlStrings: [stunServer], username: username, credential: password)
    }
    
    static func createAudioVideoConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: defaultConstraints)
    }
    
    static func createDefaultConstraint() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: defaultConstraints)
    }
    
    static func createTestConstraints() -> RTCMediaConstraints {
        return RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: constraints)
    }
    
    static func createConfiguration(server: RTCIceServer) -> RTCConfiguration {
        let config = RTCConfiguration()
        config.iceServers = [server]
        config.sdpSemantics = rtcSdpSemantics
        return config
    }
}
