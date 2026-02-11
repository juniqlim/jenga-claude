import XCTest
@testable import JengaClaude
import AppKit

/// ConversationTextView의 핵심 로직 검증:
/// MessageAttributedStringBuilder로 만든 NSAttributedString이
/// NSTextView에 올바르게 표시되는지 테스트
final class ConversationTextViewTests: XCTestCase {
    private func makeTextView(messages: [Message], streamingText: String) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true

        let attributed = MessageAttributedStringBuilder.build(
            messages: messages,
            streamingText: streamingText
        )
        textView.textStorage?.setAttributedString(attributed)
        return textView
    }

    func test_userMessage_displayedInTextView() {
        let tv = makeTextView(
            messages: [Message(role: .user, content: "안녕하세요")],
            streamingText: ""
        )
        XCTAssertTrue(tv.string.contains("나: 안녕하세요"))
    }

    func test_assistantMessage_displayedInTextView() {
        let tv = makeTextView(
            messages: [Message(role: .assistant, content: "반갑습니다")],
            streamingText: ""
        )
        XCTAssertTrue(tv.string.contains("반갑습니다"))
    }

    func test_streamingText_displayedInTextView() {
        let tv = makeTextView(
            messages: [Message(role: .user, content: "질문")],
            streamingText: "응답 중..."
        )
        XCTAssertTrue(tv.string.contains("나: 질문"))
        XCTAssertTrue(tv.string.contains("응답 중..."))
    }

    func test_updateReplacesContent() {
        let tv = makeTextView(
            messages: [Message(role: .user, content: "첫번째")],
            streamingText: ""
        )
        XCTAssertTrue(tv.string.contains("나: 첫번째"))
        XCTAssertFalse(tv.string.contains("두번째"))

        // 업데이트 시뮬레이션
        let updated = MessageAttributedStringBuilder.build(
            messages: [
                Message(role: .user, content: "첫번째"),
                Message(role: .assistant, content: "두번째"),
            ],
            streamingText: ""
        )
        tv.textStorage?.setAttributedString(updated)

        XCTAssertTrue(tv.string.contains("나: 첫번째"))
        XCTAssertTrue(tv.string.contains("두번째"))
    }

    func test_emptyState() {
        let tv = makeTextView(messages: [], streamingText: "")
        XCTAssertEqual(tv.string, "")
    }

    func test_textViewProperties() {
        let tv = makeTextView(messages: [], streamingText: "")
        XCTAssertTrue(tv.isSelectable)
        XCTAssertFalse(tv.isEditable)
    }

    func test_multipleMessages_allVisible() {
        let messages = [
            Message(role: .user, content: "1번"),
            Message(role: .assistant, content: "답변1"),
            Message(role: .user, content: "2번"),
            Message(role: .assistant, content: "답변2"),
        ]
        let tv = makeTextView(messages: messages, streamingText: "스트리밍")
        XCTAssertTrue(tv.string.contains("나: 1번"))
        XCTAssertTrue(tv.string.contains("답변1"))
        XCTAssertTrue(tv.string.contains("나: 2번"))
        XCTAssertTrue(tv.string.contains("답변2"))
        XCTAssertTrue(tv.string.contains("스트리밍"))
    }
}
