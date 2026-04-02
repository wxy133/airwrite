import CoreMotion
import Foundation
import SwiftUI

@MainActor
final class AirWriteSessionModel: ObservableObject {
    @Published var isCapturing = false
    @Published var statusText = "Ready"
    @Published var liveTrace: [Point2D] = []
    @Published var localPrediction = "-"
    @Published var remotePrediction = "-"
    @Published var committedText = ""

    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    private let projector = StrokeProjector()
    private let recognizer = TemplateRecognizer.demoDigits

    private var buffer: [MotionSample] = []
    private var lastActiveTimestamp: TimeInterval?
    private let activityThreshold = 0.18
    private let strokeEndDelay = 0.35

    init() {
        motionQueue.name = "AirWrite.MotionQueue"
        motionQueue.maxConcurrentOperationCount = 1
        WatchSyncClient.shared.activate()
    }

    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }

    func clearText() {
        committedText = ""
        liveTrace = []
        localPrediction = "-"
        remotePrediction = "-"
        statusText = "Cleared"
    }

    private func startCapture() {
        guard motionManager.isDeviceMotionAvailable else {
            statusText = "Device motion unavailable"
            return
        }

        buffer.removeAll()
        liveTrace.removeAll()
        localPrediction = "-"
        remotePrediction = "-"
        lastActiveTimestamp = nil
        statusText = "Capturing"
        isCapturing = true

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: motionQueue
        ) { [weak self] motion, error in
            self?.consumeMotion(motion, error: error)
        }
    }

    private func stopCapture() {
        motionManager.stopDeviceMotionUpdates()
        isCapturing = false
        statusText = "Stopped"
        flushBufferIfNeeded(force: true)
    }

    private func consumeMotion(_ motion: CMDeviceMotion?, error: Error?) {
        if let error {
            Task { @MainActor in
                self.statusText = error.localizedDescription
                self.isCapturing = false
            }
            return
        }

        guard let motion else { return }

        let quaternion = motion.attitude.quaternion
        let sample = MotionSample(
            timestamp: Date().timeIntervalSince1970,
            userAcceleration: Vector3(
                x: motion.userAcceleration.x,
                y: motion.userAcceleration.y,
                z: motion.userAcceleration.z
            ),
            rotationRate: Vector3(
                x: motion.rotationRate.x,
                y: motion.rotationRate.y,
                z: motion.rotationRate.z
            ),
            gravity: Vector3(
                x: motion.gravity.x,
                y: motion.gravity.y,
                z: motion.gravity.z
            ),
            attitude: Quaternion(
                x: quaternion.x,
                y: quaternion.y,
                z: quaternion.z,
                w: quaternion.w
            )
        )

        if sample.motionEnergy >= activityThreshold {
            buffer.append(sample)
            lastActiveTimestamp = sample.timestamp
            let preview = projector.project(samples: buffer)
            Task { @MainActor in
                self.liveTrace = StrokeNormalizer.resampleAndNormalize(preview, count: 48)
                self.statusText = "Writing..."
            }
            return
        }

        if let lastActiveTimestamp,
           sample.timestamp - lastActiveTimestamp >= strokeEndDelay {
            flushBufferIfNeeded(force: false)
        }
    }

    private func flushBufferIfNeeded(force: Bool) {
        guard buffer.count >= 8 || (force && !buffer.isEmpty) else {
            buffer.removeAll()
            lastActiveTimestamp = nil
            return
        }

        let samples = buffer
        buffer.removeAll()
        lastActiveTimestamp = nil

        let projected = projector.project(samples: samples)
        let normalized = StrokeNormalizer.resampleAndNormalize(projected, count: 32)
        let stroke = AirStroke(
            startedAt: samples.first?.timestamp ?? 0,
            endedAt: samples.last?.timestamp ?? 0,
            samples: samples,
            projectedPoints: projected
        )

        let local = recognizer.recognize(points: normalized, topK: 1).first

        Task { @MainActor in
            self.liveTrace = normalized
            self.localPrediction = local?.symbol ?? "?"
            self.committedText += local?.symbol ?? "?"
            self.statusText = "Stroke \(Int(stroke.duration * 1000))ms"
        }

        WatchSyncClient.shared.requestRecognition(
            for: StrokeTransfer(id: stroke.id, normalizedPoints: normalized)
        ) { [weak self] remoteText in
            guard let self else { return }
            Task { @MainActor in
                self.remotePrediction = remoteText ?? "-"
            }
        }
    }
}
