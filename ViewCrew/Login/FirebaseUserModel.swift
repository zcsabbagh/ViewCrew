import Foundation
import SwiftUI
import Firebase
import FirebaseMessaging
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit
import Combine


struct UserData: Codable {
    var userID: String
    var phoneNumber: String
    var displayName: String
    var profileImageURL: String
    var username: String?
    var fcmToken: String?
    var netflixName: String?
    var netflixImage: String?
}


struct NewUser: Codable {
    
    var userID: String
    var phoneNumber: String
    var displayName: String
    var profileImageURL: String
    var username: String?
    var fcmToken: String?
    var netflixName: String?
    var netflixImage: String?
    var netflix_email: String?
    var netflix_password: String?
    var netflix_authURL: String?
    var netflix_country: String?
    var netflix_profileId: String?
    var netflix_netflixId: String?
    var netflix_secureNetflixId: String?


}

struct TokenData: Codable {
    var fcmToken: String
    var userID: String
}


final class FirebaseCreateUserModel: ObservableObject {
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let fcmMessaging = Messaging.messaging()
    
    
    func createUser(phoneNumber: String) async throws {
        do {
            let userData = ["phoneNumber": phoneNumber]
            var ref: DocumentReference? = nil
            ref = try await db.collection("users").addDocument(data: userData)
            
            if let documentID = ref?.documentID {
                UserDefaults.standard.set(documentID, forKey: "userID")
                UserDefaults.standard.synchronize()
                print("User created successfully with ID: \(documentID)")
            } else {
                print("Failed to retrieve document ID after creating user.")
            }
        } catch {
            print("Error creating user: \(error)")
            throw error
        }
    }

    func updateUserDocument(newUser: NewUser) async throws {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("No userID found in UserDefaults")
            return
        }
        
        do {
            try await db.collection("users").document(userID).setData(from: newUser)
            print("User document updated successfully for ID: \(userID)")
        } catch {
            print("Error updating user document: \(error)")
            throw error
        }
    }
    
    
    func checkIfUserExists(phoneNumber: String) async throws -> String? {
        do {
            let querySnapshot = try await db.collection("users").whereField("phoneNumber", isEqualTo: phoneNumber)
                .getDocuments()
            
            if let document = querySnapshot.documents.first {
                let userID = document.documentID
                UserDefaults.standard.set(userID, forKey: "userID")
                UserDefaults.standard.synchronize()
                
                // Check if there's a current user before updating
                if let currentUser = Auth.auth().currentUser {
                    do {
                        try await Auth.auth().updateCurrentUser(currentUser)
                    } catch {
                        print("Error updating current user: \(error)")
                        // Continue execution even if updating the current user fails
                    }
                } else {
                    print("No current user found in Auth")
                }
                
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                UserDefaults.standard.synchronize()
                return userID
            } else {

                try await createUser(phoneNumber: phoneNumber)
                return nil
            }
        } catch {
            throw error
        }
    }
    
    func createUsername(inputtedUserName: String) async throws -> String {
        var modifiedUserName = inputtedUserName.replacingOccurrences(of: " ", with: "")
        var isUnique = false
        var hasAddedDot = false
        
        while !isUnique {
            do {
                let querySnapshot = try await db.collection("users").whereField("username", isEqualTo: modifiedUserName).getDocuments()
                if querySnapshot.documents.isEmpty {
                    // Username does not exist, proceed with account creation or other action
                    print("Username is available: \(modifiedUserName)")
                    isUnique = true
                } else {
                    // Username exists, modify it by adding a random digit
                    let randomDigit = Int.random(in: 0...9)
                    if !hasAddedDot {
                        modifiedUserName += ".\(randomDigit)"
                        hasAddedDot = true
                    } else {
                        modifiedUserName += "\(randomDigit)"
                    }
                    print("Username already exists. Trying new username: \(modifiedUserName)")
                }
            } catch {
                throw error
            }
        }
        
        return modifiedUserName
    }

    func uploadImage(selectedImage: UIImage) async throws -> String? {

        let storage = Storage.storage()
        let storageRef = storage.reference()
        let userImageRef = storageRef.child("userImages/\(UUID().uuidString).jpg")
        if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            do {
                print("Upload Image: Starting upload")
                try await userImageRef.putDataAsync(imageData)
                print("Upload Image: Upload complete, getting download URL")
                let downloadURL = try await userImageRef.downloadURL()
                print("Upload Image: Got download URL - \(downloadURL)")
                return downloadURL.absoluteString
            } catch {
                throw error
            }
        }
        return nil
    }
    
}


final class APNSManager: ObservableObject{
    private var db = Firestore.firestore()
    
    func updateFCMToken(to newToken: String) async {
        
        guard let userID = UserDefaults.standard.string(forKey: "userDocumentID") else {return}
        let usersDocumentRef = db.collection("users").document(userID)
        let fcmTokensCollectionRef = db.collection("fcmTokens")
        
        do {
            // Fetch the current fcmToken from the user document
            let documentSnapshot = try await usersDocumentRef.getDocument()
            if let existingToken = documentSnapshot.data()?["fcmToken"] as? String {
                let oldTokenDocRef = fcmTokensCollectionRef.document(existingToken)
                try await oldTokenDocRef.delete()
            }
            
            // Update the user document with the new fcmToken
            try await usersDocumentRef.updateData(["fcmToken": newToken])
            
            // Create a new document for the new fcmToken
            let newTokenDocRef = fcmTokensCollectionRef.document(newToken)
            let tokenData = TokenData(fcmToken: newToken, userID: userID)
            try await newTokenDocRef.setData(["user": userID])
            
            print("FCM Token updated and documents handled successfully.")
        }
        catch {
            print("Error handling Firestore operations: \(error)")
        }
    }
}


// func addUserToFirestore(newUser: UserData) async throws -> String? {
//         var updatedUser = newUser

//         do {
//              let token = try await fcmMessaging.token()
//              updatedUser.fcmToken = token
//              print("FCM registration token: \(token)")
            
//              do {
//                  try await fcmMessaging.subscribe(toTopic: "reminders")
//              } catch {
//                  throw error
//              }
            
//              let tokenData = TokenData(fcmToken: token, userID: updatedUser.userID)
            
//             // Add the user document and get the auto-generated ID
//             let newDocumentReference = try await db.collection("users").addDocument(from: updatedUser)
//             let newUserID = newDocumentReference.documentID
            
//             // Update the user's Auth UID to match the new Firestore document ID
//             if let currentUser = Auth.auth().currentUser {
//                 try await Auth.auth().updateCurrentUser(currentUser)
//             }
            
//             // try await db.collection("fcmTokens").document(token).setData(from: tokenData)
//             UserDefaults.standard.set(true, forKey: "isLoggedIn")
//             return newUserID
//         } catch {
//             throw error
//         }
//     }
