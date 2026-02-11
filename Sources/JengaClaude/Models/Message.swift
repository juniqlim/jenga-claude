import Foundation

struct Message: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    var isDisabled = false

    enum Role {
        case user
        case assistant
    }

    static func copyText(_ messages: [Message], activeOnly: Bool) -> String {
        let targets = activeOnly ? messages.filter { !$0.isDisabled } : messages
        return targets.map { msg in
            let role = msg.role == .user ? "나" : "Claude"
            return "\(role): \(msg.content)"
        }.joined(separator: "\n\n")
    }
}
