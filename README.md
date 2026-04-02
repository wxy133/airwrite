# AirWrite Watch Prototype

This is a starter prototype for an Apple Watch air-writing app.
It uses Apple Watch IMU data to approximate short handwritten input such as digits or simple symbols.

## What It Is

This is not camera-based OCR.
Apple Watch does not expose a public spatial camera API for reading handwriting in free space.
The prototype is based on `Core Motion` data:

- `userAcceleration`
- `rotationRate`
- `gravity`
- `attitude`

That makes this an IMU-based air-writing system.

## Data Flow

1. The watch samples `CMDeviceMotion` at a fixed rate.
2. Motion-energy thresholds segment a single stroke.
3. The stroke is projected into a 2D trace.
4. The trace is normalized to a fixed point count.
5. A lightweight local template recognizer runs on watch.
6. The normalized trace is sent to iPhone with `WatchConnectivity` for a second recognition pass.

## Project Layout

- `Shared/`
  Shared models, projection, normalization, and recognition logic.
- `WatchApp/`
  watchOS session model, SwiftUI UI, and watch-to-phone bridge.
- `iPhoneCompanion/`
  iPhone-side `WCSession` receiver and reply logic.

## Current Scope

- Capture Apple Watch motion samples
- Segment one stroke automatically
- Render a live trace on watch
- Run a basic template recognizer for demo symbols
- Send normalized strokes to iPhone for a second pass

## Current Limits

- This is a proof of concept, not a production recognizer.
- It is best suited to digits, short symbols, and simple gestures.
- Pure IMU integration drifts.
- Continuous words, Chinese characters, and arbitrary orientations will need a trained model.
- Long high-frequency capture usually needs a workout or runtime strategy.

## Productization Path

1. Start with digits and a small command alphabet.
2. Collect your own labeled dataset.
3. Feed time-series features into the model, not just projected points.
4. Try 1D CNN, BiLSTM, or Transformer encoder models.
5. Keep watch as the sensor node and iPhone as the inference node first.
6. Move to on-watch Core ML only after accuracy is stable.

## Xcode Integration

1. Create a new `watchOS App` with `iOS companion` on macOS.
2. Add `Shared` files to both targets.
3. Add `WatchApp` files to the watch target.
4. Add `iPhoneCompanion` files to the iPhone target.
5. Add `NSMotionUsageDescription` to `Info.plist`.
6. Enable `WatchConnectivity`.
7. If you need longer capture sessions, evaluate `HealthKit` workout sessions or other runtime options.

Example `Info.plist` entry:

```xml
<key>NSMotionUsageDescription</key>
<string>Used to capture wrist motion for air-writing recognition.</string>
```

## Constraints Confirmed From Apple Docs

- Apple documents watchOS support for high-frequency accelerometer and device motion batches in workout scenarios.
- `CMMotionManager` exposes `startDeviceMotionUpdates(...)`.
- `WatchConnectivity` `sendMessage(_:replyHandler:errorHandler:)` is appropriate for foreground reachable communication.
- Apple also documents multidevice workout communication, which matches a watch + iPhone architecture.

## References

- Apple Developer, watchOS updates:
  https://developer.apple.com/documentation/updates/watchos
- Apple Developer, CMMotionManager:
  https://developer.apple.com/documentation/coremotion/cmmotionmanager
- Apple Developer, startDeviceMotionUpdates(using:to:withHandler:):
  https://developer.apple.com/documentation/coremotion/cmmotionmanager/startdevicemotionupdates%28using%3Ato%3Awithhandler%3A%29
- Apple Developer, CMBatchedSensorManager:
  https://developer.apple.com/documentation/coremotion/cmbatchedsensormanager
- Apple Developer, WCSession.sendMessage(_:replyHandler:errorHandler:):
  https://developer.apple.com/documentation/watchconnectivity/wcsession/sendmessage%28_%3Areplyhandler%3Aerrorhandler%3A%29
- Apple Developer, Building a multidevice workout app:
  https://developer.apple.com/documentation/HealthKit/building-a-multidevice-workout-app
- Apple Developer, Creating independent watchOS apps:
  https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps
