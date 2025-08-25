import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabBarItem: View {
    let tab: Tab
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(height: 20)
                
                Text(tab.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

enum Tab: CaseIterable {
    case home, sebhas, profile, friends
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .sebhas: return "Sebhas"
        case .profile: return "Profile"
        case .friends: return "Friends"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .sebhas: return "book.fill"
        case .profile: return "person.fill"
        case .friends: return "person.2.fill"
        }
    }
}
