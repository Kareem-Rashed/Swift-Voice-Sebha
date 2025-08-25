import SwiftUI

struct FriendsView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Friends")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // Placeholder content for friends feature
            VStack(spacing: 20) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Connect with Friends")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Share your Sebha progress and compete with friends!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    // Add friend functionality
                }) {
                    Text("Coming Soon")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
}
