import SwiftUI

struct SebhasView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @State private var showAddSebhaSheet = false
    @State private var showEditSebhaSheet = false
    @State private var showRecordVoiceSheet = false
    @State private var recordingVoiceForIndex: Int? = nil
    @State private var editingSebhaIndex: Int?
    @State private var newSebhaName = ""
    @State private var newSebhaTarget = ""
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with title and edit button
                HStack {
                    Text("My Sebhas")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }) {
                        Text(editMode == .active ? "Done" : "Edit")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Sebhas List
                List {
                    ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                        SebhaCard(
                            sebha: viewModel.allSebhas[index],
                            target: viewModel.allSebhasTarget[index],
                            count: viewModel.allSebhasCounter[index],
                            isSelected: viewModel.selectedSebha == viewModel.allSebhas[index],
                            editMode: editMode,
                            onTap: {
                                viewModel.selectSebha(at: index)
                            },
                            onEdit: {
                                editingSebhaIndex = index
                                viewModel.editSebhaTarget(at: index)
                                showEditSebhaSheet = true
                            },
                            onRecordVoice: {
                                recordingVoiceForIndex = index
                                showRecordVoiceSheet = true
                            },
                            viewModel: viewModel
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: editMode == .active ? moveSebha : nil)
                    .onDelete(perform: editMode == .active ? deleteSebha : nil)
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, $editMode)
                .padding(.horizontal, 10)

                
                // Add Button
                Button(action: {
                    showAddSebhaSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add New Sebha")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 10)
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddSebhaSheet) {
            AddSebhaSheet(viewModel: viewModel, isPresented: $showAddSebhaSheet, newSebhaTarget: $newSebhaTarget)
        }
        .sheet(isPresented: $showEditSebhaSheet) {
            EditSebhaSheet(viewModel: viewModel, isPresented: $showEditSebhaSheet)
        }
        .sheet(isPresented: $showRecordVoiceSheet) {
            RecordVoiceSheet(
                viewModel: viewModel, 
                isPresented: $showRecordVoiceSheet,
                sebhaIndex: recordingVoiceForIndex ?? 0
            )
        }
    }
    
    // MARK: - Helper Functions
    private func moveSebha(from source: IndexSet, to destination: Int) {
        viewModel.moveSebha(from: source, to: destination)
    }
    
    private func deleteSebha(at offsets: IndexSet) {
        offsets.forEach { viewModel.removeSebha(at: $0) }
    }
}

// MARK: - SebhaCard Component
struct SebhaCard: View {
    let sebha: String
    let target: Int
    let count: Int
    let isSelected: Bool
    let editMode: EditMode
    let onTap: () -> Void
    let onEdit: () -> Void
    let onRecordVoice: () -> Void
    @ObservedObject var viewModel: SebhaViewModel
    
