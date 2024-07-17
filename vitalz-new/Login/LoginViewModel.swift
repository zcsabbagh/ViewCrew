//
//  LoginViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    @Published var loginState: LoginState
    @Published var phoneNumber: String = ""
    @Published var displayName: String = ""
    @Published var profileImageURL: String = ""
    @Published var username: String = ""
    

    let firebaseModel = FirebaseCreateUserModel()

    func uploadImage(image: UIImage) {
        Task {
            if let url = try? await firebaseModel.uploadImage(selectedImage: image) {
                self.profileImageURL = url
                print("Image uploaded successfully. URL: \(url)")
            }
        }
    }

    func createUser() {
        Task {
            do {
                let username = try await firebaseModel.createUsername(inputtedUserName: self.displayName)
                self.username = username
                let newUser = UserData(
                    userID: UUID().uuidString,
                    phoneNumber: self.phoneNumber,
                    displayName: self.displayName,
                    profileImageURL: self.profileImageURL,
                    username: self.username
                )
                if let userID = try await firebaseModel.addUserToFirestore(newUser: newUser) {
                    print("User created successfully with ID: \(userID)")

                    
                }
            } catch {
                print("Error creating user: \(error)")
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



