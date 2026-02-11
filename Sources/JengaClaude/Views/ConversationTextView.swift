import SwiftUI
import AppKit

struct ConversationTextView: NSViewRepresentable {
    let messages: [Message]
    let streamingText: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 12, height: 12)

        // NSTextView가 ScrollView 너비에 맞춰 텍스트를 줄바꿈하도록 설정
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0,  // widthTracksTextView가 실제 너비를 결정
            height: CGFloat.greatestFiniteMagnitude
        )

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let attributed = MessageAttributedStringBuilder.build(
            messages: messages,
            streamingText: streamingText
        )

        textView.textStorage?.setAttributedString(attributed)

        // 하단 자동 스크롤
        DispatchQueue.main.async {
            textView.scrollToEndOfDocument(nil)
        }
    }
}
