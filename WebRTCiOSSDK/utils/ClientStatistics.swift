//
//  ClientStatistics.swift
//  WebRTCiOSSDK
//
//  Created by applebro on 30/03/24.
//

import Foundation
import WebRTC

public enum RTCStatType: String {
    case track = "track"
    case candidate_pair = "candidate-pair"
    case remote_candidate = "remote-candidate"
    case local_candidate = "local-candidate"
    case media_source = "media-source"
    case stream = "stream"
    case remote_inbound_rtp = "remote-inbound-rtp"
    case outbound_rtp = "outbound-rtp"
    case transport = "transport"
    case certificate = "certificate"
    case data_channel = "data-channel"
    case peer_connection = "peer-connection"
    case codec = "codec"
    case unknown
}

public struct RTCStatItem {
    public var id: String
    public var key: String
    public var type: RTCStatType
    public var timestamp: CFTimeInterval
    public var values: [String: NSObject]
}

public struct ClientStatistics {
    public private(set) var items: [RTCStatItem]
    
    public var audioSource: RTCStatItem? {
        items.first(where: {$0.type == .media_source && $0.values["kind"] as? String == "audio"})
    }
    
    public var videoSource: RTCStatItem? {
        items.first(where: {$0.type == .media_source && $0.values["kind"] as? String == "video"})
    }
    
    public var audioLevel: Double {
        audioSource?.values["audioLevel"] as? Double ?? 0
    }
}
