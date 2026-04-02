import Foundation

public struct StrokeProjectorConfiguration: Sendable {
    public var accelerationGain: Double
    public var angularGain: Double
    public var damping: Double
    public var motionThreshold: Double
    public var minimumPointDistance: Double

    public init(
        accelerationGain: Double = 2.4,
        angularGain: Double = 0.08,
        damping: Double = 0.88,
        motionThreshold: Double = 0.10,
        minimumPointDistance: Double = 0.003
    ) {
        self.accelerationGain = accelerationGain
        self.angularGain = angularGain
        self.damping = damping
        self.motionThreshold = motionThreshold
        self.minimumPointDistance = minimumPointDistance
    }
}

public struct StrokeProjector: Sendable {
    public var configuration: StrokeProjectorConfiguration

    public init(configuration: StrokeProjectorConfiguration = .init()) {
        self.configuration = configuration
    }

    public func project(samples: [MotionSample]) -> [Point2D] {
        guard samples.count > 1 else { return samples.isEmpty ? [] : [.zero] }

        var points: [Point2D] = [.zero]
        var velocityX = 0.0
        var velocityY = 0.0
        var positionX = 0.0
        var positionY = 0.0

        for index in 1..<samples.count {
            let previous = samples[index - 1]
            let current = samples[index]
            let dt = clamp(current.timestamp - previous.timestamp, min: 1.0 / 120.0, max: 0.1)

            let inputX = (current.userAcceleration.x * configuration.accelerationGain) +
                (current.rotationRate.y * configuration.angularGain)
            let inputY = (-current.userAcceleration.y * configuration.accelerationGain) +
                (current.rotationRate.x * configuration.angularGain)
            let magnitude = sqrt((inputX * inputX) + (inputY * inputY))

            if magnitude < configuration.motionThreshold {
                velocityX *= configuration.damping
                velocityY *= configuration.damping
            } else {
                velocityX = ((velocityX + (inputX * dt)) * configuration.damping)
                velocityY = ((velocityY + (inputY * dt)) * configuration.damping)
            }

            positionX += velocityX * dt
            positionY += velocityY * dt

            let nextPoint = Point2D(x: positionX, y: positionY)
            if let last = points.last, last.distance(to: nextPoint) >= configuration.minimumPointDistance {
                points.append(nextPoint)
            }
        }

        return points
    }

    private func clamp(_ value: Double, min lower: Double, max upper: Double) -> Double {
        Swift.max(lower, Swift.min(value, upper))
    }
}
