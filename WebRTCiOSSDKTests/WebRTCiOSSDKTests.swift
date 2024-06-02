//
//  WebRTCiOSSDKTests.swift
//  WebRTCiOSSDKTests
//
//  Created by mekya on 06/05/2023.
//

import XCTest
@testable import WebRTCiOSSDK

final class WebRTCiOSSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRegisterStatsListener() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let client = AntMediaClient.init();
        XCTAssertNotNil(client);
        XCTAssertNil(client.rtcStatsTimer);
        
        client.registerStatsListener(for: "stream1", timeInterval:1)
    
        XCTAssertNotNil(client.rtcStatsTimer);
        XCTAssertTrue(client.rtcStatsStreamIdSet.contains("stream1"))
        
        RunLoop.current.run(until: Date().addingTimeInterval(2))

        let rtcStatsTimerExpectation = expectation(description: "rtcStatsTimer Invalidated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if (client.rtcStatsTimer == nil && client.rtcStatsStreamIdSet.isEmpty) {
                rtcStatsTimerExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [rtcStatsTimerExpectation], timeout: 3)
        
    }

    //func testPerformanceExample() throws {
        // This is an example of a performance test case.
      //  self.measure {
      //  }
    //}

}
