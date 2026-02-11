import Testing
import Foundation
@testable import JengaClaude

@Suite("ConversationFormatter")
struct ConversationFormatterTests {

    @Test("히스토리 없이 새 메시지만 보내면 그대로 반환")
    func noHistory() {
        let result = ConversationFormatter.format(
            history: [],
            newMessage: "안녕"
        )
        #expect(result == "안녕")
    }

    @Test("히스토리가 있으면 이전 대화를 포함한 프롬프트 생성")
    func withHistory() {
        let history = [
            Message(role: .user, content: "안녕"),
            Message(role: .assistant, content: "안녕하세요!"),
        ]
        let result = ConversationFormatter.format(
            history: history,
            newMessage: "오늘 뭐 먹을까?"
        )
        #expect(result.contains("안녕"))
        #expect(result.contains("안녕하세요!"))
        #expect(result.contains("오늘 뭐 먹을까?"))
    }

    @Test("여러 턴의 대화가 순서대로 포함됨")
    func multiTurnOrder() {
        let history = [
            Message(role: .user, content: "첫번째"),
            Message(role: .assistant, content: "첫번째 응답"),
            Message(role: .user, content: "두번째"),
            Message(role: .assistant, content: "두번째 응답"),
        ]
        let result = ConversationFormatter.format(
            history: history,
            newMessage: "세번째"
        )
        // 순서 확인: 첫번째 < 두번째 < 세번째
        let idx1 = result.range(of: "첫번째")!.lowerBound
        let idx2 = result.range(of: "두번째")!.lowerBound
        let idx3 = result.range(of: "세번째")!.lowerBound
        #expect(idx1 < idx2)
        #expect(idx2 < idx3)
    }
}
