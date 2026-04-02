import Foundation

public enum StrokeNormalizer {
    public static func resampleAndNormalize(_ points: [Point2D], count: Int = 32) -> [Point2D] {
        guard !points.isEmpty else { return [] }
        let compacted = removeNearDuplicates(points, epsilon: 0.0001)
        let resampled = resample(compacted, count: max(2, count))
        return normalizeToUnitSquare(resampled)
    }

    public static func normalizeToUnitSquare(_ points: [Point2D]) -> [Point2D] {
        guard !points.isEmpty else { return [] }

        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let maxY = points.map(\.y).max() ?? 0

        let width = maxX - minX
        let height = maxY - minY
        let scale = Swift.max(Swift.max(width, height), 0.0001)
        let normalizedWidth = width / scale
        let normalizedHeight = height / scale
        let offsetX = (1.0 - normalizedWidth) / 2.0
        let offsetY = (1.0 - normalizedHeight) / 2.0

        return points.map {
            Point2D(
                x: (($0.x - minX) / scale) + offsetX,
                y: (($0.y - minY) / scale) + offsetY
            )
        }
    }

    private static func removeNearDuplicates(_ points: [Point2D], epsilon: Double) -> [Point2D] {
        guard let first = points.first else { return [] }
        var result = [first]

        for point in points.dropFirst() where result.last?.distance(to: point) ?? .infinity > epsilon {
            result.append(point)
        }

        return result
    }

    private static func resample(_ points: [Point2D], count: Int) -> [Point2D] {
        guard points.count > 1 else { return Array(repeating: points.first ?? .zero, count: count) }

        let totalLength = pathLength(points)
        guard totalLength > 0 else { return Array(repeating: points[0], count: count) }

        let step = totalLength / Double(count - 1)
        var result: [Point2D] = [points[0]]
        var accumulated = 0.0
        var remainingStep = step
        var previous = points[0]

        for current in points.dropFirst() {
            var segmentLength = previous.distance(to: current)
            if segmentLength == 0 {
                previous = current
                continue
            }

            var start = previous
            while accumulated + segmentLength >= remainingStep && result.count < count - 1 {
                let ratio = (remainingStep - accumulated) / segmentLength
                let interpolated = Point2D(
                    x: start.x + ((current.x - start.x) * ratio),
                    y: start.y + ((current.y - start.y) * ratio)
                )
                result.append(interpolated)

                start = interpolated
                segmentLength = start.distance(to: current)
                accumulated = 0
                remainingStep = step
            }

            accumulated += segmentLength
            previous = current
        }

        while result.count < count {
            result.append(points.last ?? .zero)
        }

        return result
    }

    private static func pathLength(_ points: [Point2D]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { partial, pair in
            partial + pair.0.distance(to: pair.1)
        }
    }
}
