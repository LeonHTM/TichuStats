//
//  LoginSheetView.swift
//  TichuStats
//
//  Created by Leon on 06.09.2026.
//

import SwiftUI

struct LoginSheetView: View{

    @Binding var showLoginSheet:Bool
    @Binding var signIn: Bool
    var chosenName: String = ""

    // MARK: - Storage
    @StateObject private var socket = SocketService.shared
    @ObservedObject private var network = NetworkService.shared



    // MARK: - State
    @State private var userEmail: String = ""
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isEmailFocused: Bool
    @State private var isChecking:Bool = false
    @State private var alreadyExistsId: Int?
    @State private var showOfflineAlert: Bool = false
    @State private var isPasskeyLoading: Bool = false
    @State private var passkeyErrorMessage: String?
    @State private var showPasskeyError: Bool = false

    // MARK: - Email Field
    private var emailField: some View {
        HStack {
            Image(systemName: "envelope.fill")
                .foregroundColor(.secondary)
                .padding(.leading)

            TextField("\("me@tichuplayer.com")", text: $userEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .foregroundColor(.primary)
                .focused($isEmailFocused)
                .alert(isPresented:$showOfflineAlert){
                    OfflineView.offlineAlert()
                }
                .onChange(of: userEmail) {

                    if network.isOnline{
                        isChecking = true
                        Task {
                            alreadyExistsId = await network.checkEmail(email: userEmail)
                            isChecking = false
                        }
                    }
                    }
                

            Spacer()
            
            ZStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .opacity(0) // always reserves the space

                if isChecking {
                    ProgressView()
                } else {
                    if network.isOnline && socket.connected {
                        if alreadyExistsId == nil{
                            Button {
                                Task{
                                    if let id = await network.addProfile(email: userEmail, name: chosenName){
                                        _ = await network.login(userId: id)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.accentColor)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                isEmailFocused = false
                            })
                            .disabled(userEmail.isEmpty)
                        }else{
                            Button{
                                Task{
                                    await network.login(userId: alreadyExistsId!)
                                }

                            }label:{
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    } else {
                        Button {
                            showOfflineAlert = true
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .padding(.trailing, 10)
        }
        .padding(.vertical, 13)
        .glassEffect(.regular.tint(.secondary.opacity(0.2)).interactive())
    }
    
    private func passKeySignInButton() -> some View {
        Button {
            Task { await handlePasskeyTap(signIn: signIn) }
        } label: {
            HStack{
                Spacer()
                if isPasskeyLoading {
                    ProgressView()
                        .tint(colorScheme == .light ? Color.white : Color.black)
                } else {
                    Image(systemName:"person.badge.key.fill")
                    Text(String(localized:signIn ? "login.signInPasskey" : "login.signUpPasskey"))
                }
                Spacer()
            }.fontWeight(.semibold).font(.system(size: 18)).foregroundStyle(colorScheme == .light ? Color.white : Color.black).backgroundStyle(Color.black).frame(height: 50).clipShape(RoundedRectangle(cornerRadius: 24))
                .glassEffect(.regular.tint(colorScheme == .light ? .black : .white).interactive())
        }
        .disabled(isChecking || isPasskeyLoading)
    }

    // MARK: - Passkey Tap Handler
    private func handlePasskeyTap(signIn: Bool) async {
        guard network.isOnline else {
            showOfflineAlert = true
            return
        }

        isPasskeyLoading = true
        defer { isPasskeyLoading = false }

        
        do{
            if signIn == true{
                _ = try await network.signInWithPasskey(email: userEmail)
            } else if !chosenName.isEmpty {
                _ = try await network.signUpWithPasskey(name: chosenName,mail:userEmail)
                showLoginSheet = false
            } else {
                print("LOGIN ChosenNAME ERROR: \(chosenName)")
                showPasskeyError = true
                return
            }
        }catch PasskeyError.cancelled {
            
        } catch PasskeyError.server(let code) {
            passkeyErrorMessage = friendlyMessage(for: code)
            showPasskeyError = true
        } catch {
            passkeyErrorMessage =  String(localized:"passKeyError.general")
            showPasskeyError = true
        }
        
    }

    private func friendlyMessage(for code: String) -> String {
        switch code {
        case "challenge_expired":
            return String(localized:"passKeyError.expired")
        case "unknown_credential", "unknown_user":
            return String(localized:"passKeyError.unknown")
        case "verification_failed":
            return String(localized:"passKeyError.verfication")
        default:
            return String(localized:"passKeyError.general")
        }
    }
    var body: some View {
        NavigationStack{
            GlassEffectContainer {
                Spacer()
                
                VStack {
                    Text("")
                    emailField
                    
                    HStack {
                        Spacer()
                        Text(String(localized: "login.or"))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    
                    passKeySignInButton()
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle(signIn ? String(localized:"login.signIn") : String(localized:"login.signUp"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        showLoginSheet = false
                    }
                }
            }
            .alert("Passkey Sign In Failed", isPresented: $showPasskeyError, presenting: passkeyErrorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }
}
