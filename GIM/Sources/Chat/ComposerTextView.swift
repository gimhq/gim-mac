import AppKit
import SwiftUI

/// The composer's plain-text input: Return sends, Shift+Return or Option+Return inserts a newline, Up arrow in an
/// empty input edits the last own message. Grows from one to `maxLines` lines, then scrolls.
struct ComposerTextView: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    /// Increment to move the keyboard focus into the input.
    let focusRequest: Int
    let onSend: () -> Void
    let onEditLastMessage: () -> Void
    let onPasteImage: (Data) -> Void

    static let maxLines = 8
    static let inset = NSSize(width: 8, height: 6)

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = ComposerNSTextView(usingTextLayoutManager: false)
        textView.isRichText = false
        textView.importsGraphics = false
        textView.usesFontPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.allowsUndo = true
        textView.font = NSFont.preferredFont(forTextStyle: .body)
        textView.textContainerInset = Self.inset
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        textView.delegate = context.coordinator
        textView.coordinator = context.coordinator

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        guard let textView = scrollView.documentView as? ComposerNSTextView else { return }
        textView.placeholder = placeholder
        textView.isEditable = isEnabled
        textView.isSelectable = isEnabled
        if textView.string != text, !textView.hasMarkedText() {
            textView.string = text
            textView.needsDisplay = true
        }
        if coordinator.focusRequest != focusRequest {
            coordinator.focusRequest = focusRequest
            textView.requestFocus()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView scrollView: NSScrollView, context: Context) -> CGSize? {
        guard let textView = scrollView.documentView as? NSTextView,
            let layoutManager = textView.layoutManager, let container = textView.textContainer,
            let font = textView.font
        else { return nil }
        let width = proposal.width ?? scrollView.frame.width
        if width > 0 {
            container.size.width = max(width - 2 * Self.inset.width, 1)
        }
        layoutManager.ensureLayout(for: container)
        let lineHeight = layoutManager.defaultLineHeight(for: font)
        let usedHeight = layoutManager.usedRect(for: container).height
        let contentHeight = min(max(usedHeight, lineHeight), lineHeight * CGFloat(Self.maxLines))
        return CGSize(width: width, height: ceil(contentHeight + 2 * Self.inset.height))
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ComposerTextView
        /// The last `focusRequest` acted on.
        var focusRequest = 0

        init(parent: ComposerTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            textView.enclosingScrollView?.invalidateIntrinsicContentSize()
        }
    }
}

/// The text view behind `ComposerTextView`: key rules, image paste and the placeholder.
final class ComposerNSTextView: NSTextView {
    weak var coordinator: ComposerTextView.Coordinator?
    var placeholder = "" {
        didSet {
            if placeholder != oldValue { needsDisplay = true }
        }
    }
    /// Focus was requested before the view had a window.
    private var wantsFocus = false

    func requestFocus() {
        guard let window else {
            wantsFocus = true
            return
        }
        wantsFocus = false
        window.makeFirstResponder(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if wantsFocus { requestFocus() }
    }

    override func keyDown(with event: NSEvent) {
        guard !hasMarkedText(), let parent = coordinator?.parent else {
            super.keyDown(with: event)
            return
        }
        switch ComposerKeyRule.action(
            keyCode: event.keyCode, modifiers: event.modifierFlags, isTextEmpty: string.isEmpty)
        {
        case .send:
            parent.onSend()
        case .newline:
            insertNewlineIgnoringFieldEditor(nil)
        case .editLastMessage:
            parent.onEditLastMessage()
        case .passThrough:
            super.keyDown(with: event)
        }
    }

    /// Images on the pasteboard go to `onPasteImage`; anything else is pasted as plain text.
    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        if let parent = coordinator?.parent,
            let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)
        {
            parent.onPasteImage(data)
            return
        }
        super.paste(sender)
    }

    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, !placeholder.isEmpty else { return }
        let padding = textContainer?.lineFragmentPadding ?? 0
        let origin = NSPoint(x: textContainerOrigin.x + padding, y: textContainerOrigin.y)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.preferredFont(forTextStyle: .body),
            .foregroundColor: NSColor.placeholderTextColor,
        ]
        NSAttributedString(string: placeholder, attributes: attributes).draw(at: origin)
    }
}
