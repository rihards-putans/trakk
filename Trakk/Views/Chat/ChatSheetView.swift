import SwiftUI

struct ChatSheetView: View {
    @StateObject private var vm = ChatViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Coach").font(Theme.headingFont).foregroundColor(Theme.textPrimary)
                    Spacer()
                }
                .padding()

                Divider().background(Theme.inactive)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.messages, id: \.id) { msg in
                                ChatBubbleView(message: msg).id(msg.id)
                            }

                            if !vm.pendingFoodItems.isEmpty {
                                FoodConfirmationCard(
                                    items: vm.pendingFoodItems,
                                    onLog: { vm.logPendingFood() },
                                    onCancel: { vm.dismissPendingFood() }
                                )
                            }

                            if vm.isLoading {
                                HStack {
                                    ProgressView().tint(Theme.textMuted)
                                    Text("Thinking...")
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        if let lastID = vm.messages.last?.id {
                            withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                        }
                    }
                }

                Divider().background(Theme.inactive)

                // Input
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $vm.inputText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.cardSurface)
                        .cornerRadius(20)
                        .foregroundColor(Theme.textPrimary)
                        .focused($inputFocused)

                    Button(action: { Task { await vm.sendMessage() } }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(vm.inputText.isEmpty ? Theme.inactive : Theme.primary)
                    }
                    .disabled(vm.inputText.isEmpty || vm.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .onAppear { vm.loadHistory() }
    }
}
