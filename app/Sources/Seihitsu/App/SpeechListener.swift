import Foundation
import Speech
import AVFoundation

/// On-device speech-to-text via Apple's Speech framework (no network, no external deps).
/// Streams partial transcripts while listening, then delivers a final transcript on stop.
/// Callbacks are delivered on the main queue.
final class SpeechListener {
    var onPartial: ((String) -> Void)?
    var onFinal: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var isListening = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var lastText = ""

    /// Requests both Speech Recognition and Microphone access.
    func requestAuthorization(_ done: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            let speechOK = (speechStatus == .authorized)
            AVCaptureDevice.requestAccess(for: .audio) { micOK in
                DispatchQueue.main.async { done(speechOK && micOK) }
            }
        }
    }

    func start() {
        guard !isListening else { return }
        guard let recognizer else { deliverError("No speech recognizer for en-US"); return }
        guard recognizer.isAvailable else { deliverError("Speech recognizer not available right now"); return }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        // Deliberately NOT forcing requiresOnDeviceRecognition: forcing it errors out instantly
        // when the on-device model isn't ready. Modern macOS still uses on-device when available.
        request = req

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)   // hardware input format
        guard format.sampleRate > 0, format.channelCount > 0 else {
            deliverError("No microphone input (check the input device and Microphone permission)")
            return
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            deliverError("Microphone error: \(error.localizedDescription)")
            return
        }
        isListening = true
        lastText = ""
        Log.log("listen: started (sr=\(Int(format.sampleRate)) ch=\(format.channelCount))")

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                self.lastText = text
                DispatchQueue.main.async { self.onPartial?(text) }
                if result.isFinal { self.teardown(deliverFinal: text) }
            }
            if let error {
                Log.log("listen: recognition error \(error.localizedDescription)")
                self.teardown(deliverFinal: self.lastText)
            }
        }
    }

    /// Stops immediately and delivers the best transcript so far. Does not wait on the
    /// recognizer (which may never send a "final"), so it always actually stops.
    func stop() {
        teardown(deliverFinal: lastText)
    }

    private func teardown(deliverFinal text: String?) {
        DispatchQueue.main.async {
            guard self.isListening else { return }   // idempotent: runs once per session
            self.isListening = false
            if self.engine.isRunning {
                self.engine.stop()
                self.engine.inputNode.removeTap(onBus: 0)
            }
            self.request?.endAudio()
            self.task?.cancel()
            self.task = nil
            self.request = nil
            Log.log("listen: stopped (final=\(text?.count ?? 0) chars)")
            self.onFinal?(text ?? "")
        }
    }

    private func deliverError(_ message: String) {
        isListening = false
        Log.log("listen: error \(message)")
        DispatchQueue.main.async { self.onError?(message) }
    }
}
