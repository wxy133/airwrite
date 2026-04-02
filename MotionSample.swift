import Foundation

public struct Vector3: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public var magnitude: Double {
        sqrt((x * x) + (y * y) + (z * z))
    }
}

public struct Quaternion: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

public struct MotionSample: Codable, Hashable, Sendable {
    public var timestamp: TimeInterval
    public var userAcceleration: Vector3
    public var rotationRate: Vector3
    public var gravity: Vector3
    public var attitude: Quaternion

    public init(
        timestamp: TimeInterval,
        userAcceleration: Vector3,
        rotationRate: Vector3,
        gravity: Vector3,
        attitude: Quaternion
    ) {
        self.timestamp = timestamp
        self.userAcceleration = userAcceleration
        self.rotationRate = rotationRate
        self.gravity = gravity
        self.attitude = attitude
    }

    public var motionEnergy: Double {
        userAcceleration.magnitude + (rotationRate.magnitude * 0.2)
    }
}
