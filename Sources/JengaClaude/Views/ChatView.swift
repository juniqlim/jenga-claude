import SwiftUI
import AppKit

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
                Button("활성만 복사") { copyMessages(activeOnly: true) }
                    .font(.caption)
                Button("전체 복사") { copyMessages(activeOnly: false) }
                    .font(.caption)
                Toggle("전체 권한", isOn: $claude.skipPermissions)
                    .toggleStyle(.switch)
                    .font(.caption)
                    .controlSize(.mini)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            Divider()

            // 메시지 목록 (체크박스 + 개별 메시지)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            HStack(alignment: .top, spacing: 8) {
                                Toggle("", isOn: Binding(
                                    get: { !messages[index].isDisabled },
                                    set: { messages[index].isDisabled = !$0 }
                                ))
                                .toggleStyle(.checkbox)
                                .labelsHidden()

                                if index < 9 {
                                    Text("⌘\(index + 1)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(message.role == .user ? "나" : "Claude")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(message.content)
                                        .font(.body)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .opacity(message.isDisabled ? 0.3 : 1.0)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                messages[index].isDisabled.toggle()
                            }
                        }

                        // 스트리밍 중인 응답
                        if !streamingText.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Claude")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(streamingText)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .id("streaming")
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: streamingText) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        .background(toggleShortcuts)
        .onKeyPress(.escape) {
            guard claude.isRunning else { return .ignored }
            if !streamingText.isEmpty {
                messages.append(Message(role: .assistant, content: streamingText))
                streamingText = ""
            }
            claude.stop()
            return .handled
        }
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

    @ViewBuilder
    private var toggleShortcuts: some View {
        ForEach(0..<9, id: \.self) { i in
            Button("") {
                if i < messages.count {
                    messages[i].isDisabled.toggle()
                }
            }
            .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: .command)
            .hidden()
        }
    }

    private func copyMessages(activeOnly: Bool) {
        let text = Message.copyText(messages, activeOnly: activeOnly)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        if !streamingText.isEmpty {
            messages.append(Message(role: .assistant, content: streamingText))
            streamingText = ""
            claude.responseText = ""
            claude.hasResult = false
        }

        let history = messages.filter { !$0.isDisabled }
        messages.append(Message(role: .user, content: text))
        claude.send(message: text, history: history)
        inputText = ""
    }
}
