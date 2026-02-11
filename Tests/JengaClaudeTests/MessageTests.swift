import XCTest
@testable import JengaClaude

final class MessageTests: XCTestCase {
    func test_copyText_all_includesDisabled() {
        let messages = [
            Message(role: .user, content: "A"),
            Message(role: .assistant, content: "B", isDisabled: true),
            Message(role: .user, content: "C"),
        ]
        let text = Message.copyText(messages, activeOnly: false)
        XCTAssertTrue(text.contains("나: A"))
        XCTAssertTrue(text.contains("Claude: B"))
        XCTAssertTrue(text.contains("나: C"))
    }

    func test_copyText_activeOnly_excludesDisabled() {
        let messages = [
            Message(role: .user, content: "A"),
            Message(role: .assistant, content: "B", isDisabled: true),
            Message(role: .user, content: "C"),
        ]
        let text = Message.copyText(messages, activeOnly: true)
        XCTAssertTrue(text.contains("나: A"))
        XCTAssertFalse(text.contains("Claude: B"))
        XCTAssertTrue(text.contains("나: C"))
    }

    func test_copyText_empty() {
        let text = Message.copyText([], activeOnly: false)
        XCTAssertEqual(text, "")
    }

    func test_copyText_allDisabled_activeOnly_returnsEmpty() {
        let messages = [
            Message(role: .user, content: "A", isDisabled: true),
        ]
        let text = Message.copyText(messages, activeOnly: true)
        XCTAssertEqual(text, "")
    }

    func test_isDisabled_defaultFalse() {
        let msg = Message(role: .user, content: "hello")
        XCTAssertFalse(msg.isDisabled)
    }
}
