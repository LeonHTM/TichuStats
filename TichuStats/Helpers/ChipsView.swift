//
//  ChipsView.swift
//  Tichu
//
//  Created by Leon on 23.04.2026.
//
// Based on https://www.youtube.com/watch?v=T82izB2XBMA

import SwiftUI

//MARK: - ChipsView used in StatsView
struct ChipsView<Content: View, Tag: Hashable>: View {
    //MARK: Variables
    var tags: [Tag]
    var spacing: CGFloat = 10
    var animation: Animation = .easeInOut(duration: 0.2)
    var onlyOne: Bool = false
    @ViewBuilder var content: (Tag, Bool) -> Content
    var didChangeSelection: ([Tag]) -> ()
    @State private var selectedTags: [Tag] = []
    //MARK: BODY
    var body: some View {
        GlassEffectContainer {
            CustomChipLayout(spacing: spacing) {
                ForEach(tags, id: \.self) { tag in
                    content(tag, selectedTags.contains(tag))
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(animation) {
                                if onlyOne {
                                    if selectedTags.contains(tag) {
                                        if let first = tags.first {
                                            //selectedTags = [first]
                                        }
                                    } else {
                                        selectedTags = [tag]
                                    }
                                } else {
                                    if selectedTags.contains(tag) {
                                        selectedTags.removeAll(where: { $0 == tag })
                                    } else {
                                        
                                        selectedTags.append(tag)
                                    }
                                }
                            }
                            didChangeSelection(selectedTags)
                        }
                }
            }
        }
        .onAppear {
            if onlyOne && selectedTags.isEmpty, let first = tags.first {
                selectedTags = [first]
                didChangeSelection(selectedTags)
            }
        }
    }
}

// MARK: - Custom Layout for Chips
//Calculates Layout for the Chips
fileprivate struct CustomChipLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return .init(width: width, height: maxHeight(proposal: proposal, subviews: subviews))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)
            if (origin.x + fitSize.width) > bounds.maxX {
                origin.x = bounds.minX
                origin.y += fitSize.height + spacing
            }
            subview.place(at: origin, proposal: proposal)
            origin.x += fitSize.width + spacing
        }
    }

    private func maxHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var origin: CGPoint = .zero
        for (index, subview) in subviews.enumerated() {
            let fitSize = subview.sizeThatFits(proposal)
            if (origin.x + fitSize.width) > (proposal.width ?? 0) {
                origin.x = 0
                origin.y += fitSize.height + spacing
            }
            origin.x += fitSize.width + spacing
            if index == subviews.count - 1 {
                origin.y += fitSize.height
            }
        }
        return origin.y
    }
}

// MARK: - Chip View
//View for the Single Chips, gets called by Chipsview
struct ChipView: View {
    let tag: String
    let isSelected: Bool
    let showAlert: Bool
    @State private var showOfflineAlert: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .foregroundStyle(isSelected ? .white : .primary)
                .alert(isPresented: $showOfflineAlert) {
                    OfflineView.offlineAlert()
                }
                .onChange(of: isSelected) { _, _ in
                    if showAlert == true {
                        showOfflineAlert = true
                    }
                }
            //Show Checkmark if Selected
            /*if isSelected && (showAlert == false) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            }*/
        }
        .padding(12)
        .glassEffect(isSelected && showAlert == false ? .regular.tint(.accentColor).interactive() : .regular.interactive())
    }
}

