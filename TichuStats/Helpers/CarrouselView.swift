//
//  CarrouselView.swift
//  TichuStats
//
//  Created by Leon on 08.09.2026.
//  // Source - https://www.youtube.com/watch?v=VHaPYUWFTF8 Thanks man you are amazing 

import SwiftUI
import Combine

//MARK: - Card Struct
struct Card: Identifiable, Hashable {
    var id: String = UUID().uuidString
    let image: String
}

//MARK: - List of Cards
var cards: [Card] = [
    // Black
    .init(image: "card.black.10"),
    .init(image: "card.black.2"),
    .init(image: "card.black.3"),
    .init(image: "card.black.4"),
    .init(image: "card.black.5"),
    .init(image: "card.black.6"),
    .init(image: "card.black.7"),
    .init(image: "card.black.8"),
    .init(image: "card.black.9"),
    .init(image: "card.black.ace"),
    .init(image: "card.black.boy"),
    .init(image: "card.black.king"),
    .init(image: "card.black.queen"),

    // Blue
    .init(image: "card.blue.10"),
    .init(image: "card.blue.2"),
    .init(image: "card.blue.3"),
    .init(image: "card.blue.4"),
    .init(image: "card.blue.5"),
    .init(image: "card.blue.6"),
    .init(image: "card.blue.7"),
    .init(image: "card.blue.8"),
    .init(image: "card.blue.9"),
    .init(image: "card.blue.ace"),
    .init(image: "card.blue.boy"),
    .init(image: "card.blue.king"),
    .init(image: "card.blue.queen"),

    // Green
    .init(image: "card.green.10"),
    .init(image: "card.green.2"),
    .init(image: "card.green.3"),
    .init(image: "card.green.4"),
    .init(image: "card.green.5"),
    .init(image: "card.green.6"),
    .init(image: "card.green.7"),
    .init(image: "card.green.8"),
    .init(image: "card.green.9"),
    .init(image: "card.green.ace"),
    .init(image: "card.green.boy"),
    .init(image: "card.green.king"),
    .init(image: "card.green.queen"),

    // Red
    .init(image: "card.red.10"),
    .init(image: "card.red.2"),
    .init(image: "card.red.3"),
    .init(image: "card.red.4"),
    .init(image: "card.red.5"),
    .init(image: "card.red.6"),
    .init(image: "card.red.7"),
    .init(image: "card.red.8"),
    .init(image: "card.red.9"),
    .init(image: "card.red.ace"),
    .init(image: "card.red.boy"),
    .init(image: "card.red.king"),
    .init(image: "card.red.queen"),

    // Special
    .init(image: "card.dog"),
    .init(image: "card.dragon"),
    .init(image: "card.mahjong"),
    .init(image: "card.phoenix"),
]

//MARK: - Example how to use the Stuff
struct ExampleView: View {
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = 0
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()
    @State private var activeCard: Card? = cards.first
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = 0

    @ViewBuilder
    func AmbientBackground() -> some View {
        GeometryReader {
            let size = $0.size

            ZStack {
                ForEach(cards) { card in
                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: size.width, height: size.height)
                        //Only show active card
                        .opacity(activeCard?.id == card.id ? 1 : 0)
                }

                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 90, opaque: true)
            .ignoresSafeArea()
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground()
                .animation(.easeInOut(duration: 1), value: activeCard)

            VStack(spacing: 40) {
                InfiniteScrollView {
                    ForEach(cards) { card in
                        CarouselCardView(card)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollPosition($scrollPosition)
                .containerRelativeFrame(.vertical) { value, _ in
                    value * 0.45
                }
                .onScrollGeometryChange(for: CGFloat.self) {
                    $0.contentOffset.x + $0.contentInsets.leading
                } action: { oldValue, newValue in
                    currentScrollOffset = newValue

                    let activeIndex = Int((currentScrollOffset / 200).rounded()) % cards.count
                    activeCard = cards[activeIndex]
                }
                .visualEffect { [initialAnimation] content, proxy in
                    content
                        .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
                }

                VStack(alignment: .center) {
                    Text(String(localized:"login.welcomeTo"))
                        .foregroundStyle(.secondary)
                        .fontWeight(.bold)
                        .blurOpacityEffect(initialAnimation)
                    Text(String(localized:"login.title"))
                        .fontWeight(.bold)
                        .font(.system(size: 40))
                        .padding(.bottom, 10)
                        .textRenderer(TitleTextRenderer(progress: titleProgress))
                    Text(String(localized:"login.description"))
                        .multilineTextAlignment(.center)
                        .blurOpacityEffect(initialAnimation)
                        .foregroundStyle(.secondary)
                }
            }
            .safeAreaPadding(15)
        }
        .onReceive(timer) { _ in
            currentScrollOffset += 0.35
            scrollPosition.scrollTo(x: currentScrollOffset)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.35))

            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                initialAnimation = true
            }
            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                titleProgress = 1
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }
}


