enum ConversationFormatter {
    static func format(history: [Message], newMessage: String) -> String {
        guard !history.isEmpty else { return newMessage }

        var parts: [String] = ["[이전 대화]"]
        for msg in history {
            let role = msg.role == .user ? "사용자" : "어시스턴트"
            parts.append("\(role): \(msg.content)")
        }
        parts.append("")
        parts.append("[현재 메시지]")
        parts.append(newMessage)
        return parts.joined(separator: "\n")
    }
}
