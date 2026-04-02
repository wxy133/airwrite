#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

public final class CompanionSessionManager: NSObject, WCSessionDelegate {
    public static let shared = CompanionSessionManager()

    private let recognizer = TemplateRecognizer.demoDigits
    private let decoder = JSONDecoder()

    public func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {
    }

    public func sessionDidDeactivate(_ session: WCSession) {
    }

    public func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let payload = message["strokeData"] as? Data,
              let transfer = try? decoder.decode(StrokeTransfer.self, from: payload) else {
            replyHandler(["text": "?"])
            return
        }

        let candidate = recognizer.recognize(points: transfer.normalizedPoints, topK: 1).first
        replyHandler(["text": candidate?.symbol ?? "?"])
    }
}
#endif
