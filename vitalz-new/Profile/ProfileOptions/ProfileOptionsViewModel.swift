//
//  ProfileOptionsViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/16/24.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


class ProfileOptionsViewModel: ObservableObject {

    private var cancellables = Set<AnyCancellable>()
    
    func signOut() {
        do {
            UserDefaults.standard.removeObject(forKey: "userID")
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.set(LoginState.authentication.rawValue, forKey: "lastLoginState")
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    

    /* deletes user and removes from all their friends' friends list */
    func deleteAccount() {
       
        let userId = UserDefaults.standard.string(forKey: "userID") ?? "test"
        
        let db = Firestore.firestore()
        
        // Delete user document
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                // Delete user references in friends arrays
                db.collection("users").whereField("friends", arrayContains: userId).getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                    } else {
                        for document in querySnapshot!.documents {
                            document.reference.updateData([
                                "friends": FieldValue.arrayRemove([userId])
                            ]) { error in
                                if let error = error {
                                    print("Error updating document: \(error)")
                                }
                            }
                        }
                    }
                }
                

                UserDefaults.standard.removeObject(forKey: "userID")
                UserDefaults.standard.set(false, forKey: "isLoggedIn")
                UserDefaults.standard.set(LoginState.authentication.rawValue, forKey: "lastLoginState")
            
                
            }
        }
    }
}
