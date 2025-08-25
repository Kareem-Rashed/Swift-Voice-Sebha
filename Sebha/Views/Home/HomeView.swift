import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: SebhaViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            HeaderView(colorScheme: colorScheme)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Sebha Selection Card
                    SebhaSelectionCard(viewModel: viewModel)
                    
                    // Stats and Controls Row
                    StatsControlsRow(viewModel: viewModel)
                    
                    // Main Counter Section
                    CounterSection(viewModel: viewModel)
                    
                    // Progress Section
                    ProgressSection(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.secondarySystemBackground).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HeaderView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Image(colorScheme == .dark ? "darkLogo" : "lightLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
            
            Spacer()
            
            Button(action: {
                // Info action
            }) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
}

struct SebhaSelectionCard: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Sebha")
                .font(.headline)
                .foregroundColor(.secondary)
            
            SebhaScrollablePicker(
                selectedSebha: $viewModel.selectedSebha,
                counterUpdate: $viewModel.counter,
                targetUpdate: $viewModel.currentTarget,
                allSebhas: viewModel.allSebhas,
                allSebhasTarget: viewModel.allSebhasTarget,
                onSebhaSelected: { index in
                    viewModel.selectSebha(at: index)
                }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatsControlsRow: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Target Info Card
            VStack(spacing: 8) {
                Text("Target")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.currentTarget)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Voice Toggle Card
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.isVoice.toggle()
                }
            }) {
                VStack(spacing: 8) {
                    Image(systemName: viewModel.isVoice ? "mic.fill" : "mic.slash.fill")
                        .font(.title3)
                        .foregroundColor(viewModel.isVoice ? .green : .red)
                    
                    Text(viewModel.isVoice ? "Voice On" : "Voice Off")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.isVoice ? .green : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill((viewModel.isVoice ? Color.green : Color.red).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke((viewModel.isVoice ? Color.green : Color.red).opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

struct CounterSection: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Sebha Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.incrementCount(for: viewModel.selectedSebha)
                }
            }) {
                Text(viewModel.selectedSebha)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
            }
            .scaleEffect(viewModel.counter > 0 ? 1.0 : 0.98)
            .animation(.spring(response: 0.3), value: viewModel.counter)
        }
    }
}

struct ProgressSection: View {
    @ObservedObject var viewModel: SebhaViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Counter Display
            VStack(spacing: 8) {
                Text("Current Session")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.counter)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                
                Text("Total: \(viewModel.allSebhasCounter[safe: viewModel.currentIndex] ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.currentSebhaProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                ProgressView(value: viewModel.currentSebhaProgress)
                    .progressViewStyle(CustomProgressStyle())
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentSebhaProgress)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

struct CustomProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 12)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 12
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 12)
                            .mask(
                                HStack(spacing: 4) {
                                    ForEach(0..<20, id: \.self) { _ in
                                        Rectangle()
                                            .frame(width: 2)
                                    }
                                }
                            )
                    )
            }
        }
        .frame(height: 12)
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
