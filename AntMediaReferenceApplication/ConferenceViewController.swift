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

open class ConferenceViewController: UIViewController {
   
    /*
     PAY ATTENTION
        ConferenceViewController supports Multitrack Conferencing and the old way is deprecated
     */
    var conferenceClient: ConferenceClient!
    var clientUrl: String!
    var roomId: String!
    var publisherStreamId: String!
    
    @IBOutlet var localView: UIView!
    @IBOutlet var remoteView0: UIView!
    @IBOutlet var remoteView1: UIView!
    @IBOutlet var remoteView2: UIView!
    @IBOutlet var remoteView3: UIView!
        
    @IBOutlet weak var joinButton: UIButton!
    var remoteViews:[RTCVideoRenderer] = []
    
    //keeps which remoteView renders which track according to the index
    var remoteViewTrackMap: [RTCVideoTrack?] = [];
        
    var publishStream:Bool = false;
    
    var publisherClient: AntMediaClient?;
    var playerClient: AntMediaClient?;
   
        
    @IBAction func joinButtonTapped(_ sender: Any) {
        AntMediaClient.printf("button tapped");
        publishStream = !publishStream;
        var title:String;
        
        //TODO: don't use flag(publishStream), use more trusted info @mekya
        if (publishStream) {
            self.publisherClient?.start();
            title = "Stop";
        }
        else {
            self.publisherClient?.stop();
            title = "Publish"
        }
        joinButton.setTitle(title, for: .normal);
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
        conferenceClient = ConferenceClient.init(serverURL: self.clientUrl, conferenceClientDelegate: self)
        conferenceClient.joinRoom(roomId: self.roomId, streamId: "")
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.publisherClient?.stop()
        self.playerClient?.stop();
        conferenceClient.leaveRoom()
    }
}

extension ConferenceViewController: ConferenceClientDelegate
{
    public func streamIdToPublish(streamId: String) {
        
        Run.onMainThread {
        
            AntMediaClient.printf("stream id to publish \(streamId)")
            
            self.publisherStreamId = streamId;
            self.publisherClient =  AntMediaClient.init();
            self.publisherClient?.delegate = self
            self.publisherClient?.setOptions(url: self.clientUrl, streamId: self.publisherStreamId, token: "", mode: AntMediaClientMode.publish, enableDataChannel: false)
            self.publisherClient?.setRoomId(roomId: self.roomId);
            
            self.publisherClient?.setLocalView(container: self.localView)
           
            self.publisherClient?.initPeerConnection()
           // self.publisherClient?.start()
            
            
        }
        
    }
    

    public func newStreamsJoined(streams: [String]) {
        for stream in streams {
            AntMediaClient.printf("New stream in the room: \(stream)")
        }
        
        Run.onMainThread {
            if (self.playerClient == nil) {
                //Just initialize once because it handles adding/removing new tracks in the backend
                self.playerClient = AntMediaClient.init()
                self.playerClient?.delegate = self;
                self.playerClient?.setOptions(url: self.clientUrl, streamId: self.roomId, token: "", mode: AntMediaClientMode.play, enableDataChannel: true);
                AntMediaClient.printf("disable track id: \(self.publisherStreamId)")
                self.playerClient?.disableTrack(trackId:self.publisherStreamId);
                
                self.playerClient?.start()
            }
        }
        
    }
       
    public func streamsLeft(streams: [String]) {
        
        for stream in streams {
            AntMediaClient.printf("Stream(\(stream)) left the room")
        }
    }
}


extension ConferenceViewController: AntMediaClientDelegate
{
    public func clientDidDisconnect(_ message: String) {
        
    }
    
    public func clientHasError(_ message: String) {
        
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
                self.playerClient?.enableTrack(trackId: String(streamId), enabled: false);
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
        self.playerClient = nil;
        
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
    
    public func publishStarted(streamId: String) {
        AntMediaClient.printf("Publish started for stream:\(streamId)")
    }
    
    public func publishFinished(streamId: String) {
        
    }
    
    public func disconnected(streamId: String) {
        
    }
    
    public func audioSessionDidStartPlayOrRecord(streamId: String) {
        
    }
    
    public func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    public func streamInformation(streamInfo: [StreamInformation]) {
        
    }
}

