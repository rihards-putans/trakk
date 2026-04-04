import SwiftUI

struct RadialMenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let action: () -> Void
}

struct FABView: View {
    let onBarcodeScan: () -> Void
    let onTextLog: () -> Void

    @State private var isExpanded = false

    private var menuItems: [RadialMenuItem] {
        [
            RadialMenuItem(icon: "barcode.viewfinder", label: "Scan", action: {
                withAnimation(.spring(response: 0.3)) { isExpanded = false }
                onBarcodeScan()
            }),
            RadialMenuItem(icon: "pencil", label: "Log", action: {
                withAnimation(.spring(response: 0.3)) { isExpanded = false }
                onTextLog()
            }),
        ]
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dimming overlay
            if isExpanded {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded = false
                        }
                    }
                    .transition(.opacity)
            }

            VStack(alignment: .trailing, spacing: 12) {
                // Radial menu items
                if isExpanded {
                    ForEach(menuItems.reversed()) { item in
                        Button(action: item.action) {
                            HStack(spacing: 10) {
                                Text(item.label)
                                    .font(Font.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.cardSurface)
                                    .cornerRadius(8)

                                ZStack {
                                    Circle()
                                        .fill(Theme.inactive)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: item.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Main FAB button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        isExpanded.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary)
                            .frame(width: 56, height: 56)
                            .shadow(color: Theme.primary.opacity(0.4), radius: 12, x: 0, y: 6)

                        Image(systemName: isExpanded ? "xmark" : "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Theme.background)
                            .rotationEffect(.degrees(isExpanded ? 45 : 0))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                }
            }
            .padding(.trailing, Theme.screenPadding)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Theme.background.ignoresSafeArea()
        FABView(onBarcodeScan: {}, onTextLog: {})
    }
    .preferredColorScheme(.dark)
}
