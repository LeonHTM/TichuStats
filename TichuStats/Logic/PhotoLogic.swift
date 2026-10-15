//
// PhotoLogic.swift
//  TichuStats
//
//  Created by Leon on 22.04.2026.
//

import Foundation
import SwiftUI
import UIKit
import LinkPresentation

//MARK: - dataToPhoto used to translate from stored data do UIImage used in ProfileIamge
func dataToPhoto(data: Data?) -> UIImage? {
   
    if let data,
       let image = UIImage(data: data) {
        return image
    }
    return nil
}
            
//MARK: - ProfileImage render photo from UIImage + Fallback if no photo exists used in NavigationProfileImage, ShareSats, AddPlayersSheetview, EditFriendsSheetView, HistoryView, PlayView, ProfileView and StatsView
@ViewBuilder
func ProfileImage(data: Data?, size: Int) -> some View {
    
    let size = CGFloat(size)
    if let data, let uiImage = dataToPhoto(data: data) {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    } else {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

//MARK: - NavigationsProfileImage used in the NavigationBar in PlayView, HistoryView, StatsView and ProfileView
struct NavigationProfileImage: View {
    //MARK: Vars
    @AppStorage("userImageData") var userImageData: Data?
    @AppStorage("selectedTab") var selectedTab: Int?
    @AppStorage("userId") var userId: Int?
    //MARK: Body
    var body: some View {
        //Button switches to ProfileView
        Button {
            selectedTab = 3
        } label: {
            ProfileImage(data: userImageData, size: 44)
        }
        .frame(width: 44, height: 44)
        //Makes sure that the Preview is a circle
        .contentShape(.contextMenuPreview,.circle)
        .contextMenu{
            if NetworkService.shared.isOnline == true{
                Button{
                    if SocketService.shared.connected{
                        Task {
                            if let id = userId{
                                await NetworkService.shared.logout(profileId: id)
                            }
                        }
                    }
                }label:{
                    Image(systemName:"rectangle.portrait.and.arrow.right.fill")
                    Text(String(localized : "general.logout"))
                }
            }
        }
               
    }
}

//MARK: - GuestImageView used in PlayView to show random ProfileImage for Guest
struct GuestImageView: View {
    //MARK: Vars
    @State private var imageName = ["dog", "phoenix", "dragon", "mahjong"].randomElement()!
    //MARK: Body
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
    }
}

//MARK: - ShareItem used in ActivityViewControler
final class ShareItem: NSObject, UIActivityItemSource {
    //MARK: Vars
    let title: String
    let message: String
    let image: UIImage?
    
    //MARK: Init
    init(title: String, message: String, image: UIImage?) {
        self.title = title
        self.message = message
        self.image = image
    }

    // Placeholder
    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        message
    }

    // Shared content
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if let image {
            return image
        }
        return message
    }

    // Mail subject
    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        title
    }

    // Rich preview
    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {

        let metadata = LPLinkMetadata()
        metadata.title = title

        if let image {
            metadata.imageProvider = NSItemProvider(object: image)
        }
        return metadata
    }
}

// MARK: - ActivityViewController used in GameSummarySheetView
struct ActivityViewController: UIViewControllerRepresentable {

    let title: String
    let message: String
    let image: UIImage?

    func makeUIViewController(context: Context) -> UIActivityViewController {

        let shareItem = ShareItem(
            title: title,
            message: message,
            image: image
        )

        return UIActivityViewController(
            activityItems: [shareItem],
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}


//MARK: - UImage used in UploadProfileImage
extension UIImage {
    func resized(to maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height

        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
