//
//  EditNameSheetView.swift
//  Tichu
//
//  Created by Leon on 21.04.2026.
//

import SwiftUI
import Combine
struct EditNameSheetView: View {

    // MARK: - Bindings
    @Environment(\.dismiss) private var dismiss
    
    var editMode: Bool
    
    @ObservedObject private var network = NetworkService.shared
    @FocusState private var isTextFocused: Bool

    // MARK: - Storage
    @AppStorage("userId") private var userId: Int = -69420
    @AppStorage("userNameTiming") private var userNametiming: Double = 0
    
    // MARK: - State
    @State private var isAvailable: Bool = false
    @State private var isCheckingAvailability: Bool = false
    @Binding var showLoginSheet:Bool
    @Binding var signIn:Bool
    @Binding var chosenName: String
    
    @State private var now: Date = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    private var downTime: Double {
        let date = Date(timeIntervalSince1970: userNametiming)
        return date.timeIntervalSince(now)
    }
    // MARK: - Validation
    private var isLengthValid: Bool {
        let count = chosenName.count
        return count >= 2 && count <= 20
    }

    private var isCharsetValid: Bool {
        !chosenName.isEmpty &&
        chosenName.wholeMatch(of: /^[\p{L}\p{N}_]+$/) != nil
    }
    
    private var isNotGuest: Bool {
        chosenName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "guest"
    }

    
    private var isAllValid: Bool {
        isLengthValid && isCharsetValid && isAvailable && isNotGuest
    }
    
    private var isAllValidEdit: Bool {
        isLengthValid && isCharsetValid && isAvailable && isNotGuest && downTime <= 0
    }
    
    
    private var downTimeFormatted: String {
        let seconds = Int(downTime)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    var body: some View {
        NavigationStack {
            
            Form {
                Section {
                    TextField(String(localized: "username.enter"), text: $chosenName)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($isTextFocused)
                        .onAppear{
                            isTextFocused = true
                        }
                }

                Section(String(localized: "username.requirements")) {
                    requirementRow(
                        text: String(localized: "username.requirements.length"),
                        isValid: isLengthValid
                    )
                    requirementRow(
                        text: String(localized: "username.requirements.letters"),
                        isValid: isCharsetValid
                    )
                    HStack {
                        requirementRow(
                            text: chosenName == network.profiles.first { $0.id == userId }?.name ?? String(localized: "general.unknown") ? String(localized: "username.old") : String(localized: "username.available"),
                            isValid: isAvailable
                        )
                        if isCheckingAvailability {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                if downTime > 0 && editMode == true{
                    Section{
                        
                        
                        HStack{
                            Spacer()
                            Text(String(format:String(localized: "username.change"),String(downTimeFormatted))).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            Spacer()
                        }
                        
                    }.listRowBackground(Color.clear).onReceive(timer) { date in
                        now = date
                    }
                }
            }.listSectionSpacing(0).safeAreaInset(edge:.bottom){
                if editMode == false{
                    Button{
                        chosenName = chosenName.trimmingCharacters(in: .whitespacesAndNewlines)
                        signIn = false
                        showLoginSheet = true
                        
                    }label:{
                        HStack{
                            Spacer()
                            Text(String(localized:"login.continue"))
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                            Spacer()
                        }
                    }.foregroundStyle(.primary).padding().glassEffect(.regular.tint(Color.accentColor).interactive()).padding(.horizontal,10).disabled(!isAllValid).padding(.bottom,10)
                }else{
                    Button{
                        let name = chosenName.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task{
                            await network.updateUsername(profileId:userId,name:name)
                            userNametiming = Date().timeIntervalSince1970 + (24 * 60 * 60)
                            dismiss()
                        }
                    }label:{
                        HStack{
                            Spacer()
                            Text(String(localized:"general.alert.save"))
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary).padding().glassEffect(.regular.tint(Color.accentColor).interactive()).padding(.horizontal,10).disabled(!isAllValidEdit).padding(.bottom,10)
                }
            }
            .navigationTitle(editMode == true ? String(localized: "username.edit") : String(localized: "username.create"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) {
                Text(String(localized: "username.description"))
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    .padding(.bottom, -10)
            }
            .onChange(of: chosenName) {
                if isLengthValid && isCharsetValid{
                    isAvailable = false
                    guard isLengthValid && isCharsetValid else { return }
                    isCheckingAvailability = true
                    Task {
                        isAvailable = await network.checkUsername(username: chosenName)
                        isCheckingAvailability = false
                    }
                }
            }
            
        }
        .onAppear {
            if editMode == true{
                chosenName = network.profiles.first { $0.id == userId }?.name ?? String(localized: "general.unknown")
            }
        }
    }
}

#Preview {
    EditNameSheetView(editMode: false,showLoginSheet:.constant(false),signIn: .constant(false), chosenName: .constant(""))
}
