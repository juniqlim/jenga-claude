import SwiftUI

struct MessageView: View {
    let message: Message
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            if message.role == .user { Spacer() }

            if message.role == .user { deleteLabel }

            Text(message.content)
                .padding(10)
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(12)

            if message.role == .assistant { deleteLabel }

            if message.role == .assistant { Spacer() }
        }
    }

    private var deleteLabel: some View {
        Button(action: onDelete) {
            HStack(spacing: 2) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                if index < 9 {
                    Text("⌘\(index + 1)")
                        .font(.system(size: 10, design: .monospaced))
                }
            }
            .foregroundColor(.gray.opacity(0.4))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
