import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var captureButtonTitle = "Start Recording"
    @State private var statusText = "Status: Idle"
    @State private var resultText = "Result will be displayed here"
    
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioFilename: URL?
    @State private var whisperContext: OpaquePointer? = nil

    var body: some View {
        VStack {
            Text(statusText)
                .font(.headline)
                .padding()
            
            Button(action: toggleRecording) {
                Text(captureButtonTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(isRecording ? Color.red : Color.gray)
                    .cornerRadius(10)
            }
            
            ScrollView {
                Text(resultText)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            setupAudioSession()
            loadModel() 
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
            startTranscription()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ] as [String : Any]
            
            audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
            
            audioRecorder = try AVAudioRecorder(url: audioFilename!, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            statusText = "Status: Recording"
            captureButtonTitle = "Stop Recording"
            
        } catch {
            statusText = "Failed to start recording"
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        statusText = "Status: Idle"
        captureButtonTitle = "Start Recording"
    }
    
    private func startTranscription() {
        guard !isTranscribing else { return }
        
        isTranscribing = true
        resultText = "Processing - please wait ..."
        
        DispatchQueue.global(qos: .background).async {
            self.transcribeAudio()
        }
    }
    
    private func transcribeAudio() {
        guard let audioFilename = audioFilename else { return }
        
        // Load the recorded audio file
        let fileData: Data
        do {
            fileData = try Data(contentsOf: audioFilename)
        } catch {
            DispatchQueue.main.async {
                self.resultText = "Failed to load audio file"
                self.isTranscribing = false
            }
            return
        }
        
        // Process the audio file data
        fileData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let audioBuffer = buffer.bindMemory(to: Int16.self)
            let nSamples = audioBuffer.count / MemoryLayout<Int16>.stride
            
            // Convert I16 to F32
            var audioBufferF32 = audioBuffer.map { Float($0) / 32768.0 }
            
            // Run the Whisper model
            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            let maxThreads = min(8, ProcessInfo.processInfo.processorCount)
            params.print_realtime = true
            params.print_progress = false
            params.print_timestamps = true
            params.print_special = false
            params.translate = false
            params.n_threads = Int32(maxThreads)
            params.offset_ms = 0
            params.no_context = true
            params.single_segment = true
            params.no_timestamps = true
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            whisper_reset_timings(whisperContext)
            
            let language = "en"
            language.withCString { languageCString in
                params.language = languageCString
                if whisper_full(whisperContext, params, &audioBufferF32, Int32(nSamples)) != 0 {
                    DispatchQueue.main.async {
                        self.resultText = "Failed to run the model"
                        self.isTranscribing = false
                    }
                    return
                }
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            
            var result = ""
            let nSegments = whisper_full_n_segments(whisperContext)
            for i in 0..<nSegments {
                if let textCur = whisper_full_get_segment_text(whisperContext, i) {
                    result += String(cString: textCur)
                }
            }
            
            let tRecording = Float(nSamples) / 16000.0  // Assuming a sample rate of 16000 Hz
            
            result += String(format: "\n\n[recording time:  %5.3f s]", tRecording)
            result += String(format: "  \n[processing time: %5.3f s]", endTime - startTime)
            
            DispatchQueue.main.async {
                self.resultText = result
                self.isTranscribing = false
            }
        }
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            statusText = "Error: Could not set up audio session"
        }
    }
    
    private func loadModel() {
        if let modelPath = Bundle.main.path(forResource: "ggml-tarteel-tinyq5_0", ofType: "bin") {
            modelPath.withCString { modelPathCString in
                whisperContext = whisper_init_from_file(modelPathCString)
            }

            if whisperContext == nil {
                statusText = "Failed to load model"
            }
        } else {
            statusText = "Model file not found"
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

