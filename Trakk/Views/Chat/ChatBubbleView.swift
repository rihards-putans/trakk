import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            Text(message.content ?? "")
                .font(.system(size: 14))
                .foregroundColor(isUser ? .white : Theme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Theme.primary : Theme.cardSurface)
                .cornerRadius(16)

            if !isUser { Spacer(minLength: 60) }
        }
    }
}
