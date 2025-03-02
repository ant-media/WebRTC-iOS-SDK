//
//  String.swift
//  AntMediaSDK
//
//

import Foundation

public extension String {
    
    func toURL() -> URL {
        return URL(string: self)!
    }
    
    func toJSON() -> [String: Any]? {
        let data = self.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                return jsonArray
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}
