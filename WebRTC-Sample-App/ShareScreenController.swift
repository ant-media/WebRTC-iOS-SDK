//
//  ShareScreenController.swift
//  WebRTC-Sample-App
//
//  Created by Muhammadjon Tohirov on 08/02/25.
//

import Foundation
import UIKit
import WebRTCiOSSDK
import ReplayKit

final class ShareScreenController: UIViewController {
    var broadcastPicker: RPSystemBroadcastPickerView!
    private let draggableRectangle = UIView()
    private var lastLocation = CGPoint.zero
    private let userDefaults: UserDefaults = UserDefaults(suiteName: "group.io.antmedia.sbd.webrtc.sample")!
    private let imageView: UIImageView = .init()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews()
        self.setupShareScreen()
        self.setupDraggableRectangle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        broadcastPicker.frame = .init(
            x: (view.bounds.width - broadcastPicker.bounds.width) / 2,
            y: view.bounds.height - broadcastPicker.bounds.height - 20,
            width: broadcastPicker.bounds.width,
            height: broadcastPicker.bounds.height
        )
        
        imageView.frame = view.bounds
    }

    private func setupShareScreen() {
        let ssBundle = "antmedia.sbd.sample.screen"
        broadcastPicker.preferredExtension = ssBundle;
    }
    
    private func setupSubviews() {
        broadcastPicker = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: 50, height: 50))
        view.addSubview(imageView)
        view.addSubview(broadcastPicker)
        view.addSubview(draggableRectangle)
        view.backgroundColor = .secondarySystemBackground
        
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
    }
    
    private func setupDraggableRectangle() {
        draggableRectangle.frame = CGRect(x: 50, y: 100, width: 200, height: 200)
        draggableRectangle.layer.borderColor = UIColor.black.cgColor
        draggableRectangle.layer.borderWidth = 2
        draggableRectangle.backgroundColor = UIColor.clear
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        draggableRectangle.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        
        if let view = gesture.view {
            let newX = view.center.x + translation.x
            let newY = view.center.y + translation.y
            
            // Ensure it stays within bounds
            let minX = view.safeAreaInsets.left + view.frame.width / 2
            let maxX = self.view.frame.width - view.safeAreaInsets.right - view.frame.width / 2
            let minY = self.view.safeAreaInsets.top + view.frame.height / 2
            let maxY = broadcastPicker.frame.minY - view.frame.height / 2
            
            let clampedX = max(minX, min(newX, maxX))
            let clampedY = max(minY, min(newY, maxY))
            
            view.center = CGPoint(x: clampedX, y: clampedY)
            gesture.setTranslation(.zero, in: self.view)
            
            if gesture.state == .ended {
                print("Final Rectangle Frame: \(view.frame)")
                publishFrame(view.frame)
            }
        }
    }
    
    func publishFrame(_ frame: CGRect) {
        let value: [CGFloat] = [
            frame.minX, frame.minY, frame.width, frame.height
        ]
        userDefaults.set(value, forKey: "screenShareFrame")
    }
}
