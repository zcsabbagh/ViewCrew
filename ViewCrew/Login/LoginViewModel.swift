//
//  LoginViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import SwiftUI
import Combine
import FirebaseAuth

class LoginViewModel: ObservableObject {
    @AppStorage("loginState") var loginState: LoginState = .authentication
    @AppStorage("phoneNumber") var phoneNumber: String = ""
    @AppStorage("displayName") var displayName: String = ""
    @AppStorage("profileImageURL") var profileImageURL: String = ""
    @AppStorage("username") var username: String = ""
    @AppStorage("userID") var userID: String = ""
    
    

    let firebaseModel = FirebaseCreateUserModel()

    func uploadImage(image: UIImage) {
        Task {
            do {
                if let url = try await firebaseModel.uploadImage(selectedImage: image) {
                    self.profileImageURL = url
                    print("Image uploaded successfully. URL: \(url)")
                } else {
                    print("Image upload failed: No URL returned")
                }
            } catch {
                print("Error uploading image: \(error)")
            }
            
            // Call updateUser() regardless of the upload result
            await updateUser()
        }
    }

    func updateUser() {
        Task {
            do {
                let newUsername = try await firebaseModel.createUsername(inputtedUserName: self.displayName)
                self.username = newUsername
                
                let newUser = NewUser(
                    userID: self.userID,
                    phoneNumber: self.phoneNumber,
                    displayName: self.displayName,
                    profileImageURL: self.profileImageURL,
                    username: newUsername,
                    fcmToken: nil,
                    netflixName: nil,
                    netflixImage: nil,
                    netflix_email: UserDefaults.standard.string(forKey: "netflix_email"),
                    netflix_password: UserDefaults.standard.string(forKey: "netflix_password"),
                    netflix_authURL: UserDefaults.standard.string(forKey: "netflix_authURL"),
                    netflix_country: UserDefaults.standard.string(forKey: "netflix_country"),
                    netflix_profileId: UserDefaults.standard.string(forKey: "netflix_profileId"),
                    netflix_netflixId: UserDefaults.standard.string(forKey: "netflix_netflixId"),
                    netflix_secureNetflixId: UserDefaults.standard.string(forKey: "netflix_secureNetflixId")
                )
                
                try await firebaseModel.updateUserDocument(newUser: newUser)
                print("User updated successfully.")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            } catch {
                print("Error updating user: \(error)")
            }
        }
    }


    func checkUser() {
        Task {
            do {
                if let userID = try await firebaseModel.checkIfUserExists(phoneNumber: self.phoneNumber) {
                    print("User exists with ID: \(userID)")
                } else {
                    print("User does not exist")
                }
            } catch {
                print("Error checking if user exists: \(error)")
            }
        }
    }


    /* login state management */
    init() {
        let savedState = UserDefaults.standard.string(forKey: "lastLoginState")
        self.loginState = LoginState(rawValue: savedState ?? "") ?? .authentication
    }
    
    func moveToNextState() {
        print("Current state: \(loginState)")
        switch loginState {
        case .authentication:
            loginState = .netflixSignIn
            print("Moving to Netflix Sign In")
        case .netflixSignIn:
            loginState = .profileCreation
            print("Moving to Profile Creation")
        case .profileCreation:
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            print("Login completed")
        }
        saveLoginState()
        print("New state: \(loginState)")
    }
    
    private func saveLoginState() {
        UserDefaults.standard.set(loginState.rawValue, forKey: "lastLoginState")
    }
}