    var completionPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(count) / Double(target), 1.0)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Sebha Text
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sebha)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(count)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Target")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(target)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            if editMode == .inactive {
                                HStack(spacing: 8) {
                                    // Record voice button
                                    Button(action: onRecordVoice) {
                                        Image(systemName: "waveform.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Voice recording button
                                    Button(action: {
                                        if viewModel.hasVoiceRecording(for: sebha) {
                                            viewModel.playVoicePrompt(for: sebha)
                                        }
                                    }) {
                                        Image(systemName: viewModel.hasVoiceRecording(for: sebha) ? "play.circle.fill" : "mic.slash.circle")
                                            .font(.title2)
                                            .foregroundColor(viewModel.hasVoiceRecording(for: sebha) ? .green : .gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: onEdit) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected && editMode == .inactive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                
                // Progress bar
                if target > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("\(Int(completionPercentage * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 6)
                                    .opacity(0.2)
                                    .foregroundColor(.gray)
                                
                                Rectangle()
                                    .frame(width: min(CGFloat(completionPercentage) * geometry.size.width, geometry.size.width), height: 6)
                                    .foregroundColor(completionPercentage >= 1.0 ? .green : .blue)
                                    .animation(.easeInOut(duration: 0.5), value: completionPercentage)
                            }
                            .cornerRadius(3)
                        }
                        .frame(height: 6)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Sebha Sheet
struct AddSebhaSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    @Binding var newSebhaTarget: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Add New Sebha")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sebha Text")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter sebha text", text: $viewModel.recognizedText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Target")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter daily target", text: $newSebhaTarget)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.body)
                    }
                    
                    // Voice recording section
                    VStack(spacing: 12) {
                        Text("Or Record Voice")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            if viewModel.isRecordingForNewSebha {
                                viewModel.stopSpeechRecognitionForNewSebha()
                            } else {
                                viewModel.startSpeechRecognitionForNewSebha()
                            }
                        }) {
                            HStack {
                                Image(systemName: viewModel.isRecordingForNewSebha ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(viewModel.isRecordingForNewSebha ? "Stop Recording" : "Start Recording")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(viewModel.isRecordingForNewSebha ? Color.red : Color.blue)
                            .cornerRadius(12)
                        }
                        
                        if !viewModel.recognizedText.isEmpty {
                            Text("Recognized: \(viewModel.recognizedText)")
                                .font(.caption)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        resetFields()
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("Add Sebha") {
                        if let target = Int(newSebhaTarget), !viewModel.recognizedText.isEmpty {
                            viewModel.newSebha = viewModel.recognizedText
                            viewModel.newSebhaTarget = newSebhaTarget
                            viewModel.addCustomSebha()
                            resetFields()
                            isPresented = false
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(canAddSebha ? Color.green : Color.gray)
                    .cornerRadius(12)
                    .disabled(!canAddSebha)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canAddSebha: Bool {
        !viewModel.recognizedText.isEmpty && !newSebhaTarget.isEmpty && Int(newSebhaTarget) != nil
    }
    
    private func resetFields() {
        viewModel.recognizedText = ""
        newSebhaTarget = ""
        if viewModel.isRecordingForNewSebha {
            viewModel.stopSpeechRecognitionForNewSebha()
        }
    }
}

// MARK: - Edit Sebha Sheet
struct EditSebhaSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Edit Target")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("New Daily Target")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter new target", text: $viewModel.newTarget)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("Save") {
                        viewModel.updateSebhaTarget()
                        isPresented = false
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(canSave ? Color.green : Color.gray)
                    .cornerRadius(12)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canSave: Bool {
        !viewModel.newTarget.isEmpty && Int(viewModel.newTarget) != nil
    }
}

// MARK: - Record Voice Sheet
struct RecordVoiceSheet: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Binding var isPresented: Bool
    let sebhaIndex: Int
    
    private var sebha: String {
        guard sebhaIndex < viewModel.allSebhas.count else { return "" }
        return viewModel.allSebhas[sebhaIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Record Voice Prompt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    Text("Sebha:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(sebha)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                VStack(spacing: 20) {
                    Text("Record yourself saying this sebha. This will be played when you switch to this sebha.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Recording button
                    Button(action: {
                        if viewModel.isRecordingVoicePrompt {
                            viewModel.stopRecordingVoicePrompt()
                        } else {
                            viewModel.startRecordingVoicePrompt(for: sebhaIndex)
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.isRecordingVoicePrompt ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text(viewModel.isRecordingVoicePrompt ? "Stop Recording" : "Start Recording")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 40)
                        .background(viewModel.isRecordingVoicePrompt ? Color.red : Color.blue)
                        .cornerRadius(20)
                        .shadow(color: viewModel.isRecordingVoicePrompt ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    // Play button (if recording exists)
                    if viewModel.hasVoiceRecording(for: sebha) {
                        Button(action: {
                            viewModel.playVoicePrompt(for: sebha)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Play Recording")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.green)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            viewModel.deleteVoiceRecording(for: sebha)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                Text("Delete Recording")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                // Done button
                Button("Done") {
                    if viewModel.isRecordingVoicePrompt {
                        viewModel.stopRecordingVoicePrompt()
                    }
                    isPresented = false
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 40)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
}

struct SebhasView_Previews: PreviewProvider {
    static var previews: some View {
        SebhasView(viewModel: SebhaViewModel())
    }
}

