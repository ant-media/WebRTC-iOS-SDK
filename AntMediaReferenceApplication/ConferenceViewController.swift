//
//  ConferenceViewController.swift
//  AntMediaReferenceApplication
//
//  Created by mekya on 13.08.2020.
//  Copyright © 2020 AntMedia. All rights reserved.
//

import UIKit
import Foundation
import WebRTCiOSSDK

open class ConferenceViewController: UIViewController {
   
    var conferenceClient: ConferenceClient!
    var clientUrl: String!
    var roomId: String!
    var publisherStreamId: String!
    
    @IBOutlet var localView: UIView!
    @IBOutlet var remoteView0: UIView!
    @IBOutlet var remoteView1: UIView!
    @IBOutlet var remoteView2: UIView!
    @IBOutlet var remoteView3: UIView!
        
    var remoteViews:[UIView] = []
    
    var viewFree:[Bool] = [true, true, true, true]
    
    var publisherClient: AntMediaClient?;
    var playerClients:[AntMediaClientConference] = [];
    
    class AntMediaClientConference {
        var playerClient: AntMediaClient;
        var viewIndex: Int;
        
        init(player: AntMediaClient, index: Int) {
            self.playerClient = player;
            self.viewIndex = index
        }
    }
    
    
    
    open override func viewWillAppear(_ animated: Bool)
    {
        remoteViews.append(remoteView0)
        remoteViews.append(remoteView1)
        remoteViews.append(remoteView2)
        remoteViews.append(remoteView3)
        AntMediaClient.setDebug(true)
        conferenceClient = ConferenceClient.init(serverURL: self.clientUrl, conferenceClientDelegate: self)
        conferenceClient.joinRoom(roomId: self.roomId, streamId: "")
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        self.publisherClient?.stop()
        for client in playerClients
        {
            client.playerClient.stop();
        }
        conferenceClient.leaveRoom()
    }
    
    
}

extension ConferenceViewController: ConferenceClientDelegate
{
    public func streamIdToPublish(streamId: String) {
        
        Run.onMainThread {
        //
            AntMediaClient.printf("stream id to publish \(streamId)")
            
            self.publisherStreamId = streamId;
            self.publisherClient =  AntMediaClient.init();
            self.publisherClient?.delegate = self
            self.publisherClient?.setOptions(url: self.clientUrl, streamId: self.publisherStreamId, token: "", mode: AntMediaClientMode.publish, enableDataChannel: false)
            
            self.publisherClient?.setLocalView(container: self.localView)
           
            self.publisherClient?.initPeerConnection()
            self.publisherClient?.start()
            
        }
           
    }
       
    public func newStreamsJoined(streams: [String]) {
        
        AntMediaClient.printf("Room current capacity: \(playerClients.count)")
        if (playerClients.count == 4) {
            AntMediaClient.printf("Room is full")
            return
        }
        Run.onMainThread {
            
        
            for stream in streams
            {
                AntMediaClient.printf("stream in the room: \(stream)")
                let playerClient = AntMediaClient.init()
                playerClient.delegate = self;
                playerClient.setOptions(url: self.clientUrl, streamId: stream, token: "", mode: AntMediaClientMode.play, enableDataChannel: false)
                
                var freeIndex: Int = -1
                for (index,free) in self.viewFree.enumerated() {
                    if (free) {
                        freeIndex = index;
                        self.viewFree[index] = false;
                        break;
                    }
                }
                if (freeIndex == -1) {
                    AntMediaClient.printf("Problem in free view index")
                }
                playerClient.setRemoteView(remoteContainer: self.remoteViews[freeIndex])
                playerClient.initPeerConnection()
                playerClient.start()
                self.remoteViews[freeIndex].isHidden = false
                
                let playerConferenceClient = AntMediaClientConference.init(player: playerClient, index: freeIndex);
                
                self.playerClients.append(playerConferenceClient)
                
            }
        }
       
           
    }
       
    public func streamsLeaved(streams: [String]) {
        
        Run.onMainThread {
        
            var leavedClientIndex:[Int] = []
            for streamId in streams
            {
                for  (clientIndex,conferenceClient) in self.playerClients.enumerated()
                {
                    if (conferenceClient.playerClient.getStreamId() == streamId) {
                        conferenceClient.playerClient.stop();
                        self.remoteViews[conferenceClient.viewIndex].isHidden = true
                        self.viewFree[conferenceClient.viewIndex] = true
                        leavedClientIndex.append(clientIndex)
                        break;
                    }
                }
            }
            
            for index in leavedClientIndex {
                self.playerClients.remove(at: index);
            }
        }
    }
}

extension ConferenceViewController: AntMediaClientDelegate
{
    public func clientDidConnect(_ client: AntMediaClient) {
        AntMediaClient.printf("Websocket is connected")
    }
    
    public func clientDidDisconnect(_ message: String) {
        
    }
    
    public func clientHasError(_ message: String) {
        
    }
    
    public func remoteStreamStarted(streamId: String) {
        
    }
    
    public func remoteStreamRemoved(streamId: String) {
        
    }
    
    public func localStreamStarted(streamId: String) {
        
    }
    
    public func playStarted(streamId: String) {
        print("play started");
        
    }
    
    public func playFinished(streamId: String) {
        
    }
    
    public func publishStarted(streamId: String) {
        
    }
    
    public func publishFinished(streamId: String) {
        
    }
    
    public func disconnected(streamId: String) {
        
    }
    
    public func audioSessionDidStartPlayOrRecord(streamId: String) {
        
    }
    
    public func dataReceivedFromDataChannel(streamId: String, data: Data, binary: Bool) {
        
    }
    
    
}
