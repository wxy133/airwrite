import Foundation

public struct RecognitionCandidate: Codable, Hashable, Sendable {
    public var symbol: String
    public var score: Double

    public init(symbol: String, score: Double) {
        self.symbol = symbol
        self.score = score
    }
}

public struct GlyphTemplate: Hashable, Sendable {
    public var symbol: String
    public var points: [Point2D]

    public init(symbol: String, points: [Point2D]) {
        self.symbol = symbol
        self.points = StrokeNormalizer.resampleAndNormalize(points, count: 32)
    }
}

public struct TemplateRecognizer: Sendable {
    public var templates: [GlyphTemplate]

    public init(templates: [GlyphTemplate]) {
        self.templates = templates
    }

    public func recognize(points: [Point2D], topK: Int = 3) -> [RecognitionCandidate] {
        let normalized = StrokeNormalizer.resampleAndNormalize(points, count: 32)
        guard !normalized.isEmpty else { return [] }

        return templates
            .map { template in
                let distance = averagePointDistance(normalized, template.points)
                let confidence = max(0, 1.0 - (distance * 1.8))
                return RecognitionCandidate(symbol: template.symbol, score: confidence)
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.symbol < rhs.symbol
                }
                return lhs.score > rhs.score
            }
            .prefix(topK)
            .map { $0 }
    }

    private func averagePointDistance(_ lhs: [Point2D], _ rhs: [Point2D]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return .infinity }

        let sum = zip(lhs, rhs).reduce(0.0) { partial, pair in
            partial + pair.0.distance(to: pair.1)
        }

        return sum / Double(lhs.count)
    }
}

public extension TemplateRecognizer {
    static let demoDigits = TemplateRecognizer(
        templates: [
            GlyphTemplate(
                symbol: "0",
                points: [
                    Point2D(x: 0.50, y: 0.05),
                    Point2D(x: 0.80, y: 0.18),
                    Point2D(x: 0.92, y: 0.50),
                    Point2D(x: 0.80, y: 0.82),
                    Point2D(x: 0.50, y: 0.95),
                    Point2D(x: 0.20, y: 0.82),
                    Point2D(x: 0.08, y: 0.50),
                    Point2D(x: 0.20, y: 0.18),
                    Point2D(x: 0.50, y: 0.05)
                ]
            ),
            GlyphTemplate(
                symbol: "1",
                points: [
                    Point2D(x: 0.35, y: 0.25),
                    Point2D(x: 0.50, y: 0.10),
                    Point2D(x: 0.50, y: 0.90)
                ]
            ),
            GlyphTemplate(
                symbol: "2",
                points: [
                    Point2D(x: 0.18, y: 0.22),
                    Point2D(x: 0.42, y: 0.06),
                    Point2D(x: 0.78, y: 0.18),
                    Point2D(x: 0.78, y: 0.40),
                    Point2D(x: 0.28, y: 0.72),
                    Point2D(x: 0.16, y: 0.92),
                    Point2D(x: 0.84, y: 0.92)
                ]
            ),
            GlyphTemplate(
                symbol: "3",
                points: [
                    Point2D(x: 0.20, y: 0.12),
                    Point2D(x: 0.78, y: 0.12),
                    Point2D(x: 0.50, y: 0.50),
                    Point2D(x: 0.80, y: 0.50),
                    Point2D(x: 0.56, y: 0.88),
                    Point2D(x: 0.20, y: 0.84)
                ]
            ),
            GlyphTemplate(
                symbol: "L",
                points: [
                    Point2D(x: 0.30, y: 0.08),
                    Point2D(x: 0.30, y: 0.92),
                    Point2D(x: 0.78, y: 0.92)
                ]
            ),
            GlyphTemplate(
                symbol: "C",
                points: [
                    Point2D(x: 0.82, y: 0.18),
                    Point2D(x: 0.56, y: 0.06),
                    Point2D(x: 0.22, y: 0.22),
                    Point2D(x: 0.12, y: 0.50),
                    Point2D(x: 0.22, y: 0.78),
                    Point2D(x: 0.56, y: 0.94),
                    Point2D(x: 0.82, y: 0.82)
                ]
            )
        ]
    )
}
