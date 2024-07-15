//
//  CellView.swift
//  WebRTC-Sample-App
//
//  Created by Ahmet Oguz Mermerkaya on 15.07.2024.
//

import Foundation
import UIKit
import WebRTC
public class CellView: UICollectionViewCell {
    
    
    @IBOutlet weak var playerView: RTCMTLVideoView!
    
    var videoTrack:RTCVideoTrack?
    
    public override func prepareForReuse() {
        videoTrack?.remove(playerView)
    }
    
}
