//
//  NetworkQuality.swift
//  WebRTCiOSSDK
//
//  Created by applebro on 30/04/24.
//

import Foundation
import Foundation
import Network

protocol NetworkQualityMonitorDelegate: AnyObject {
    func didDetectNetworkQualityChange(_ networkQuality: NetworkQuality)
}

enum NetworkQuality {
    case good
    case poor
}

class NetworkQualityMonitor {
    weak var delegate: NetworkQualityMonitorDelegate?
    
    // Known server to ping for latency measurement
    let host = "example.com"
    let port = 80 // HTTP port

    init() {
        // Start monitoring
        let queue = DispatchQueue(label: "NetworkMonitor")
        queue.async { [weak self] in
            self?.startMonitoring()
        }
    }

    private func startMonitoring() {
        while true {
            let pingTime = pingHost()
            let networkQuality = evaluateNetworkQuality(pingTime: pingTime)
            delegate?.didDetectNetworkQualityChange(networkQuality)
            // Wait for some time before next ping
            sleep(5)
        }
    }

    private func pingHost() -> TimeInterval {
        var timeInterval: TimeInterval = -1
        let semaphore = DispatchSemaphore(value: 0)
        
        let host = NWEndpoint.Host(host)
        
        guard let port = NWEndpoint.Port(rawValue: UInt16(port)) else {
            return timeInterval
        }

        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let startTime = CFAbsoluteTimeGetCurrent()
                connection.send(content: nil, completion: .contentProcessed { _ in
                    timeInterval = CFAbsoluteTimeGetCurrent() - startTime
                    semaphore.signal()
                })
            case .failed(let error):
                print("Connection failed with error: \(error)")
                semaphore.signal()
            default:
                break
            }
        }
        
        connection.start(queue: DispatchQueue.global())
        semaphore.wait()
        connection.cancel()

        return timeInterval
    }

    private func evaluateNetworkQuality(pingTime: TimeInterval) -> NetworkQuality {
        if pingTime >= 0 && pingTime <= 0.2 { // Assuming 200ms as threshold for good quality
            return .good
        } else {
            return .poor
        }
    }
}
