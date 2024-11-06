import Foundation
import SwiftUI
import Speech

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
        print("Initialization done")
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
            showAlert = true
            delegate?.didReachTarget()
        }
        saveSebhas()
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
        
        selectedSebha = allSebhas.last!
        currentTarget = targetValue
        
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
        } else {
            if index < allSebhas.count {
                selectedSebha = allSebhas[index]
                currentTarget = allSebhasTarget[index]
            } else {
                selectedSebha = allSebhas.first ?? ""
                currentTarget = allSebhasTarget.first ?? 0
            }
        }
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
                showAlert = true
                delegate?.didReachTarget()
            }
            
           
        }
    }


        
    func startSpeechRecognition() {
        before = 0 // Reset the count before starting recognition
        
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
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
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
}
