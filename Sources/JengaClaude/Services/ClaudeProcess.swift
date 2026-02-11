import Foundation

@MainActor
class ClaudeProcess: ObservableObject {
    @Published var model: String?
    @Published var responseText: String = ""
    @Published var hasResult: Bool = false
    @Published var isRunning: Bool = false
    @Published var errorText: String = ""

    private var process: Process?

    func send(message: String, history: [Message] = []) {
        // 이전 프로세스가 있으면 종료
        process?.terminate()

        let proc = Process()
        let stdinP = Pipe()
        let stdoutP = Pipe()
        let stderrP = Pipe()

        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = [
            "claude",
            "--print",
            "--output-format", "stream-json",
            "--input-format", "stream-json",
            "--verbose",
        ]
        proc.standardInput = stdinP
        proc.standardOutput = stdoutP
        proc.standardError = stderrP

        self.process = proc
        self.responseText = ""
        self.hasResult = false
        self.isRunning = true
        self.errorText = ""

        var stdoutBuffer = ""

        stdoutP.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                stdoutBuffer += chunk
                let lines = stdoutBuffer.split(separator: "\n", omittingEmptySubsequences: false)
                stdoutBuffer = String(lines.last ?? "")
                for line in lines.dropLast() {
                    let parsed = ClaudeEvent.parse(line: String(line))
                    for event in parsed {
                        switch event {
                        case .`init`(_, let m):
                            self.model = m
                        case .assistant(let text):
                            self.responseText += text
                        case .toolUse(let toolName, _, _):
                            self.responseText += "\n[Tool: \(toolName)]"
                        case .result(_, _, _):
                            self.hasResult = true
                            self.isRunning = false
                            self.process?.terminate()
                            self.process = nil
                        case .unknown:
                            break
                        }
                    }
                }
            }
        }

        stderrP.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.errorText += chunk
            }
        }

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isRunning = false
            }
        }

        do {
            try proc.run()
            // 히스토리를 포함한 프롬프트 생성
            let fullMessage = ConversationFormatter.format(history: history, newMessage: message)
            let payload: [String: Any] = [
                "type": "user",
                "message": ["role": "user", "content": fullMessage],
                "session_id": "default",
                "parent_tool_use_id": NSNull(),
            ]
            if let data = try? JSONSerialization.data(withJSONObject: payload),
               let jsonStr = String(data: data, encoding: .utf8) {
                stdinP.fileHandleForWriting.write((jsonStr + "\n").data(using: .utf8)!)
            }
        } catch {
            isRunning = false
            errorText = "Failed to start claude: \(error.localizedDescription)"
        }
    }

    func stop() {
        process?.terminate()
        process = nil
        isRunning = false
    }
}
