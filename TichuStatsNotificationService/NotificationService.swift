//
//  NotificationService.swift
//  TichuStatsNotificationService
//
//  Created by Leon on 19.05.2026.
//

import UserNotifications
import Intents
import UIKit

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler:
        @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        guard let bestAttemptContent =
            (request.content.mutableCopy()
             as? UNMutableNotificationContent) else {
            contentHandler(request.content)
            return
        }

        self.bestAttemptContent = bestAttemptContent

        let userInfo = request.content.userInfo

        let senderName     = userInfo["sender_name"]     as? String ?? String(localized: "general.unknown")
        let senderHandle   = userInfo["sender_id"]       as? String ?? senderName
        let conversationID = userInfo["conversation_id"] as? String ?? "default-chat"
        let imageURLString = userInfo["image_url"]       as? String

        // Build name components for Contacts matching
        var nameComponents = PersonNameComponents()
        let parts = senderName.split(separator: " ", maxSplits: 1)
        nameComponents.givenName  = parts.first.map(String.init)
        nameComponents.familyName = parts.dropFirst().first.map(String.init)

        func buildAndDeliver(avatar: INImage?) {

            let sender = INPerson(
                personHandle: INPersonHandle(
                    value: senderHandle,
                    type: .unknown
                ),
                nameComponents: nameComponents,
                displayName: senderName,
                image: avatar,
                contactIdentifier: nil,
                customIdentifier: senderHandle
            )

            let intent = INSendMessageIntent(
                recipients: nil,
                outgoingMessageType: .outgoingMessageText,
                content: bestAttemptContent.body,
                speakableGroupName: nil,
                conversationIdentifier: conversationID,
                serviceName: nil,
                sender: sender,
                attachments: nil
            )

            // Required per Apple docs
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming

            interaction.donate { error in

                if let error {
                    print("Interaction donation failed: \(error)")
                    contentHandler(bestAttemptContent)
                    return
                }

                do {
                    //Update content AFTER successful donation
                    let updatedContent = try bestAttemptContent.updating(from: intent)
                    contentHandler(updatedContent)
                } catch {
                    print("Content update failed: \(error)")
                    contentHandler(bestAttemptContent)
                }
            }
        }

        guard let imageURLString,
              let imageURL = URL(string: imageURLString) else {
            buildAndDeliver(avatar: nil)
            return
        }

        downloadImage(from: imageURL) { image in
            let avatar: INImage?
            if let data = image?.jpegData(compressionQuality: 0.8) {
                avatar = INImage(imageData: data)
            } else {
                avatar = nil
            }
            buildAndDeliver(avatar: avatar)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        guard let contentHandler = contentHandler,
              let bestAttemptContent = bestAttemptContent else { return }
        contentHandler(bestAttemptContent)
    }

    private func downloadImage(
        from url: URL,
        completion: @escaping (UIImage?) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }
}
