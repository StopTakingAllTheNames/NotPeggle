//
//  GameEngine.swift
//  NotPeggle
//
//  Created by Ying Gao on 10/2/21.
//

import UIKit

/**
 Game-specific engine.
 */
class GameEngine: PhysicsWorldDelegate, GamePegDelegate {

    // ================ //
    // MARK: Properties
    // ================ //

    private(set) var ballLaunched = false
    private(set) var world: PhysicsWorld

    private(set) var launchPoint: CGPoint
    private(set) var launchAngle: CGFloat

    private(set) var cannon: CannonBall?
    private(set) var gamePegs: [GamePeg] = []
    private(set) var gameBlocks: [GameBlock] = []

    private(set) var shotsLeft = 0
    private(set) var score = 0
    private(set) var requiredScore = 0

    weak var delegate: GameEngineDelegate?

    init(frame: CGRect, delegate: GameEngineDelegate?) {
        world = PhysicsWorld(frame: frame, excluding: .bottom)
        let xCoord = frame.width / 2
        let yCoord = CGFloat(Constants.pegRadius)
        launchPoint = CGPoint(x: xCoord, y: yCoord)
        launchAngle = CGFloat.pi / 2
        world.setDelegate(self)
        self.delegate = delegate
    }

    /// Adds the `GamePeg` objects into the engine if they do not already exist.
    func loadIntoWorld(pegs: [GamePeg], blocks: [GameBlock]) {
        pegs.filter { !gamePegs.contains($0) }
            .forEach { world.insert(body: $0) }
        blocks.filter { !gameBlocks.contains($0) }
            .forEach { world.insert(body: $0) }
    }

    /// Updates the location of all pegs and cannon balls (if the latter is present).
    /// If the cannon has left the boundaries, it performs the removal of hit pegs and the cannon.
    func refresh(elapsed: TimeInterval) {
        world.update(time: elapsed)
        delegate?.updateCannonBallPosition()
        delegate?.highlightPegs()
        handleBallStuck()
        handleCannonExit()
    }

    // ======================= //
    // MARK: Turn End Handlers
    // ======================= //

    /// Checks if the cannon is within the playing area. If it has left, it is removed and all hit pegs are removed.
    func handleCannonExit() {
        guard let currentCannon = cannon else {
            return
        }
        let cannonHasLeftArea = currentCannon.outOfBounds(frame: world.dimensions)
        guard cannonHasLeftArea else {
            return
        }
        removeAllHitPegs()
        removeCannonBall()
    }

    func handleBallStuck() {
        guard let ball = cannon, ball.stuck else {
            return
        }
        removeAllHitPegs()
        removeCannonBall()
    }

    func removeCannonBall() {
        guard let currentCannon = cannon else {
            return
        }
        world.remove(body: currentCannon)
        cannon = nil
        ballLaunched = false
        endGameIfPossible()
    }

    func removeAllHitPegs() {
        let hitPegs = gamePegs.filter { $0.hit }
        hitPegs.forEach { world.remove(body: $0) }
    }

    /// Checks if the conditions for ending the game have been met.
    /// If the game had no pegs to begin with, a no start is declared.
    /// If the player has gotten the required score within the number of cannon shots, he wins.
    /// If the player has used up all shots and failed to score the minimum score, he loses.
    /// Otherwise, the game continues.
    func endGameIfPossible() {
        // TODO: Implement this
        // delegate?.endGame(won)
        if requiredScore <= 0 {
            delegate?.endGame(condition: .noStart)
        }
        if shotsLeft >= 0 && score >= requiredScore {
            delegate?.endGame(condition: .won)
        }
        if shotsLeft < 1 && score < requiredScore {
            delegate?.endGame(condition: .lost)
        }
    }

    // ===================== //
    // MARK: Cannon Handling
    // ===================== //

    func aim(at coordinates: CGPoint) {
        launchAngle = calculateAngleOfFire(coordinates: coordinates)
    }

    /// Fires a cannon ball towards the given `coordinates` if there is no cannon active in the engine.
    func launch() {
        guard !ballLaunched, shotsLeft > 0 else {
            return
        }
        startCannonSimulation()
    }

    private func startCannonSimulation() {
        cannon = CannonBall(angle: launchAngle, coord: launchPoint)
        guard let cannon = cannon else {
            fatalError("Cannon should be initialised by now")
        }
        world.insert(body: cannon)
        ballLaunched = true
        shotsLeft -= 1
    }

    func calculateAngleOfFire(coordinates: CGPoint) -> CGFloat {
        let xDist = coordinates.x - launchPoint.x
        let yDist = coordinates.y - launchPoint.y
        var angle = CGVector(dx: xDist, dy: yDist).angleInRads

        if xDist < 0 {
            angle += CGFloat.pi
        }
        return angle
    }

    // ============= //
    // MARK: Cleanup
    // ============= //

    /// Removes unneeded resources.
    func cleanUp() {
        cannon = nil
        gamePegs.removeAll()
    }

    // ==================================== //
    // MARK: Physics World Delegate Methods
    // ==================================== //

    func updateAddedPegs() {
        let pegsToAdd = world.bodies.compactMap { $0 as? GamePeg }.filter { !gamePegs.contains($0) }
        for peg in pegsToAdd {
            gamePegs.append(peg)
            peg.delegate = self
        }
        shotsLeft += pegsToAdd.count * 1
        requiredScore += pegsToAdd.count * BlueGamePeg.score

        let blocksToAdd = world.bodies.compactMap { $0 as? GameBlock }.filter { !gameBlocks.contains($0) }
        blocksToAdd.forEach { gameBlocks.append($0) }

        delegate?.addMissingObjects(pegs: pegsToAdd, blocks: blocksToAdd)
    }

    func updateRemovedPegs() {
        gamePegs.filter { !world.contains(body: $0) }
            .forEach { remove(peg: $0) }
    }

    private func remove(peg: GamePeg) {
        guard let index = gamePegs.firstIndex(of: peg) else {
            return
        }
        gamePegs.remove(at: index)
        delegate?.removeView(of: peg)
    }

    // =============================== //
    // MARK: Game Peg Delegate Methods
    // =============================== //

    func updateScore(_ score: Int) {
        self.score += score
        delegate?.displayScore()
    }

    func pegsInVicinity(searchRadius: CGFloat, around center: CGPoint) -> [GamePeg] {
        gamePegs.filter { $0.center.distanceTo(point: center) <= searchRadius }
    }

}

enum GameOverState {
    case won, lost, noStart
}
