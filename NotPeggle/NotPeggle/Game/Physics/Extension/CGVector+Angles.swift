//
//  CGVector+Angles.swift
//  NotPeggle
//
//  Created by Ying Gao on 10/2/21.
//

import UIKit

/**
 Additional functionality for vector mathematics.
 */
extension CGVector {

    /// Angle of the given vector.
    /// Note that the angle is calculated by arctan() and has limited range [pi/2, -pi/2].
    /// In other words, two parallel vectors in opposite directions will share the same angle.
    var angleInRads: CGFloat {
        guard magnitude != 0 else {
            return 0
        }
        return atan(dy / dx)
    }

    var magnitudeSquared: CGFloat {
        dx * dx + dy * dy
    }

    var magnitude: CGFloat {
        sqrt(magnitudeSquared)
    }

    /// Rotates the vector **anticlockwise** by the given `angle`.
    mutating func rotate(by angle: CGFloat) {
        let newDx = dx * cos(angle) - dy * sin(angle)
        let newDy = dx * sin(angle) + dy * cos(angle)
        dx = newDx
        dy = newDy
    }

    /// Returns the dot product between the two vectors
    func dot(other: CGVector) -> CGFloat {
        dx * other.dx + dy * other.dy
    }

    func isPerpendicularTo(other: CGVector) -> Bool {
         dot(other: other) == 0
    }

    /// Multiplies the magnitude of the vector by the given `factor`.
    mutating func scale(factor: CGFloat) {
        dx *= factor
        dy *= factor
    }

}
