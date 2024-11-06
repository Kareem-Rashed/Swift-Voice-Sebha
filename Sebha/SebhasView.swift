import SwiftUI

struct SebhasView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @State private var showAddSebhaSheet = false
    @State private var showEditSebhaSheet = false
    @State private var newSebhaName = ""
    @State private var newSebhaTarget = ""

    var body: some View {
        VStack {
            Text("Sebhas")
                .font(.title2)
                .padding(.top, 20)
                .offset(x: -150, y: 0)
            List {
                ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.allSebhas[index])
                            .font(.headline)
                            .padding(.bottom, 2)
                            .foregroundColor(.primary) // Ensure text is visible in dark mode
                        
                        HStack {
                            Text("Target: \(viewModel.allSebhasTarget[index])")
                                .foregroundColor(.primary) // Ensure text is visible in dark mode
                            Spacer()
                            Button(action: {
                                viewModel.editSebhaTarget(at: index)
                                showEditSebhaSheet = true
                            }) {
                                Text("Edit Target")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Total Count: \(viewModel.allSebhasCounter[index])")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground)) // Adjust background color for dark mode
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.vertical, 8)
                }
                .onDelete { indexSet in
                    indexSet.forEach { viewModel.removeSebha(at: $0) }
                }
            }
            .listStyle(PlainListStyle())
            .padding(.horizontal)
            .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)) // Remove the white frame background

            Button(action: {
                showAddSebhaSheet = true
            }) {
                Text("Add New Sebha")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)) // Ensure background is consistent in dark mode
        .sheet(isPresented: $showAddSebhaSheet) {
            VStack {
                Text("Add New Sebha")
                    .font(.headline)
                    .padding()
                TextField("Sebha Name", text: $viewModel.recognizedText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Target", text: $newSebhaTarget)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                HStack {
                    Button("Add") {
                        if let target = Int(newSebhaTarget), !viewModel.recognizedText.isEmpty {
                            viewModel.newSebha = viewModel.recognizedText
                            viewModel.newSebhaTarget = newSebhaTarget
                            viewModel.addCustomSebha()
                            viewModel.recognizedText = ""
                            newSebhaTarget = ""
                            showAddSebhaSheet = false
                        }
                    }
                    .padding()
                    Spacer()
                    Button("Cancel") {
                        showAddSebhaSheet = false
                    }
                    .padding()
                }
                .padding()

                HStack {
                    Button(action: {
                        if viewModel.isRecordingForNewSebha {
                            viewModel.stopSpeechRecognitionForNewSebha()
                        } else {
                            viewModel.startSpeechRecognitionForNewSebha()
                        }
                    }) {
                        Text(viewModel.isRecordingForNewSebha ? "Stop Recording" : "Start Recording")
                            .padding()
                            .background(viewModel.isRecordingForNewSebha ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                Text(viewModel.recognizedText)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding()
            }
            .padding()
        }
        .sheet(isPresented: $showEditSebhaSheet) {
            VStack {
                Text("Edit Sebha Target")
                    .font(.headline)
                    .padding()
                TextField("New Target", text: $viewModel.newTarget)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .padding()
                HStack {
                    Button("Save") {
                        viewModel.updateSebhaTarget()
                        showEditSebhaSheet = false
                    }
                    .padding()
                    Spacer()
                    Button("Cancel") {
                        showEditSebhaSheet = false
                    }
                    .padding()
                }
                .padding()
            }
            .padding()
        }
    }
}

struct SebhasView_Previews: PreviewProvider {
    static var previews: some View {
        SebhasView(viewModel: SebhaViewModel())
    }
}

