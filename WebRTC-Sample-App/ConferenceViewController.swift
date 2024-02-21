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

open class ConferenceViewController: UIViewController , AVCaptureVideoDataOutputSampleBufferDelegate, RTCVideoViewDelegate{
    
    /*
     PAY ATTENTION
        ConferenceViewController supports Multitrack Conferencing and the old way is deprecated
     */
    var clientUrl: String!
    var roomId: String!
    var publisherStreamId: String!
    
    @IBOutlet var localView: UIView!
    @IBOutlet var remoteView0: UIView!
    @IBOutlet var remoteView1: UIView!
    @IBOutlet var remoteView2: UIView!
    @IBOutlet var remoteView3: UIView!
        
    var remoteViews:[RTCVideoRenderer] = []
    
    //keeps which remoteView renders which track according to the index
    var remoteViewTrackMap: [RTCVideoTrack?] = [];
        
    var conferenceClient: AntMediaClient?;
            
    func generateRandomAlphanumericString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in characters.randomElement()! })
    }
    
    func initRenderer(view: UIView)
    {
        #if arch(arm64)
        let localRenderer = RTCMTLVideoView(frame: view.frame)
        localRenderer.videoContentMode =  .scaleAspectFit
        #else
        let localRenderer = RTCEAGLVideoView(frame: view.frame)
        localRenderer.delegate = self
        #endif
        
        localRenderer.frame = view.bounds
        
        localRenderer.isHidden = true;
        AntMediaClient.embedView(localRenderer, into: view)
        remoteViews.append(localRenderer)
        remoteViewTrackMap.append(nil);
       
    }
    
    open override func viewWillAppear(_ animated: Bool)
    {
        
        //init renderers because front end manage the viewers
        initRenderer(view: remoteView0)
        initRenderer(view: remoteView1)
        initRenderer(view: remoteView2)
        initRenderer(view: remoteView3)
       
        
        AntMediaClient.setDebug(true)
        self.conferenceClient =  AntMediaClient.init();
        self.conferenceClient?.delegate = self
        self.conferenceClient?.setWebSocketServerUrl(url: self.clientUrl)
        self.conferenceClient?.setLocalView(container: self.localView)
        
        //this publishes stream to the room
        self.publisherStreamId = generateRandomAlphanumericString(length: 10);
        self.conferenceClient?.publish(streamId: self.publisherStreamId, token: "", mainTrackId: roomId);
        
        //this plays the streams in the room
        self.conferenceClient?.play(streamId: self.roomId);
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        //stop playing
        self.conferenceClient?.stop(streamId: self.roomId);
        
        //stop publishing
        self.conferenceClient?.stop(streamId: self.publisherStreamId);

        
    }
    
    public func removePlayers() {
        Run.onMainThread { [self] in
            var i = 0;
            
            while (i < remoteViewTrackMap.count)
            {
                remoteViewTrackMap[i] = nil;
                if let view = remoteViews[i] as? RTCMTLVideoView {
                    view.isHidden = true;
                }
                else if let view = remoteViews[i] as? RTCEAGLVideoView {
                    view.isHidden = true;
                }
                i += 1
            }
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
        //tracks are in this format ARDAMSv+ streamId or ARDAMSa + streamId
        let streamId =  track.trackId.suffix(track.trackId.count - "ARDAMSv".count);
        
        if (streamId == self.publisherStreamId) {
            
            //TODO: Refactor here to have a better solution. I mean server should not send this track
            // When we have single object to publish and play the streams. It can be done.
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                //It's delay for 3 seconds because in some cases server enables while adding local stream
                self.conferenceClient?.enableTrack(trackId: String(streamId), enabled: false);
            }
            track.isEnabled = false;
            return;
            
        }
        
        AntMediaClient.printf("Track is added with id:\(track.trackId) and stream id:\(streamId)")
        if let videoTrack = track as? RTCVideoTrack
        {
            //find the view to render
            var i = 0;
            while (i < remoteViewTrackMap.count) {
                if (remoteViewTrackMap[i] == nil) {
                    break
                }
                i += 1
            }
            
            if (i < remoteViewTrackMap.count) {
                //keep the track reference
                remoteViewTrackMap[i] = videoTrack;
                videoTrack.add(remoteViews[i]);
                
                Run.onMainThread { [self] in
                    if let view = self.remoteViews[i] as? RTCMTLVideoView {
                        view.isHidden = false;
                    }
                    else if let view = remoteViews[i] as? RTCEAGLVideoView {
                        view.isHidden = false;
                    }
                }
            }
            else {
                AntMediaClient.printf("No space to render new video track")
            }
                
        }
        else {
            AntMediaClient.printf("New track is not video track")
        }
    }
    
    public func trackRemoved(track: RTCMediaStreamTrack) {
        
        Run.onMainThread { [self] in
            var i = 0;
            
            while (i < remoteViewTrackMap.count)
            {
                if (remoteViewTrackMap[i]?.trackId == track.trackId)
                {
                    remoteViewTrackMap[i] = nil;
                    
                    if let view = remoteViews[i] as? RTCMTLVideoView {
                        view.isHidden = true;
                    }
                    else if let view = remoteViews[i] as? RTCEAGLVideoView {
                        view.isHidden = true;
                    }
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
    }
    
    public func publishFinished(streamId: String) {
        AntMediaClient.printf("Publish finished for stream:\(streamId)")
    }
    
    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        AntMediaClient.printf("Video size changed to " + String(Int(size.width)) + "x" + String(Int(size.height)) + ". These changes are not handled in Simulator for now")
    }
}

