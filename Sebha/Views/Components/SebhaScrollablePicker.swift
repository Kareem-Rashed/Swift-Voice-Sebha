import SwiftUI

struct SebhaScrollablePicker: View {
    @Binding var selectedSebha: String
    @Binding var counterUpdate: Int
    @Binding var targetUpdate: Int
    var allSebhas: [String]
    var allSebhasTarget: [Int]
    var onSebhaSelected: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(allSebhas.indices, id: \.self) { index in
                        SebhaPickerItem(
                            sebha: allSebhas[index],
                            isSelected: index == (allSebhas.firstIndex(of: selectedSebha) ?? 0),
                            onTap: {
                                withAnimation(.spring(response: 0.4)) {
                                    proxy.scrollTo(index, anchor: .center)
                                    onSebhaSelected(index)
                                }
                            }
                        )
                        .id(index)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(height: 180)
            .onChange(of: selectedSebha) { newValue in
                if let index = allSebhas.firstIndex(of: newValue) {
                    withAnimation(.spring(response: 0.4)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
}

struct SebhaPickerItem: View {
    let sebha: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(sebha)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color(UIColor.tertiarySystemBackground), Color(UIColor.tertiarySystemBackground)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? Color.blue.opacity(0.5) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .shadow(
                    color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
