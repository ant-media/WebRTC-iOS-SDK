//
//  Dictionary.swift
//  AntMediaSDK
//
//  Created by Oğulcan on 27.05.2018.
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation

public extension Dictionary {

    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
}
