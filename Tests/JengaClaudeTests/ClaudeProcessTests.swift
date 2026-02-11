import Testing
import Foundation
@testable import JengaClaude

// 통합 테스트: CLAUDE_INTEGRATION_TEST=1 환경변수가 설정된 경우에만 실행
@Suite("ClaudeProcess Integration", .tags(.integration),
       .enabled(if: ProcessInfo.processInfo.environment["CLAUDE_INTEGRATION_TEST"] != nil))
@MainActor
struct ClaudeProcessTests {

    @Test("메시지 전송 및 응답 수신")
    func sendMessageAndReceiveResponse() async throws {
        let process = ClaudeProcess()
        process.send(message: "Say exactly: PONG")

        let sendTime = Date()
        while !process.hasResult && Date().timeIntervalSince(sendTime) < 30 {
            try await Task.sleep(for: .milliseconds(100))
        }

        #expect(process.hasResult)
        #expect(process.responseText.contains("PONG"))

        process.stop()
    }
}

extension Tag {
    @Tag static var integration: Self
}
