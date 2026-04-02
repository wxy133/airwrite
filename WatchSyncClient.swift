#if canImport(WatchConnectivity)
import Foundation
import WatchConnectivity

public final class WatchSyncClient: NSObject, WCSessionDelegate {
    public static let shared = WatchSyncClient()

    private let encoder = JSONEncoder()
    private var isActivated = false

    public func activate() {
        guard WCSession.isSupported(), !isActivated else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        isActivated = true
    }

    public func requestRecognition(for transfer: StrokeTransfer, reply: @escaping (String?) -> Void) {
        guard WCSession.isSupported() else {
            reply(nil)
            return
        }

        let session = WCSession.default
        guard session.isReachable else {
            reply(nil)
            return
        }

        do {
            let payload = try encoder.encode(transfer)
            session.sendMessage(
                ["strokeData": payload],
                replyHandler: { response in
                    reply(response["text"] as? String)
                },
                errorHandler: { _ in
                    reply(nil)
                }
            )
        } catch {
            reply(nil)
        }
    }

    public func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
    }
}
#endif
