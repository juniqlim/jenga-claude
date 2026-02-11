import Foundation

@MainActor
class ClaudeProcess: ObservableObject {
    @Published var sessionId: String?
    @Published var model: String?
    @Published var responseText: String = ""
    @Published var hasResult: Bool = false
    @Published var isRunning: Bool = false
    @Published var events: [ClaudeEvent] = []
    @Published var errorText: String = ""

    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutBuffer = ""
    private var stderrBuffer = ""

    func start() {
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
        self.stdinPipe = stdinP
        self.isRunning = true

        // stdout 비동기 읽기
        stdoutP.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.processStdout(chunk)
            }
        }

        // stderr 비동기 읽기
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
        } catch {
            isRunning = false
            errorText = "Failed to start claude: \(error.localizedDescription)"
        }
    }

    private func processStdout(_ chunk: String) {
        stdoutBuffer += chunk
        let lines = stdoutBuffer.split(separator: "\n", omittingEmptySubsequences: false)
        stdoutBuffer = String(lines.last ?? "")
        let completeLines = lines.dropLast()
        for line in completeLines {
            let parsed = ClaudeEvent.parse(line: String(line))
            for event in parsed {
                events.append(event)
                switch event {
                case .`init`(let sid, let m):
                    sessionId = sid
                    model = m
                case .assistant(let text):
                    responseText += text
                case .toolUse(let toolName, _, _):
                    responseText += "\n[Tool: \(toolName)]"
                case .result(_, _, _):
                    hasResult = true
                case .unknown:
                    break
                }
            }
        }
    }

    func send(message: String) {
        guard let stdinPipe else { return }
        let payload: [String: Any] = [
            "type": "user",
            "message": ["role": "user", "content": message],
            "session_id": sessionId ?? "default",
            "parent_tool_use_id": NSNull(),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonStr = String(data: data, encoding: .utf8)
        else { return }
        let line = jsonStr + "\n"
        stdinPipe.fileHandleForWriting.write(line.data(using: .utf8)!)
    }

    func stop() {
        process?.terminate()
        process = nil
        stdinPipe = nil
        isRunning = false
    }
}
