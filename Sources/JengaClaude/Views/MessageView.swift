import SwiftUI

struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            Text(message.content)
                .padding(10)
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(12)
                .textSelection(.enabled)
            if message.role == .assistant { Spacer() }
        }
    }
}
