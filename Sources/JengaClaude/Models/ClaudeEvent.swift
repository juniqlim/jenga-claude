import Foundation

enum ClaudeEvent: Equatable {
    case `init`(sessionId: String, model: String)
    case assistant(text: String)
    case toolUse(toolName: String, toolUseId: String, input: [String: String])
    case result(text: String, costUsd: Double, isError: Bool)
    case unknown(raw: String)

    static func parse(line: String) -> [ClaudeEvent] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String
        else { return [] }

        switch type {
        case "system":
            guard let subtype = json["subtype"] as? String, subtype == "init",
                  let sessionId = json["session_id"] as? String,
                  let model = json["model"] as? String
            else { return [.unknown(raw: trimmed)] }
            return [.`init`(sessionId: sessionId, model: model)]

        case "assistant":
            guard let message = json["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]]
            else { return [.unknown(raw: trimmed)] }
            var events: [ClaudeEvent] = []
            for block in content {
                guard let blockType = block["type"] as? String else { continue }
                switch blockType {
                case "text":
                    if let text = block["text"] as? String {
                        events.append(.assistant(text: text))
                    }
                case "tool_use":
                    if let name = block["name"] as? String,
                       let id = block["id"] as? String {
                        let input = (block["input"] as? [String: Any])?.compactMapValues { $0 as? String } ?? [:]
                        events.append(.toolUse(toolName: name, toolUseId: id, input: input))
                    }
                default:
                    break
                }
            }
            return events.isEmpty ? [.unknown(raw: trimmed)] : events

        case "result":
            let text = json["result"] as? String ?? ""
            let costUsd = json["total_cost_usd"] as? Double ?? 0
            let isError = json["is_error"] as? Bool ?? false
            return [.result(text: text, costUsd: costUsd, isError: isError)]

        default:
            return [.unknown(raw: trimmed)]
        }
    }
}
