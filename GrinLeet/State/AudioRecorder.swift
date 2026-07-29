import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioRecorder {
    enum Status: Equatable {
        case idle
        case denied
        case recording
    }

    var status: Status = .idle
    var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timerTask: Task<Void, Never>?
    private var currentURL: URL?

    var isRecording: Bool { status == .recording }

    func requestPermission() async -> Bool {
        // macOS: AVCaptureDevice handles mic authorization.
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            status = .denied
            return false
        @unknown default:
            return false
        }
    }

    /// Starts recording to a fresh temp file. Returns the destination URL.
    @discardableResult
    func start() throws -> URL {
        stop()  // safety

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("grinleet-\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw NSError(
                domain: "GrinLeet.AudioRecorder",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder.record() returned false"]
            )
        }

        self.recorder = recorder
        self.currentURL = url
        self.status = .recording
        self.elapsed = 0
        startTimer()
        return url
    }

    /// Stops recording and returns the file URL if a recording was in progress.
    @discardableResult
    func stop() -> URL? {
        timerTask?.cancel()
        timerTask = nil
        recorder?.stop()
        recorder = nil
        let url = currentURL
        currentURL = nil
        status = .idle
        elapsed = 0
        return url
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            let started = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.isRecording else { return }
                self.elapsed = Date().timeIntervalSince(started)
            }
        }
    }
}
