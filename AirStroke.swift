import Foundation

public struct Point2D: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Point2D(x: 0, y: 0)

    public func distance(to other: Point2D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt((dx * dx) + (dy * dy))
    }
}

public struct AirStroke: Codable, Hashable, Sendable {
    public var id: UUID
    public var startedAt: TimeInterval
    public var endedAt: TimeInterval
    public var samples: [MotionSample]
    public var projectedPoints: [Point2D]

    public init(
        id: UUID = UUID(),
        startedAt: TimeInterval,
        endedAt: TimeInterval,
        samples: [MotionSample],
        projectedPoints: [Point2D]
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.samples = samples
        self.projectedPoints = projectedPoints
    }

    public var duration: TimeInterval {
        endedAt - startedAt
    }
}

public struct StrokeTransfer: Codable, Hashable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var normalizedPoints: [Point2D]

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        normalizedPoints: [Point2D]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.normalizedPoints = normalizedPoints
    }
}
