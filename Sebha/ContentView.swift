import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SebhaViewModel()
    @State private var delegate: SebhaViewModelDelegateClass?
    @State private var selectedTab: Tab = .home
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()

                VStack {
                    // Top Bar
                    if selectedTab == .home {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .font(.title)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(colorScheme == .dark ? "darkLogo" : "lightLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 110) // Adjust the height as needed
                            Spacer()
                            Image(systemName: "info.circle")
                                .font(.title)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                    }

                    // Main Content
                    if selectedTab == .home {
                        // Home View Content
                        VStack(spacing: 20) {
                            // Custom Scrollable Picker
                            SebhaScrollablePicker(
                                selectedSebha: $viewModel.selectedSebha,
                                counterUpdate: $viewModel.counter,
                                targetUpdate: $viewModel.currentTarget,
                                allSebhas: viewModel.allSebhas,
                                allSebhasTarget: viewModel.allSebhasTarget
                            )
                            .padding()
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .padding(.horizontal)

                            // Add Sebha and Voice Toggle
                            HStack {
                                Text("Target: \(viewModel.currentTarget)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding()
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)

                                Spacer()

                                Button(action: {
                                    viewModel.isVoice.toggle()
                                }) {
                                    Text(viewModel.isVoice ? "Voice On" : "Voice Off")
                                        .font(.headline)
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(10)
                                        .shadow(radius: 5)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .green))
                            }
                            .padding(.horizontal)

                            // Sebha Counter Button
                            VStack {
                                Button(action: {
                                    viewModel.counter += 1
                                    viewModel.allSebhasCounter[viewModel.currentIndex] += 1

                                    if viewModel.counter >= viewModel.currentTarget && viewModel.currentTarget > 0 {
                                        viewModel.triggerVibration()
                                        viewModel.showAlert = true
                                        delegate?.didReachTarget()
                                    }
                                    viewModel.saveSebhas()
                                }) {
                                    Text(viewModel.selectedSebha)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, maxHeight: 50)
                                        .background(Color.green)
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                }

                                // Sebha Counter
                                VStack {
                                    Spacer()
                                    Text("\(viewModel.counter)")
                                        .font(.largeTitle)
                                    Text("\(viewModel.allSebhasCounter[viewModel.currentIndex])")
                                        .font(.footnote)
                                }
                                .padding()
                                .cornerRadius(15)
                                .shadow(radius: 5)

                                // Progress Bar
                                ProgressView(value: Double(viewModel.counter), total: Double(viewModel.currentTarget))
                                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                    .padding()
                            }
                            .padding(.horizontal)
                        }
                    } else if selectedTab == .sebhas {
                        SebhasView(viewModel: viewModel)
                    } else if selectedTab == .profile {
                        ProfileView(viewModel: viewModel)
                    } else if selectedTab == .friends {
                        FriendsView()
                    }

                    Spacer()

                    // Bottom Tab Bar
                    HStack {
                        Spacer()
                        Button(action: { selectedTab = .sebhas }) {
                            VStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == .sebhas ? .primary : .secondary)
                                Text("Sebhas")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTab == .sebhas ? .primary : .secondary)
                            }
                        }
                        
                        Spacer()
                        Button(action: { selectedTab = .home }) {
                            VStack {
                                Image(systemName: "house.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == .home ? .primary : .secondary)
                                Text("Home")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTab == .home ? .primary : .secondary)
                            }
                        }
                        Spacer()
                        Button(action: { selectedTab = .friends }) {
                            VStack {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == .friends ? .primary : .secondary)
                                Text("Friends")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTab == .friends ? .primary : .secondary)
                            }
                        }
                        
                        Spacer()
                        Button(action: { selectedTab = .profile }) {
                            VStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedTab == .profile ? .primary : .secondary)
                                Text("Profile")
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTab == .profile ? .primary : .secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGray5).opacity(0.9))
                    .cornerRadius(15)
                    .shadow(color: .gray, radius: 5, x: 0, y: 0)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("Congratulations!"),
                          message: Text("You have reached your target count of \(viewModel.currentTarget)."),
                          dismissButton: .default(Text("OK")))
                }
                .alert("Add Custom Sebha", isPresented: $viewModel.showAddSebhaAlert) {
                    TextField("New Sebha", text: $viewModel.newSebha)
                    TextField("New Sebha Target", text: $viewModel.newSebhaTarget)
                    Button("Add") {
                        viewModel.addCustomSebha()
                    }
                    Button("Record") {
                        viewModel.showAddSebhaAlert = true
                        //DispatchQueue.main.async {
                        // viewModel.startSpeechRecognitionForNewSebha()
                        //}
                    }
                    Button("Stop") {
                        viewModel.stopSpeechRecognition()
                        viewModel.Stopped = true
                        viewModel.showAddSebhaAlert = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .onAppear {
            delegate = SebhaViewModelDelegateClass(viewModel: viewModel)
        }
    }

    private func switchToNextSebha() {
        if let currentIndex = viewModel.allSebhas.firstIndex(of: viewModel.selectedSebha) {
            let nextIndex = (currentIndex + 1) % viewModel.allSebhas.count
            viewModel.selectedSebha = viewModel.allSebhas[nextIndex]
            viewModel.counter = 0
            viewModel.currentTarget = viewModel.allSebhasTarget[nextIndex]
        }
    }

    func didReachTarget() {
        switchToNextSebha()
    }
}
struct SebhaScrollablePicker: View {
    @Binding var selectedSebha: String
    @Binding var counterUpdate: Int
    @Binding var targetUpdate: Int
    var allSebhas: [String]
    var allSebhasTarget: [Int]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(allSebhas.indices, id: \.self) { index in
                        Text(allSebhas[index])
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(index == (allSebhas.firstIndex(of: selectedSebha) ?? 0) ? Color(UIColor.systemGray6) : Color.clear)
                            .foregroundColor(index == (allSebhas.firstIndex(of: selectedSebha) ?? 0) ? .primary : .green)
                            .cornerRadius(15)
                            .shadow(radius: 0)
                            .id(index) // Assign an ID to each item
                            .onTapGesture {
                                withAnimation {
                                    proxy.scrollTo(index, anchor: .center)
                                }
                                selectedSebha = allSebhas[index]
                                counterUpdate = 0
                                targetUpdate = allSebhasTarget[index]
                            }
                    }
                }
                .padding(.vertical, 10)
                .onChange(of: selectedSebha) { newValue in
                    if let index = allSebhas.firstIndex(of: newValue) {
                        withAnimation {
                            proxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 150)
        }
    }
}
struct FriendsView: View {
    var body: some View {
        VStack {
            Text("Friends")
                .font(.largeTitle)
                .padding()
            // Add friends interaction options here
        }
    }
}

enum Tab {
    case home, sebhas, profile, friends
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
