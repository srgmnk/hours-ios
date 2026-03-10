import CoreMotion
import Combine
import SwiftUI

@MainActor
final class ParallaxMotionManager: ObservableObject {
    @Published private(set) var normalizedOffset: CGSize = .zero

    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "settings.parallax.motion.queue"
        queue.qualityOfService = .userInteractive
        return queue
    }()

    private let maxTiltRadians: Double = 0.45
    private let smoothingFactor: CGFloat = 0.16
    private var isRunning = false

    func start() {
        guard !isRunning else { return }
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 45.0
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let clampedRoll = self.clamp(motion.attitude.roll / self.maxTiltRadians)
            let clampedPitch = self.clamp(motion.attitude.pitch / self.maxTiltRadians)
            let target = CGSize(width: clampedRoll, height: -clampedPitch)

            Task { @MainActor in
                self.applySmoothedOffset(toward: target)
            }
        }

        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false

        withAnimation(.easeOut(duration: 0.2)) {
            normalizedOffset = .zero
        }
    }

    private func applySmoothedOffset(toward target: CGSize) {
        let nextX = normalizedOffset.width + (target.width - normalizedOffset.width) * smoothingFactor
        let nextY = normalizedOffset.height + (target.height - normalizedOffset.height) * smoothingFactor
        normalizedOffset = CGSize(width: nextX, height: nextY)
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(max(-1, min(1, value)))
    }
}
