import AppKit
import Quartz
import SwiftUI

/// Shows one attachment in the shared Quick Look panel. The panel looks for its controller along the responder
/// chain, so the pane hosts a `QuickLookResponderView` that hands it to this controller.
@MainActor
final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var previewURL: URL?
    /// The pane's responder; made first responder so the panel finds it.
    fileprivate weak var responder: QuickLookResponderNSView?

    /// Opens the panel on `url`, or shows `url` in it when it is already open.
    func preview(url: URL) {
        previewURL = url
        let panel: QLPreviewPanel = QLPreviewPanel.shared()
        if let responder, let window = responder.window {
            window.makeFirstResponder(responder)
        }
        if panel.dataSource === self {
            panel.reloadData()
        }
        panel.makeKeyAndOrderFront(nil)
    }

    fileprivate func beginControl(_ panel: QLPreviewPanel) {
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
    }

    fileprivate func endControl(_ panel: QLPreviewPanel) {
        panel.dataSource = nil
        panel.delegate = nil
    }

    nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        MainActor.assumeIsolated { previewURL == nil ? 0 : 1 }
    }

    nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        guard let url = MainActor.assumeIsolated({ previewURL }) else { return nil }
        return url as NSURL
    }
}

/// The pane's hook into the responder chain for the Quick Look panel; draws nothing.
struct QuickLookResponderView: NSViewRepresentable {
    let controller: QuickLookController

    func makeNSView(context: Context) -> QuickLookResponderNSView {
        let view = QuickLookResponderNSView()
        view.controller = controller
        controller.responder = view
        return view
    }

    func updateNSView(_ view: QuickLookResponderNSView, context: Context) {
        view.controller = controller
        controller.responder = view
    }
}

final class QuickLookResponderNSView: NSView {
    weak var controller: QuickLookController?

    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    nonisolated override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }

    nonisolated override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        MainActor.assumeIsolated { controller?.beginControl(panel) }
    }

    nonisolated override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        MainActor.assumeIsolated { controller?.endControl(panel) }
    }
}
