import XCTest
@testable import JengaClaude
import AppKit

final class MessageAttributedStringBuilderTests: XCTestCase {
    func test_emptyMessages_noStreaming_returnsEmpty() {
        let result = MessageAttributedStringBuilder.build(messages: [], streamingText: "")
        XCTAssertEqual(result.length, 0)
    }

    func test_singleUserMessage() {
        let messages = [Message(role: .user, content: "안녕")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")
        let text = result.string
        XCTAssertTrue(text.contains("나: 안녕"))
    }

    func test_singleAssistantMessage() {
        let messages = [Message(role: .assistant, content: "반갑습니다")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")
        let text = result.string
        XCTAssertTrue(text.contains("반갑습니다"))
        XCTAssertFalse(text.contains("나:"))
    }

    func test_userMessage_hasBlueBackground() {
        let messages = [Message(role: .user, content: "테스트")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")

        let range = (result.string as NSString).range(of: "나: 테스트")
        XCTAssertNotEqual(range.location, NSNotFound)

        let attrs = result.attributes(at: range.location, effectiveRange: nil)
        let bgColor = attrs[.backgroundColor] as? NSColor
        XCTAssertNotNil(bgColor)
    }

    func test_userMessage_hasWhiteForeground() {
        let messages = [Message(role: .user, content: "테스트")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")

        let range = (result.string as NSString).range(of: "나: 테스트")
        let attrs = result.attributes(at: range.location, effectiveRange: nil)
        let fgColor = attrs[.foregroundColor] as? NSColor
        XCTAssertEqual(fgColor, NSColor.white)
    }

    func test_multipleMessages_separatedByNewlines() {
        let messages = [
            Message(role: .user, content: "질문"),
            Message(role: .assistant, content: "답변"),
        ]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")
        let text = result.string
        XCTAssertTrue(text.contains("나: 질문"))
        XCTAssertTrue(text.contains("답변"))
        // 메시지 사이에 줄바꿈이 있어야 함
        let lines = text.components(separatedBy: "\n")
        XCTAssertTrue(lines.count >= 2)
    }

    func test_streamingText_appended() {
        let messages = [Message(role: .user, content: "질문")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "응답 중...")
        let text = result.string
        XCTAssertTrue(text.contains("나: 질문"))
        XCTAssertTrue(text.contains("응답 중..."))
    }

    func test_onlyStreamingText_noMessages() {
        let result = MessageAttributedStringBuilder.build(messages: [], streamingText: "스트리밍")
        let text = result.string
        XCTAssertTrue(text.contains("스트리밍"))
    }

    func test_assistantMessage_hasDefaultForeground() {
        let messages = [Message(role: .assistant, content: "답변")]
        let result = MessageAttributedStringBuilder.build(messages: messages, streamingText: "")

        let range = (result.string as NSString).range(of: "답변")
        let attrs = result.attributes(at: range.location, effectiveRange: nil)
        let fgColor = attrs[.foregroundColor] as? NSColor
        // assistant는 흰색이 아닌 기본 텍스트 색상
        XCTAssertNotEqual(fgColor, NSColor.white)
    }
}
