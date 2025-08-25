import Foundation
import SwiftUI
import Speech
import AVFoundation
import AudioToolbox

protocol SebhaViewModelDelegate: AnyObject {
    func didReachTarget()
}
extension String {
    func removingInvisibleCharacters() -> String {
        return self.filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }
}
class SebhaViewModel: ObservableObject {
    weak var delegate: SebhaViewModelDelegate?
    
    @Published var selectedSebha = ""
    @Published var allSebhas: [String] = []
    @Published var currentTarget = 0
    @Published var currentIndex = 0
    @Published var allSebhasTarget: [Int] = []
    @Published var allSebhasCounter: [Int] = []
    @Published var favoriteSebhas: [String] = []
    @Published var countHistory: [(date: Date, count: Int)] = []
    
    @Published var showEditTargetAlert = false
    @Published var editTargetSebhaIndex: Int? = nil
    @Published var newTarget = ""
    @Published var isRecordingForNewSebha = false
    @Published var Stopped = false
    @Published var before = 0
    @Published var counter = 0
    @Published var isVoice = false {
        didSet {
            if isVoice {
                startSpeechRecognition()
            } else {
                stopSpeechRecognition()
            }
        }
    }
    @Published var target = 0
    @Published var prevCount = 0
    @Published var targetInput = ""
    @Published var showAlert = false
    @Published var showAddSebhaAlert = false
    
    @Published var newSebha = ""
    @Published var newSebhaRecorded = ""
    @Published var newSebhaTarget = ""
    @Published var recognizedText = ""
    @Published var currentSebhaProgress: Double = 0.0
    
    // Voice recordings for each sebha
    @Published var sebhaRecordings: [String: URL] = [:]
    @Published var isRecordingVoicePrompt = false
    @Published var recordingForSebhaIndex: Int? = nil
    
    // Sound player for completion sound and voice prompts
    private var audioPlayer: AVAudioPlayer?
    private var voiceRecorder: AVAudioRecorder?
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-SA"))!
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    init() {
        loadSebhas()
        if allSebhas.isEmpty {
            allSebhas = ["سبحان الله", "الحمد لله", "لا اله الا الله"]
            allSebhasTarget = [10, 20, 30]
            allSebhasCounter = [0, 0, 0]
            favoriteSebhas = []
            selectedSebha = allSebhas[0]
            currentTarget = allSebhasTarget[0]
            saveSebhas()
        }
        selectedSebha = allSebhas[0]
        currentTarget = allSebhasTarget[0]
        currentIndex = 0
        updateProgress()
        print("Initialization done")
        setupAudioSession()
        loadVoiceRecordings()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func startSpeechRecognitionForNewSebha() {
        stopSpeechRecognition() // Ensure any existing recognition is stopped
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = spokenText
                    print("Recognized text: \(spokenText)")
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognitionForNewSebha()
                print("Error or final result: \(String(describing: error))")
            }
        }
        