//MARK: - CarouselCardView of a single Card
@ViewBuilder
func CarouselCardView(_ card: Card) -> some View {
    GeometryReader {
        let size = $0.size

        Image(card.image)
            .resizable()
        //.fit for iphones
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.width*1.5384615385)
            .clipShape(.rect(cornerRadius: 18))
            .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
    }
    .frame(width: 200)
    .padding(.top,100)
    .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
        content
            .offset(y: phase == .identity ? -10 : 0)
            .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
    }
}
//MARK: - InfinteScrollView to Display all the Cards
struct InfiniteScrollView<Content: View>: View {
    var spacing: CGFloat = 20
    @ViewBuilder var content: Content
    @State private var contentSize: CGSize = .zero

    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    Group(subviews: content) { collection in
                        HStack(spacing: spacing) {
                            ForEach(collection) { view in
                                view
                            }
                        }
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            contentSize = .init(width: newValue.width + spacing, height: newValue.height)
                        }

                        let averageWidth = contentSize.width / CGFloat(collection.count)
                        let repeatingCount = contentSize.width > 0 ? Int((size.width / averageWidth).rounded()) + 1 : 1

                        HStack(spacing: spacing) {
                            ForEach(0..<repeatingCount, id: \.self) { index in
                                let view = Array(collection)[index % collection.count]
                                view
                            }
                        }
                    }
                }
                .background(InfiniteScrollHelper(contentSize: $contentSize, declarationRate: .constant(.fast)))
            }
        }
    }
}

//MARK: - UIKit Stuff
extension UIView {
    var scrollView: UIScrollView? {
        if let superview, superview is UIScrollView {
            return superview as? UIScrollView
        }
        return superview?.scrollView
    }
}

struct InfiniteScrollHelper: UIViewRepresentable {
    @Binding var contentSize: CGSize
    @Binding var declarationRate: UIScrollView.DecelerationRate

    func makeCoordinator() -> Coordinator {
        Coordinator(declarationRate: declarationRate, contentSize: contentSize)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let scrollView = view.scrollView {
                context.coordinator.defaultDelegate = scrollView.delegate
                scrollView.decelerationRate = declarationRate
                scrollView.delegate = context.coordinator
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.declarationRate = declarationRate
        context.coordinator.contentSize = contentSize
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var declarationRate: UIScrollView.DecelerationRate
        var contentSize: CGSize

        init(declarationRate: UIScrollView.DecelerationRate, contentSize: CGSize) {
            self.declarationRate = declarationRate
            self.contentSize = contentSize
        }

        weak var defaultDelegate: UIScrollViewDelegate?

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.decelerationRate = declarationRate

            let minX = scrollView.contentOffset.x

            if minX > contentSize.width {
                scrollView.contentOffset.x -= contentSize.width
            }
            if minX < 0 {
                scrollView.contentOffset.x += contentSize.width
            }

            defaultDelegate?.scrollViewDidScroll?(scrollView)
        }
    }
}

//MARK: Renders One Letter after the other
struct TitleTextRenderer: TextRenderer, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let slices = layout.flatMap({ $0 }).flatMap({ $0 })

        for (index, slice) in slices.enumerated() {
            let sliceProgressIndex = CGFloat(slices.count) * progress
            let sliceProgress = max(min(sliceProgressIndex / CGFloat(index + 1), 1), 0)

            /// If you want each slice to begin from its origin point, create a copy context for each loop, such as
            /// "var copy = context."
            /// However, I want the context to be incremented after each loop, so I'm using the context directly without
            /// copying!
            ctx.addFilter(.blur(radius: 5 - (5 * sliceProgress)))
            ctx.opacity = sliceProgress
            ctx.translateBy(x: 0, y: 5 - (5 * sliceProgress))
            ctx.draw(slice, options: .disablesSubpixelQuantization)
        }
    }
}

//MARK: - Animation
extension View {
    func blurOpacityEffect(_ show: Bool) -> some View {
        self
            .blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
}
#Preview {
    ExampleView()
}
