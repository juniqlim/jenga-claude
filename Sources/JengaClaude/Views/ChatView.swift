import SwiftUI

struct ChatView: View {
    @StateObject private var claude = ClaudeProcess()
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var streamingText = ""

    var body: some View {
        VStack(spacing: 0) {
            // 상태 표시
            HStack {
                Circle()
                    .fill(claude.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(claude.isRunning ? "응답 중..." : "대기")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !claude.errorText.isEmpty {
                    Text("stderr: \(claude.errorText.prefix(100))")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            Divider()

            // 메시지 목록
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            MessageView(message: message)
                        }
                        if !streamingText.isEmpty {
                            HStack {
                                Text(streamingText)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                            .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: streamingText) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            // 입력창
            HStack {
                TextField("메시지를 입력하세요...", text: $inputText)
                    .textFieldStyle(.plain)
                    .onSubmit { sendMessage() }
                Button("전송") { sendMessage() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .onChange(of: claude.responseText) {
            if !claude.responseText.isEmpty {
                streamingText = claude.responseText
            }
        }
        .onChange(of: claude.hasResult) {
            if claude.hasResult && !streamingText.isEmpty {
                messages.append(Message(role: .assistant, content: streamingText))
                streamingText = ""
                claude.responseText = ""
                claude.hasResult = false
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(Message(role: .user, content: text))
        claude.send(message: text)
        inputText = ""
        streamingText = ""
    }
}
