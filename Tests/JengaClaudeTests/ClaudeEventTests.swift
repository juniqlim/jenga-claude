import Testing
import Foundation
@testable import JengaClaude

@Suite("ClaudeEvent Parsing")
struct ClaudeEventTests {

    @Test("system/init 메시지 파싱")
    func parseInitEvent() throws {
        let json = """
        {"type":"system","subtype":"init","session_id":"abc-123","tools":["Bash","Read"],"model":"claude-opus-4-6"}
        """
        let events = ClaudeEvent.parse(line: json)
        #expect(events.count == 1)
        guard case .`init`(let sessionId, let model) = events[0] else {
            Issue.record("Expected init event")
            return
        }
        #expect(sessionId == "abc-123")
        #expect(model == "claude-opus-4-6")
    }

    @Test("assistant 텍스트 메시지 파싱")
    func parseAssistantText() throws {
        let json = """
        {"type":"assistant","message":{"id":"msg_001","type":"message","role":"assistant","content":[{"type":"text","text":"Hello!"}],"model":"claude-opus-4-6","stop_reason":null},"session_id":"abc-123"}
        """
        let events = ClaudeEvent.parse(line: json)
        #expect(events.count == 1)
        guard case .assistant(let text) = events[0] else {
            Issue.record("Expected assistant event")
            return
        }
        #expect(text == "Hello!")
    }

    @Test("result 메시지 파싱")
    func parseResult() throws {
        let json = """
        {"type":"result","subtype":"success","is_error":false,"duration_ms":2500,"duration_api_ms":2400,"num_turns":1,"result":"Done!","session_id":"abc-123","total_cost_usd":0.04}
        """
        let events = ClaudeEvent.parse(line: json)
        #expect(events.count == 1)
        guard case .result(let text, let costUsd, let isError) = events[0] else {
            Issue.record("Expected result event")
            return
        }
        #expect(text == "Done!")
        #expect(costUsd == 0.04)
        #expect(isError == false)
    }

    @Test("tool_use 블록이 포함된 assistant 메시지 파싱")
    func parseToolUse() throws {
        let json = """
        {"type":"assistant","message":{"id":"msg_002","type":"message","role":"assistant","content":[{"type":"text","text":"Let me read that file."},{"type":"tool_use","id":"tool_001","name":"Read","input":{"file_path":"/tmp/test.ts"}}],"model":"claude-opus-4-6","stop_reason":null},"session_id":"abc-123"}
        """
        let events = ClaudeEvent.parse(line: json)
        #expect(events.count == 2)
        guard case .assistant(let text) = events[0] else {
            Issue.record("Expected assistant event")
            return
        }
        #expect(text == "Let me read that file.")
        guard case .toolUse(let toolName, let toolUseId, _) = events[1] else {
            Issue.record("Expected toolUse event")
            return
        }
        #expect(toolName == "Read")
        #expect(toolUseId == "tool_001")
    }

    @Test("잘못된 JSON 무시")
    func ignoreInvalidJSON() {
        let events = ClaudeEvent.parse(line: "not valid json")
        #expect(events.isEmpty)
    }

    @Test("빈 줄 무시")
    func ignoreEmptyLines() {
        #expect(ClaudeEvent.parse(line: "").isEmpty)
        #expect(ClaudeEvent.parse(line: "  ").isEmpty)
    }

    @Test("알 수 없는 타입은 unknown으로 파싱")
    func parseUnknownType() {
        let json = """
        {"type":"something_else","data":"value"}
        """
        let events = ClaudeEvent.parse(line: json)
        #expect(events.count == 1)
        guard case .unknown = events[0] else {
            Issue.record("Expected unknown event")
            return
        }
    }
}
