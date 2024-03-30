//
//  Dictionary+Extensions.swift
//  WebRTCiOSSDK
//
//  Created by applebro on 30/03/24.
//

import Foundation
import WebRTC

extension Dictionary where Key == String, Value == RTCStatistics {
    func extractRTCStatItems() -> [RTCStatItem] {
        var extractedItems: [RTCStatItem] = []

        // Iterate through the dictionary
        for (key, object) in self {
            // Extract values from each object
            let id = object.id
            let type = object.type
            let timestamp = object.timestamp_us
            let item = RTCStatItem(
                id: id,
                key: key,
                type: RTCStatType(rawValue: type) ?? .unknown,
                timestamp: timestamp,
                values: object.values
            )
            // Append the RTCStatItem to the array
            extractedItems.append(item)
        }

        return extractedItems
    }
}

