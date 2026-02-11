import AppKit

enum MessageAttributedStringBuilder {
    static func build(messages: [Message], streamingText: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for (index, message) in messages.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n\n"))
            }
            result.append(attributedString(for: message))
        }

        if !streamingText.isEmpty {
            if !messages.isEmpty {
                result.append(NSAttributedString(string: "\n\n"))
            }
            result.append(assistantAttributedString(streamingText))
        }

        return result
    }

    private static func attributedString(for message: Message) -> NSAttributedString {
        switch message.role {
        case .user:
            return userAttributedString(message.content)
        case .assistant:
            return assistantAttributedString(message.content)
        }
    }

    private static func userAttributedString(_ text: String) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.systemBlue,
        ]
        return NSAttributedString(string: "나: \(text)", attributes: attrs)
    }

    private static func assistantAttributedString(_ text: String) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor,
        ]
        return NSAttributedString(string: text, attributes: attrs)
    }
}
