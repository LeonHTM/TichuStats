import SwiftUI
import AuthenticationServices
import Combine




struct WelcomeView: View {
    
    //MARK: Observed
    @ObservedObject private var network = NetworkService.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    //MARK: Logic
    @Binding var showLoginSheet: Bool
    @Binding var signIn: Bool
    @Binding var chosenName: String
    @Binding var userEmail: String
    @State private var showOfflineAlert: Bool = false
    
    //MARK: Visuals
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = 0
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()
    @State private var activeCard: Card? = cards.first
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = 0
    
    
    //MARK: Ambient Background: A
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
                        //Only Showing active Card Image
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

    //MARK: Body
    var body: some View {
        GlassEffectContainer {
            ZStack{
                //Not sure about the Ambient Background
                /*AmbientBackground()
                    .animation(.easeInOut(duration:1), value: activeCard)*/
                VStack{
                    VStack(spacing: 40) {
                        InfiniteScrollView {
                            ForEach(cards) { card in
                                CarouselCardView(card)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .scrollPosition($scrollPosition)
                        .containerRelativeFrame(.vertical) { value, _ in
                            value * 0.60
                        }
                        .onScrollGeometryChange(for: CGFloat.self) {
                            $0.contentOffset.x + $0.contentInsets.leading
                        } action: { oldValue, newValue in
                            currentScrollOffset = newValue
                            
                            let activeIndex = Int((currentScrollOffset/200).rounded()) % cards.count
                            activeCard = cards[activeIndex]
                        }
                        .visualEffect { [initialAnimation] content, proxy in
                            content
                                .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
                        }
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
                        withAnimation(.smooth(duration:0.25,extraBounce:0)){
                            titleProgress = 1
                        }
                    }
                    
                    //MARK: Title and Subtilte
                    VStack(alignment:.center){
                        Text(String(localized:"login.welcomeTo")).foregroundStyle(.secondary).fontWeight(.bold).blurOpacityEffect(initialAnimation)
                        Text(String(localized:"login.title")).fontWeight(.bold).font(.system(size:40)).padding(.bottom,10).textRenderer(TitleTextRenderer(progress: titleProgress))
                        Text(String(localized: "login.description")).multilineTextAlignment(.center).blurOpacityEffect(initialAnimation)
                            .foregroundStyle(.secondary)
                    }.padding(.bottom,20).padding(.horizontal)
                    
                    //MARK: Buttons
                    VStack {
                        NavigationButton(
                            title: String(localized: "login.getStarted"),
                            icon: nil,
                            primary: true,
                            animation: $initialAnimation
                        
                        ) {
                            if network.isOnline {
                                EditNameSheetView(
                                    editMode: false,
                                    showLoginSheet: $showLoginSheet,
                                    signIn: $signIn,
                                    chosenName: $chosenName
                                ).onAppear{
                                    userEmail = ""
                                }
                            } else {
                                OfflineView(
                                    showNavBar: .constant(false)
                                )
                            }
                        }
                        
                        Button {
                            if network.isOnline{
                                signIn = true
                                showLoginSheet = true
                            }else{
                                showOfflineAlert = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text(String(localized: "login.alreadyHave")).blurOpacityEffect(initialAnimation)
                                Spacer()
                            }
                            .fontWeight(.semibold)
                            .font(.system(size: 18))
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .foregroundStyle(
                                colorScheme == .dark ? Color.black : Color.white
                            )
                            .glassEffect(
                                .regular.tint(
                                    colorScheme == .dark
                                    ? Color.white
                                    : Color.primary
                                ).interactive()
                            )
                        }
                    }.alert(isPresented:$showOfflineAlert){
                        OfflineView.offlineAlert()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }.onAppear{
            cards.shuffle()
            timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
       
    }
}


//MARK: - LoginView Manages all the differnt Views for the Login
struct LoginView: View {
    //MARK: Variables
    @State private var showLoginSheet: Bool = false
    @State private var signIn: Bool = true
    @State private var chosenName: String = ""
    @State private var showCodeView: Bool = false
    @State private var firstAppear: Bool = true
    @State private var userEmail: String = ""
    @ObservedObject private var network = NetworkService.shared

    //MARK: BOdy
    var body: some View {
        NavigationStack {
            WelcomeView(
                showLoginSheet: $showLoginSheet,
                signIn: $signIn,
                chosenName: $chosenName,
                userEmail: $userEmail
            ).onChange(of:network.isOnline){
                if network.isOnline == false {
                    showLoginSheet = false
                }
            }
            .navigationTitle(String(localized: "login.title"))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(
                isPresented: $showLoginSheet,
                onDismiss: {
                    firstAppear = true
                    
                }
            ) {
                NavigationStack{ 
                ZStack {
                    if showCodeView {
                        CodeView(
                            userEmail: $userEmail,
                            showCodeView: $showCodeView,
                            showLoginSheet: $showLoginSheet,
                            firstAppear: $firstAppear,
                            userName: $chosenName
                        )
                        
                        .transition( showCodeView == true ?
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ): .identity
                        )
                    } else {
                        LoginSheetView(
                            showLoginSheet: $showLoginSheet,
                            showCodeView: $showCodeView,
                            signIn: $signIn,
                            firstAppear: $firstAppear,
                            userEmail: $userEmail,
                            chosenName: chosenName
                        )
                        
                    }
                }.navigationTitle(signIn ? String(localized:"login.signIn") : String(localized:"login.signUp"))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel", systemImage: "xmark") {
                                    showLoginSheet = false
                                }
                            }
                        }
            }
                
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                //breaks the focus stats Autofill will break
                /*.animation(
                    .easeInOut(duration: 0.3),
                    value: showCodeView
                )*/
                .presentationDetents([.height(250)])
            }
        }
        .onChange(of: chosenName) {
            print(chosenName)
        }
    }
}




