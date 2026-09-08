import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @ObservedObject private var network = NetworkService.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme

    @Binding var showLoginSheet: Bool
    @Binding var signIn: Bool
    @Binding var chosenName: String
    
    @State private var showOfflineAlert: Bool = false

    var body: some View {
        GlassEffectContainer {
            Spacer()

            VStack {
                Image("AppLogo")
                    .resizable()
                    .frame(width: 100, height: 100)

                Text(String(localized: "login.title"))
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack {
                Text(String(localized: "login.description"))
                    .foregroundStyle(.secondary)

                NavigationButton(
                    title: String(localized: "login.getStarted"),
                    icon: nil,
                    primary: true
                ) {
                    if network.isOnline {
                        EditNameSheetView(
                            editMode: false,
                            showLoginSheet: $showLoginSheet,
                            signIn: $signIn,
                            chosenName: $chosenName
                        )
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
                        Text(String(localized: "login.alreadyHave"))
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
}

struct LoginView: View {
    @State private var showLoginSheet: Bool = false
    @State private var signIn: Bool = true
    @State private var chosenName: String = ""
    @State private var showCodeView: Bool = false
    @State private var firstAppear: Bool = true
    @State private var userEmail: String = ""
    @ObservedObject private var network = NetworkService.shared

    var body: some View {
        NavigationStack {
            WelcomeView(
                showLoginSheet: $showLoginSheet,
                signIn: $signIn,
                chosenName: $chosenName
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


