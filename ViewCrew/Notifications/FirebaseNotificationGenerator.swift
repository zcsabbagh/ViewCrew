//
//  NotificationFunctions.swift
//  Roll
//
//  Created by Christen Xie on 12/27/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

final class FirebaseNotificationGenerator{
    
    static let shared = FirebaseNotificationGenerator()
    
    private init() {}
    
    private lazy var functions = Functions.functions()

    /* Notifications that are used are below */
    
    func sendFriendRequestNotification(fromUser: String, toUser: String) async throws {
        do {
            let _ = try await functions.httpsCallable("sendFriendRequestNotification").call([
                "sendingUser": fromUser,
                "receivingUser": toUser
            ])
        } catch {
            throw error
        }
    }
    
    func sendAcceptFriendRequestNotification(fromUser: String, toUser: String) async throws {
        do {
            let result = try await functions.httpsCallable("acceptFriendRequestNotification").call([
                "messageRecipientId": toUser,
                "messageSenderId": fromUser
            ])
            
            if let data = result.data as? [String: Any],
            let success = data["success"] as? Bool,
            let message = data["message"] as? String {
                if success {
                    print("Notification sent successfully: \(message)")
                } else {
                    print("Notification failed: \(message)")
                }
            } else {
                print("Unexpected response format")
            }
        } catch {
            print("Error sending notification: \(error.localizedDescription)")
            if let functionsError = error as? NSError {
                print("Error domain: \(functionsError.domain)")
                print("Error code: \(functionsError.code)")
                if let details = functionsError.userInfo["details"] as? String {
                    print("Error details: \(details)")
                }
            }
            throw error
        }
    }

    func sendContactJoinedNotification(fromUserDisplayName: String, fromUserId: String, toUsers: [String]) async throws {
        do {
            let _ = try await
            functions.httpsCallable("sendContactJoinedNotification").call([
                "joinedUserDisplayName": fromUserDisplayName,
                "joinedUserId": fromUserId,
                "messageRecipientIds": toUsers,
            ])
        }
        catch{
            throw error
        }
    }


    func sendViewsNotification(forUser: String, views: Int) async throws {
        do {
            let _ = try await
            functions.httpsCallable("sendViewsNotification").call([
                "forUser": forUser,
                "views": views,
            ])
            print("NotificaitonSuccessfully sent")
        }
        catch{
            throw error
        }
    }

    func sendReactPostNotification(fromUser: String, forPoster: String, emoji: String) async throws {
        print("Entering sendReactPostNotification")
        if fromUser != "" && forPoster != "" && emoji != "" {
                
            do
            {
                let _ = try await
                functions.httpsCallable("sendReactPostNotification").call([
                    "postRecipientId": forPoster,
                    "likeSenderId": fromUser,
                    "emoji": emoji,
                ])
                print("NotificaitonSuccessfully sent")
            }
            catch{
                throw error
            }
        }
    }

    /* Notifications that are used are above */

        
    func sendCommentNotification(fromUser: String, toUser: String, toPostID: String) async throws {
        do
        {
            let _ = try await
            functions.httpsCallable("sendCommentNotification").call([
                "commentRecipientId": toUser,
                "commentSenderId": fromUser,
                "postId": toPostID
            ])
        }
        catch{
            throw error
        }
    }
    
    
    func sendLikeCommentNotification(fromUser: String, forComment: String) async throws{
        do
        {
            let _ = try await
            functions.httpsCallable("sendLikeCommentNotification").call([
                "likeSenderId" : fromUser,
                "likedCommentId" : forComment
        ])
        }
        catch{
            throw error
        }
    }
    
    func sendClippedNotification(fromUser: String, toUser: String, numClipped: Int, forPost: String) async throws {
        do{
            let _ = try await
            functions.httpsCallable("sendClippedNotification").call([
                "clippedRecipientId": toUser,
                "clippedSenderId": fromUser,
                "numClipped": numClipped,
                "postId": forPost
            ])
        }
        catch{
            throw error
        }
    }
    

    
    func sendCommentReplyNotification(fromUserId: String, forCommentId: String, replyText: String) async throws{
        do{
            print("sending notif", fromUserId, forCommentId)
            let _ = try await
            functions.httpsCallable("sendCommentReplyNotification").call([
                "commentId" : forCommentId,
                "replySenderId" : fromUserId,
                "replyText" : replyText
            ])
        }
        catch{
            throw error
        }
    }
    
    func sendFriendPinnedNotification(fromUserId: String, fromPostId: String, destinationPostId: String, imageUrl: String) async throws {
        do{
            let _ = try await
            functions.httpsCallable("sendFriendPinnedNotification").call([
                    "senderUserId" : fromUserId,
                    "fromPostId" : fromPostId,
                    "destinationPostId" : destinationPostId,
                    "imageUrl" : imageUrl
                ])
        }
        catch{
            throw error
        }
    }
    
    //TODO: deeplink to photoAlbum
    func sendFriendPostedNotificaiton(fromPosterId: String) async throws{
        do {
            let _ = try await
            functions.httpsCallable("sendFriendPostedNotification").call([
                "messageSenderId" : fromPosterId
                ])
        }
        catch{
            throw error
        }
    }
    
    //TODO: deeplink to post
    func sendTagUserNotification(fromPosterId: String, toPosterId: String) async throws{
        do {
            let _ = try await
            functions.httpsCallable("sendTagUserNotification").call([
                "taggedUserId" : toPosterId,
                "taggerUserId" : fromPosterId,
                ])
        }
        catch{
            throw error
        }
    }
    
}
