//
//  AntMediaError.swift
//  AntMediaSDK
//
//  Copyright © 2018 AntMedia. All rights reserved.
//

import Foundation

class AntMediaError {
    
    static func localized(_ message: String) -> String {
        switch message {
            case "no_stream_exist":
                return "No stream exists on server."
            case "unauthorized_access":
                return "Unauthorized access: Check your token"
            default:
                return "An error occured: " + message
        }
    }
    
}
