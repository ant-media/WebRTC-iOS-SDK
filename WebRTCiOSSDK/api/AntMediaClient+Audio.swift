//
//  AntMediaClient+Audio.swift
//  WebRTCiOSSDK
//
//  Created by applebro on 21/03/24.
//

import Foundation
import AVFoundation

extension AntMediaClient {
    func setupAudioNotifications() {
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
    }
    
    func removeAudioNotifications() {
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.removeObserver(self,
                          name: AVAudioSession.interruptionNotification,
                          object: AVAudioSession.sharedInstance())
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        
        // Switch over the interruption type.
        switch type {
        case .began:
            // An interruption began. Update the UI as necessary.
            AntMediaClient.printf("Audio: interruption began")
            break
        case .ended:
            // An interruption ended. Resume playback, if appropriate.
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // An interruption ended. Resume playback.
                AntMediaClient.printf("Audio: interruption ended and should resume playback")
                activateAudioSession()
            } else {
                // An interruption ended. Don't resume playback.
                AntMediaClient.printf("Audio: interruption ended and should not resume playback")
            }
        default: ()
        }
    }
    
    private func activateAudioSession() {
        DispatchQueue(label: "audio").async {() in
            AntMediaClient.rtcAudioSession.lockForConfiguration()
            AntMediaClient.rtcAudioSession.isAudioEnabled = true
            AntMediaClient.rtcAudioSession.unlockForConfiguration()
            AntMediaClient.printf("Audio: Activated")
        }
    }
}
