//
//  GamePegTests.swift
//  NotPeggleTests
//
//  Created by Ying Gao on 12/2/21.
//

import XCTest
@testable import NotPeggle

class GamePegTests: XCTestCase {

    var peg: GamePeg? {
        GamePeg(pegColor: .blue, pos: CGPoint(x: 50, y: 80), radius: 25.0)
    }

    func testCollision() {
        let cannonBall = CannonBall(angle: 0, coord: CGPoint(x: 100, y: 80))
        let distCannon = CannonBall(angle: 0, coord: CGPoint(x: 50, y: 200))
        guard let peg = peg else {
            XCTFail("Init should not fail")
            return
        }
        XCTAssertFalse(peg.hit)
        peg.handleCollision(object: distCannon)
        XCTAssertFalse(peg.hit)
        peg.handleCollision(object: cannonBall)
        XCTAssertTrue(peg.hit)
        peg.handleCollision(object: distCannon)
        XCTAssertTrue(peg.hit)
    }

}
