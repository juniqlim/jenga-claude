import SwiftUI
import AppKit

struct ChatView: View {
    @StateObject private var claude = ClaudeProcess()
    @State private var inputText = ""
    @State private var messages: [Message] = []
    @State private var streamingText = ""
    @AppStorage("fontSize") private var fontSize: Double = 14
    @State private var scrollProxy: NSScrollView?
    @State private var cursorIndex: Int?
    @State private var scrollMonitor: Any?

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
                Text(claude.workingDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
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
                Picker("", selection: $claude.selectedModel) {
                    Text("sonnet").tag("sonnet")
                    Text("opus").tag("opus")
                    Text("haiku").tag("haiku")
                }
                .labelsHidden()
                .fixedSize()
                Picker("", selection: $claude.effort) {
                    Text("low").tag("low")
                    Text("mid").tag("medium")
                    Text("high").tag("high")
                }
                .labelsHidden()
                .fixedSize()
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
                    ScrollViewFinder(scrollView: $scrollProxy)
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(messages.enumerated().reversed()), id: \.element.id) { index, message in
                            HStack(alignment: .top, spacing: 8) {
                                Text(message.content)
                                    .font(.system(size: fontSize))
                                    .foregroundColor(message.role == .user ? .secondary : .primary)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(message.role == .user
                                        ? Color.primary.opacity(0.06)
                                        : Color.primary.opacity(0.03))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(cursorIndex == index ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .opacity(message.isDisabled ? 0.3 : 1.0)
                            .overlay(
                                OptionClickOverlay {
                                    messages[index].isDisabled.toggle()
                                }
                            )
                        }

                        // 스트리밍 중인 응답
                        if !streamingText.isEmpty {
                            Text(streamingText)
                                .font(.system(size: fontSize))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.primary.opacity(0.03))
                                )
                                .id("streaming")
                        }
                    }
                    .padding(.vertical, 8)
                    .scaleEffect(x: 1, y: -1)
                }
                .scaleEffect(x: 1, y: -1)
                .onChange(of: streamingText) {
                    proxy.scrollTo("streaming", anchor: .top)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .top)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // 입력창
            TextField("메시지를 입력하세요...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: fontSize))
                .onSubmit { sendMessage() }
                .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(toggleShortcuts)
        .background(fontSizeShortcuts)
        .background(toggleAllShortcut)
        .onKeyPress(.escape) {
            guard claude.isRunning else { return .ignored }
            if !streamingText.isEmpty {
                messages.append(Message(role: .assistant, content: streamingText))
                streamingText = ""
            }
            claude.stop()
            return .handled
        }
        .onAppear {
            if CommandLine.arguments.count > 1 {
                claude.workingDirectory = CommandLine.arguments[1]
            }
            scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.modifierFlags.contains(.control),
                      (event.keyCode == 2 || event.keyCode == 32),
                      let sv = scrollProxy else { return event }
                let delta = fontSize * 1.4 * 10
                let clipView = sv.contentView
                var origin = clipView.bounds.origin
                if event.keyCode == 2 { // d (scaleEffect y:-1 반전)
                    origin.y = max(origin.y - delta, 0)
                } else { // u (scaleEffect y:-1 반전)
                    origin.y = min(origin.y + delta, (sv.documentView?.frame.height ?? 0) - clipView.bounds.height)
                }
                clipView.scroll(to: origin)
                sv.reflectScrolledClipView(clipView)
                return nil
            }
        }
        .onDisappear {
            if let monitor = scrollMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cycleModel)) { _ in
            switch claude.selectedModel {
            case "opus": claude.selectedModel = "sonnet"
            case "sonnet": claude.selectedModel = "haiku"
            default: claude.selectedModel = "opus"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cycleEffort)) { _ in
            switch claude.effort {
            case "low": claude.effort = "medium"
            case "medium": claude.effort = "high"
            default: claude.effort = "low"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleAll)) { _ in
            let allActive = messages.allSatisfy { !$0.isDisabled }
            for i in messages.indices {
                messages[i].isDisabled = allActive
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyActive)) { _ in
            copyMessages(activeOnly: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyAll)) { _ in
            copyMessages(activeOnly: false)
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

    @ViewBuilder
    private var toggleAllShortcut: some View {
        Button("") {
            guard !messages.isEmpty else { return }
            let current = cursorIndex ?? -1
            cursorIndex = min(current + 1, messages.count - 1)
        }
        .keyboardShortcut(.downArrow, modifiers: [.command, .shift])
        .hidden()
        Button("") {
            guard !messages.isEmpty else { return }
            let current = cursorIndex ?? 0
            cursorIndex = max(current - 1, 0)
        }
        .keyboardShortcut(.upArrow, modifiers: [.command, .shift])
        .hidden()
        Button("") {
            if let i = cursorIndex, i < messages.count {
                messages[i].isDisabled.toggle()
            }
        }
        .keyboardShortcut(.rightArrow, modifiers: [.command, .shift])
        .hidden()
        Button("") {
            if let i = cursorIndex, i < messages.count {
                messages[i].isDisabled.toggle()
            }
        }
        .keyboardShortcut(.leftArrow, modifiers: [.command, .shift])
        .hidden()
    }

    @ViewBuilder
    private var fontSizeShortcuts: some View {
        Button("") { fontSize = min(fontSize + 2, 40) }
            .keyboardShortcut("+", modifiers: .command)
            .hidden()
        Button("") { fontSize = max(fontSize - 2, 8) }
            .keyboardShortcut("-", modifiers: .command)
            .hidden()
    }

    private func copyMessages(activeOnly: Bool) {
        let text = Message.copyText(messages, activeOnly: activeOnly)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        if text == "/cl" {
            messages.removeAll()
            streamingText = ""
            claude.responseText = ""
            claude.hasResult = false
            cursorIndex = nil
            inputText = ""
            return
        }

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

/// Option+클릭만 가로채고 나머지 이벤트는 통과시키는 투명 오버레이
private struct OptionClickOverlay: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> OptionClickView {
        let view = OptionClickView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: OptionClickView, context: Context) {
        nsView.action = action
    }
}

private class OptionClickView: NSView {
    var action: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            action?()
        } else {
            super.mouseDown(with: event)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent,
              event.type == .leftMouseDown,
              event.modifierFlags.contains(.option) else {
            return nil  // Option 없으면 이벤트 통과
        }
        return super.hitTest(point)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .arrow)
    }
}

/// SwiftUI ScrollView 내부의 NSScrollView 참조를 캡처
private struct ScrollViewFinder: NSViewRepresentable {
    @Binding var scrollView: NSScrollView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.scrollView = view.enclosingScrollView
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
