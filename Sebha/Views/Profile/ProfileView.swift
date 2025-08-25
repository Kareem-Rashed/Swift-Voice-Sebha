import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel = SebhaViewModel()
    
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Total Stats
                    VStack(alignment: .leading) {
                        Text("Total Stats")
                            .font(.headline)
                        Text("Total Sebha: \(viewModel.allSebhasCounter.reduce(0, +))")
                        Text("Average per Sebha: \(viewModel.allSebhasCounter.reduce(0, +) / max(viewModel.allSebhasCounter.count, 1))")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Weekly Stats
                    VStack(alignment: .leading) {
                        Text("Weekly Stats")
                            .font(.headline)
                        // Add logic to calculate weekly stats here
                        Text("Total this week: \(viewModel.calculateWeeklyStats())")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Monthly Stats
                    VStack(alignment: .leading) {
                        Text("Monthly Stats")
                            .font(.headline)
                        // Add logic to calculate monthly stats here
                        Text("Total this month: \(viewModel.calculateMonthlyStats())")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Daily Stats
                    VStack(alignment: .leading) {
                        Text("Daily Stats")
                            .font(.headline)
                        // Add logic to calculate daily stats here
                        Text("Total today: \(viewModel.calculateDailyStats())")
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Individual Sebha Stats
                    VStack(alignment: .leading) {
                        Text("Individual Sebha Stats")
                            .font(.headline)
                        ForEach(viewModel.allSebhas.indices, id: \.self) { index in
                            VStack(alignment: .leading) {
                                Text(viewModel.allSebhas[index])
                                    .font(.subheadline)
                                Text("Count: \(viewModel.allSebhasCounter[index])")
                                Text("Target: \(viewModel.allSebhasTarget[index])")
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct ContentViews_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
