import SwiftUI

struct ContentView: View {
    @StateObject private var model = AirWriteSessionModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("AirWrite")
                    .font(.headline)

                Text(model.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TracePreview(points: model.liveTrace)
                    .frame(height: 120)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(model.localPrediction)
                            .font(.title3.monospaced())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("iPhone")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(model.remotePrediction)
                            .font(.title3.monospaced())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Result")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(model.committedText.isEmpty ? "-" : model.committedText)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(model.isCapturing ? "Stop" : "Start") {
                    model.toggleCapture()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    model.clearText()
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
}

private struct TracePreview: View {
    let points: [Point2D]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.12))

                if points.count > 1 {
                    Path { path in
                        let converted = points.map { point in
                            CGPoint(
                                x: point.x * geometry.size.width,
                                y: point.y * geometry.size.height
                            )
                        }

                        path.move(to: converted[0])
                        for point in converted.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                } else {
                    Text("Move your wrist to write")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
