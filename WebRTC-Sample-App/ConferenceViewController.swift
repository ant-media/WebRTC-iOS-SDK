//
//  ConferenceViewController.swift
//  AntMediaReferenceApplication
//
//  Created by mekya on 13.08.2020.
//  Copyright © 2020 AntMedia. All rights reserved.
//

import UIKit
import Foundation
import WebRTC
import WebRTCiOSSDK

open class ConferenceViewController: UIViewController ,  AVCaptureVideoDataOutputSampleBufferDelegate, RTCVideoViewDelegate{
    
    /*
     PAY ATTENTION
        ConferenceViewController supports Multitrack Conferencing and the old way is deprecated
     */
    var clientUrl: String!
    var roomId: String!
    var publisherStreamId: String!
    
    @IBOutlet var localView: UIView!
        
    @IBOutlet weak var collectionView: UICollectionView!
    
    //keeps which remoteView renders which track according to the index
    var remoteViewTrackMap: [RTCVideoTrack?] = [];
        
    var conferenceClient: AntMediaClient?;
    
    func generateRandomAlphanumericString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in characters.randomElement()! })
    }
    

    
    open override func viewWillAppear(_ animated: Bool)
    {
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        AntMediaClient.setDebug(true)
        self.conferenceClient =  AntMediaClient.init();
        self.conferenceClient?.delegate = self
        self.conferenceClient?.setWebSocketServerUrl(url: self.clientUrl)
        self.conferenceClient?.setLocalView(container: self.localView)
        
        //this publishes stream to the room
        self.publisherStreamId = generateRandomAlphanumericString(length: 10);
        self.conferenceClient?.publish(streamId: self.publisherStreamId, token: "", mainTrackId: roomId);
        
        //this plays the streams in the room
        
        //self.conferenceClient?.play(streamId: self.roomId);
        
        //In order to make the play consistent, we've moved this method to the publish_started callback below
        //because if this is the first user and second user join the call immediately after this user,
        //it takes up to 8 seconds to play the stream. Because it thinks there is no user in the room,
        //it will try to play again after timeout(5 secs) and it may take about 2-3 seconds to start play
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        //stop playing
        self.conferenceClient?.stop(streamId: self.roomId);
        
        //stop publishing
        self.conferenceClient?.stop(streamId: self.publisherStreamId);
    }
    
    public func removePlayers() {
        Run.onMainThread { [self] in
            remoteViewTrackMap.removeAll();
            collectionView.reloadData()
        }
    }
}


extension ConferenceViewController: AntMediaClientDelegate
{
    public func clientHasError(_ message: String) {
        
    }
    
    public func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {

        
    }
    
    public func clientDidDisconnect(_ message: String) {
        removePlayers();
    }
    public func playStarted(streamId: String) {
        print("play started");
        AntMediaClient.speakerOn();
    }
    
    public func trackAdded(track: RTCMediaStreamTrack, stream: [RTCMediaStream]) {
                
        AntMediaClient.printf("Track is added with id:\(track.trackId)")
        if let videoTrack = track as? RTCVideoTrack
        {
            remoteViewTrackMap.append(videoTrack);
            Run.onMainThread {
                self.collectionView.reloadData()
            }
        }
    }
    
    public func trackRemoved(track: RTCMediaStreamTrack) {
        
        Run.onMainThread { [self] in
            var i = 0;
            
            while (i < remoteViewTrackMap.count)
            {
                if (remoteViewTrackMap[i]?.trackId == track.trackId)
                {
                    remoteViewTrackMap.remove(at: i)
                    collectionView.reloadData();
                    break;
                }
                i += 1
            }
        }
        
    }
    
    public func playFinished(streamId: String) {
        removePlayers();
    }
    
    public func publishStarted(streamId: String) {
        AntMediaClient.printf("Publish started for stream:\(streamId)")
                
        //this plays the streams in the room
        self.conferenceClient?.play(streamId: self.roomId);
        
        conferenceClient?.getBroadcastObject(forStreamId: self.roomId)

    }
    
    public func publishFinished(streamId: String) {
        AntMediaClient.printf("Publish finished for stream:\(streamId)")
    }
    
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        AntMediaClient.printf("Video size changed to " + String(Int(size.width)) + "x" + String(Int(size.height)) + ". These changes are not handled in Simulator for now")
    }
    
    public func onLoadBroadcastObject(streamId: String, message: [String : Any]) {
           debugPrint(streamId)
           debugPrint(message)
    }
    
    public func eventHappened(streamId: String, eventType: String, payload: [String : Any]?) 
    {
        debugPrint("Event: \(streamId) - \(eventType) \(payload ?? [:])")
        
        if eventType == EVENT_TYPE_TRACK_LIST_UPDATED {
            conferenceClient?.getBroadcastObject(forStreamId: streamId)
        }
        else if (eventType == EVENT_TYPE_VIDEO_TRACK_ASSIGNMENT_LIST) {
            
            if let unwrappedPayload = payload?["payload"] as? [[String: Any]] {
            
                //let array = unwrappedPayload as? [[String: Any]]
                for (item) in unwrappedPayload
                {
                    if let trackId = item["trackId"] as? String,
                       let videoLabel = item["videoLabel"] as? String
                    {
                        
                        print("videoLabel:\(videoLabel) plays the trackId:\(trackId)")
                        //On the server side, we create WebRTC tracks with ARDAMSv{VIDEO_LABEL}
                        //It's useful in limiting/dynamic allocation of the streams and tracks in a conference call
                        //If you want to make sure, which webrtc track is playing which real streamId,
                        //you can learn from here
                        
                        //i.e. you receive ARDAMSvvideoTrack0 in trackAdded method above, then you'll receive this event
                        //and it will tell you videoTrack0 is playing the specific streamId.
                        //If ARDAMSvvideoTrack0 starts to play another trackId, then you'll receive this event again.
                    }
                }
            }
        }
    }
}

extension ConferenceViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remoteViewTrackMap.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "playerCell", for: indexPath) as! CellView;
        cell.videoTrack = remoteViewTrackMap[indexPath.item];
        cell.playerView.videoContentMode = .scaleAspectFit
        remoteViewTrackMap[indexPath.item]?.add(cell.playerView)
        
        return cell
    }
    
}

extension ConferenceViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       let columns: CGFloat = 2
       let collectionViewWidth = collectionView.bounds.width
       let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
       let spaceBetweenCells = flowLayout.minimumInteritemSpacing * (columns - 1)
       let adjustedWidth = collectionViewWidth - spaceBetweenCells
       let width: CGFloat = adjustedWidth / columns
       let height: CGFloat = 200
       return CGSize(width: width, height: height)
        
    }
}

