//
//  TestView.swift
//  TichuStats
//
//  Created by Leon on 13.10.2026.
//



import SwiftUI
import UIKit

struct TapContextMenu<Content: View, Preview: View>: UIViewRepresentable {
    let content: Content
    let preview: Preview
    let previewSize: CGSize?
    let actions: [UIMenuElement]
    let onCommit: (() -> Void)?

    init(previewSize: CGSize? = nil,
         actions: [UIMenuElement],
         onCommit: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content,
         @ViewBuilder preview: () -> Preview) {
        self.content = content()
        self.preview = preview()
        self.previewSize = previewSize
        self.actions = actions
        self.onCommit = onCommit
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        context.coordinator.host = host

        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        host.view.addInteraction(interaction)
        context.coordinator.interaction = interaction

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.tapped(_:)))
        host.view.addGestureRecognizer(tap)
        return host.view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.host?.rootView = content
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize? {
        context.coordinator.host?.sizeThatFits(in: CGSize(
            width: proposal.width ?? UIView.layoutFittingExpandedSize.width,
            height: proposal.height ?? UIView.layoutFittingExpandedSize.height))
    }

    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        var parent: TapContextMenu
        var host: UIHostingController<Content>?
        weak var interaction: UIContextMenuInteraction?

        init(_ parent: TapContextMenu) { self.parent = parent }

        @objc func tapped(_ g: UITapGestureRecognizer) {
            guard let interaction else { return }
            let sel = NSSelectorFromString("_presentMenuAtLocation:")
            if interaction.responds(to: sel) {
                interaction.perform(sel, with: NSValue(cgPoint: g.location(in: g.view)))
            }
        }

        func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                    configurationForMenuAtLocation location: CGPoint)
        -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: { [parent] in
                    let vc = UIHostingController(rootView: parent.preview)
                    if let size = parent.previewSize { vc.preferredContentSize = size }
                    return vc
                },
                actionProvider: { [parent] _ in UIMenu(children: parent.actions) }
            )
        }

        // Called when the user taps the preview itself
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                    willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
                                    animator: UIContextMenuInteractionCommitAnimating) {
            animator.addCompletion { [weak self] in
                self?.parent.onCommit?()
            }
        }
    }
}