        // Use the input node's actual format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
            print("Audio buffer appended")
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecordingForNewSebha = true
            print("Audio engine started")
        } catch {
            print("Audio engine couldn't start because of an error: \(error.localizedDescription)")
        }
    }
    func stopSpeechRecognitionForNewSebha() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
            isRecordingForNewSebha = false
            print("Audio engine stopped")
        }
    }
    
    
    // Example function to calculate weekly stats
    func calculateWeeklyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let weeklyCounts = countHistory.filter { $0.date >= oneWeekAgo }
        return weeklyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Example function to calculate monthly stats
    func calculateMonthlyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
        
        let monthlyCounts = countHistory.filter { $0.date >= oneMonthAgo }
        return monthlyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Example function to calculate daily stats
    func calculateDailyStats() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        let dailyCounts = countHistory.filter { calendar.isDate($0.date, inSameDayAs: today) }
        return dailyCounts.map { $0.count }.reduce(0, +)
    }
    
    // Ensure to update the countHistory whenever a count is incremented
    func incrementCount(for sebha: String) {
        counter += 1
        allSebhasCounter[currentIndex] += 1
        countHistory.append((date: Date(), count: 1))
        
        if counter >= currentTarget && currentTarget > 0 {
            triggerVibration()
            playCompletionSound()
            delegate?.didReachTarget()
            
            // Auto switch to next sebha after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.switchToNextSebha()
            }
        }
        saveSebhas()
    }
    
    private func updateProgress() {
        currentSebhaProgress = currentTarget > 0 ? Double(counter) / Double(currentTarget) : 0.0
    }
    
    func addFavoriteSebha(at index: Int) {
        let sebha = allSebhas[index]
        if favoriteSebhas.contains(sebha) {
            favoriteSebhas.removeAll { $0 == sebha }
        } else {
            favoriteSebhas.append(sebha)
        }
        saveSebhas()
    }
    
    func editSebhaTarget(at index: Int) {
        editTargetSebhaIndex = index
        newTarget = String(allSebhasTarget[index])
        showEditTargetAlert = true
    }
    
    func updateSebhaTarget() {
        guard let index = editTargetSebhaIndex, let targetValue = Int(newTarget) else {
            return
        }
        allSebhasTarget[index] = targetValue
        if selectedSebha == allSebhas[index] {
            currentTarget = targetValue
        }
        editTargetSebhaIndex = nil
        newTarget = ""
        saveSebhas()
    }
    
    func triggerVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func addCustomSebha() {
        guard !newSebha.isEmpty, !newSebhaTarget.isEmpty, let targetValue = Int(newSebhaTarget) else {
            print("Invalid new Sebha or target")
            return
        }
        
        allSebhas.append(newSebha)
        allSebhasTarget.append(targetValue)
        allSebhasCounter.append(0)
        
        newSebha = ""
        newSebhaTarget = ""
        
        currentIndex = allSebhas.count - 1
        selectedSebha = allSebhas.last!
        currentTarget = targetValue
        counter = 0
        updateProgress()
        
        print("New Sebha added:")
        saveSebhas()
    }
    
    func saveSebhas() {
        UserDefaults.standard.set(allSebhas, forKey: "allSebhas")
        UserDefaults.standard.set(allSebhasTarget, forKey: "allSebhasTarget")
        UserDefaults.standard.set(allSebhasCounter, forKey: "allSebhasCounter")
        UserDefaults.standard.set(favoriteSebhas, forKey: "favoriteSebhas")
        print("Data saved:")
        print("allSebhas: \(allSebhas)")
        print("allSebhasTarget: \(allSebhasTarget)")
        print("allSebhasCounter: \(allSebhasCounter)")
        print("favoriteSebhas: \(favoriteSebhas)")
    }
    
    func loadSebhas() {
        if let savedSebhas = UserDefaults.standard.stringArray(forKey: "allSebhas") {
            allSebhas = savedSebhas
        } else {
            allSebhas = ["سبحان الله", "الحمد لله", "لا اله الا الله"]
        }
        
        if let savedSebhasTarget = UserDefaults.standard.array(forKey: "allSebhasTarget") as? [Int] {
            allSebhasTarget = savedSebhasTarget
        } else {
            allSebhasTarget = [10, 20, 30]
        }
        
        if let savedSebhasCounter = UserDefaults.standard.array(forKey: "allSebhasCounter") as? [Int] {
            allSebhasCounter = savedSebhasCounter
        } else {
            allSebhasCounter = [0, 0, 0]
        }
        
        if let savedFavoriteSebhas = UserDefaults.standard.stringArray(forKey: "favoriteSebhas") {
            favoriteSebhas = savedFavoriteSebhas
        } else {
            favoriteSebhas = []
        }
        
        print("Data loaded:")
        print("allSebhas: \(allSebhas)")
        print("allSebhasTarget: \(allSebhasTarget)")
        print("allSebhasCounter: \(allSebhasCounter)")
        print("favoriteSebhas: \(favoriteSebhas)")
        
        if allSebhas.count != allSebhasTarget.count || allSebhas.count != allSebhasCounter.count {
            print("Inconsistent array lengths detected after loading")
        }
    }
    
    func removeSebha(at index: Int) {
        guard index < allSebhas.count else { return }
        
        allSebhas.remove(at: index)
        allSebhasTarget.remove(at: index)
        allSebhasCounter.remove(at: index)
        
        if allSebhas.isEmpty {
            selectedSebha = ""
            currentTarget = 0
            currentIndex = 0
        } else {
            if index <= currentIndex {
                // If we removed an item before or at current index, adjust current index
                currentIndex = max(0, currentIndex - 1)
            }
            // Ensure current index is within bounds
            currentIndex = min(currentIndex, allSebhas.count - 1)
            
            selectedSebha = allSebhas[currentIndex]
            currentTarget = allSebhasTarget[currentIndex]
        }
        updateProgress()
        saveSebhas()
    }
    private var isRestarting = false // Added flag to prevent multiple restarts
    private func handleSpokenText(_ text: String) {
        let sebhaPhrase = selectedSebha.trimmingCharacters(in: .whitespacesAndNewlines)
        let sebhaWords = sebhaPhrase.split(separator: " ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).removingInvisibleCharacters() }
        let spokenWords = text.split(separator: " ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).removingInvisibleCharacters() }
        
        print("Recognized text: \(text)")
        print("Sebha phrase: \(sebhaPhrase)")
        
        var matchCount = 0
        var i = 0
        
        while i <= spokenWords.count - sebhaWords.count {
            var isMatch = true
            for j in 0..<sebhaWords.count {
                let spokenWord = spokenWords[i + j]
                let sebhaWord = sebhaWords[j]
                print("Comparing: '\(spokenWord)' with '\(sebhaWord)'")
                if spokenWord.caseInsensitiveCompare(sebhaWord) != .orderedSame {
                    isMatch = false
                    print("No match at word \(i + j): '\(spokenWord)' != '\(sebhaWord)'")
                    break
                }
            }
            if isMatch {
                matchCount += 1
                print("Match found: \(Array(spokenWords[i..<i + sebhaWords.count]).joined(separator: " "))")
                i += sebhaWords.count // Move the index by the length of the phrase to avoid overlapping
            } else {
                print("No match: \(Array(spokenWords[i..<min(i + sebhaWords.count, spokenWords.count)]).joined(separator: " "))")
                i += 1
            }
        }
        
        print("Total matches found: \(matchCount)")
        
        let newMatchesCount = matchCount - before
        before = matchCount
        
        if newMatchesCount > 0 {
            counter += newMatchesCount
            allSebhasCounter[currentIndex] += newMatchesCount
            saveSebhas()
            
            print("New matches count: \(newMatchesCount)")
            print("Updated counter: \(counter)")
            print("All Sebhas counter: \(allSebhasCounter)")
            
            if counter >= currentTarget && currentTarget > 0 {
                triggerVibration()
                playCompletionSound()
                showAlert = true
                delegate?.didReachTarget()
                
                // Auto switch to next sebha after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.switchToNextSebha()
                }
            }
        }
    }


        
    func startSpeechRecognition() {
        before = 0 // Reset the count before starting recognition
        
        // Stop any existing recognition
        if audioEngine.isRunning {
            stopSpeechRecognition()
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let spokenText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.handleSpokenText(spokenText)
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopSpeechRecognition()
            }
        }
        
        // Use the input node's actual format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("Speech recognition started successfully")
        } catch {
            print("audioEngine couldn't start because of an error: \(error.localizedDescription)")
        }
    }

    func stopSpeechRecognition() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionRequest = nil
            recognitionTask = nil
        }
    }
    
    // MARK: - Reordering Functions
    func moveSebha(from source: IndexSet, to destination: Int) {
        // Move the items in all related arrays
        allSebhas.move(fromOffsets: source, toOffset: destination)
        allSebhasTarget.move(fromOffsets: source, toOffset: destination)
        allSebhasCounter.move(fromOffsets: source, toOffset: destination)
        
        // Update current index if necessary
        if let sourceIndex = source.first {
            if sourceIndex == currentIndex {
                // If the current sebha was moved, update the current index
                let newIndex = sourceIndex < destination ? destination - 1 : destination
                currentIndex = newIndex
            } else if sourceIndex < currentIndex && destination > currentIndex {
                // Item moved from before current to after current
                currentIndex -= 1
            } else if sourceIndex > currentIndex && destination <= currentIndex {
                // Item moved from after current to before/at current
                currentIndex += 1
            }
        }
        
        saveSebhas()
    }
    
    // MARK: - Sound Functions
    private func playCompletionSound() {
        // Play system sound for completion
        AudioServicesPlaySystemSound(1001) // Success sound
        
        // Optionally, you can also play a custom sound
        // guard let url = Bundle.main.url(forResource: "completion", withExtension: "mp3") else { return }
        // 
        // do {
        //     audioPlayer = try AVAudioPlayer(contentsOf: url)
        //     audioPlayer?.play()
        // } catch {
        //     print("Error playing completion sound: \(error)")
        // }
    }
    
    private func switchToNextSebha() {
        guard !allSebhas.isEmpty else { return }
        
        let nextIndex = (currentIndex + 1) % allSebhas.count
        currentIndex = nextIndex
        selectedSebha = allSebhas[nextIndex]
        currentTarget = allSebhasTarget[nextIndex]
        counter = 0
        
        // Update progress
        updateProgress()
        
        print("Switched to next sebha: \(selectedSebha)")
        
        // Play voice prompt for the new sebha instead of showing alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playVoicePrompt(for: self.selectedSebha)
        }
    }
    
    func selectSebha(at index: Int) {
        guard index < allSebhas.count else { return }
        
        currentIndex = index
        selectedSebha = allSebhas[index]
        currentTarget = allSebhasTarget[index]
        counter = 0
        updateProgress()
        saveSebhas()
    }
    
    // MARK: - Voice Recording Functions
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func getVoiceRecordingURL(for sebha: String) -> URL {
        let filename = sebha.replacingOccurrences(of: " ", with: "_") + "_voice.m4a"
        return getDocumentsDirectory().appendingPathComponent(filename)
    }
    
    func startRecordingVoicePrompt(for index: Int) {
        guard index < allSebhas.count else { return }
        
        recordingForSebhaIndex = index
        let sebha = allSebhas[index]
        let recordingURL = getVoiceRecordingURL(for: sebha)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            voiceRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            voiceRecorder?.record()
            isRecordingVoicePrompt = true
            print("Started recording voice prompt for: \(sebha)")
        } catch {
            print("Could not start recording voice prompt: \(error)")
        }
    }
    
    func stopRecordingVoicePrompt() {
        guard let recorder = voiceRecorder, let index = recordingForSebhaIndex else { return }
        
        recorder.stop()
        isRecordingVoicePrompt = false
        
        let sebha = allSebhas[index]
        let recordingURL = getVoiceRecordingURL(for: sebha)
        sebhaRecordings[sebha] = recordingURL
        
        saveVoiceRecordings()
        print("Stopped recording voice prompt for: \(sebha)")
        
        voiceRecorder = nil
        recordingForSebhaIndex = nil
    }
    
    func playVoicePrompt(for sebha: String) {
        guard let recordingURL = sebhaRecordings[sebha] else {
            print("No voice recording found for: \(sebha)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.play()
            print("Playing voice prompt for: \(sebha)")
        } catch {
            print("Could not play voice prompt: \(error)")
        }
    }
    
    func hasVoiceRecording(for sebha: String) -> Bool {
        guard let url = sebhaRecordings[sebha] else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func deleteVoiceRecording(for sebha: String) {
        guard let recordingURL = sebhaRecordings[sebha] else { return }
        
        do {
            try FileManager.default.removeItem(at: recordingURL)
            sebhaRecordings.removeValue(forKey: sebha)
            saveVoiceRecordings()
            print("Deleted voice recording for: \(sebha)")
        } catch {
            print("Could not delete voice recording: \(error)")
        }
    }
    
    private func saveVoiceRecordings() {
        let recordings = sebhaRecordings.mapValues { $0.path }
        UserDefaults.standard.set(recordings, forKey: "sebhaVoiceRecordings")
    }
    
    private func loadVoiceRecordings() {
        guard let savedRecordings = UserDefaults.standard.dictionary(forKey: "sebhaVoiceRecordings") as? [String: String] else { return }
        
        sebhaRecordings = savedRecordings.compactMapValues { path in
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: path) ? url : nil
        }
        
        print("Loaded voice recordings: \(sebhaRecordings.keys)")
    }
}
