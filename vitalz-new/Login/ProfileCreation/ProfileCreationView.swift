//
//  ProfileCreationView.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import Foundation
import SwiftUI
import Combine

struct ProfileCreationView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented: Bool = false
    let onComplete: () -> Void
    let loginHaptics = LoginHaptics()
    
    var body: some View {
        VStack {
            Text(selectedImage != nil ? "Add your name" : "Add a profile pic")
                .animation(.easeInOut)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, UIScreen.main.bounds.height * 0.02)

            profileImageView
            .padding(.bottom, UIScreen.main.bounds.height * 0.02)

            nameBackgroundBox
            .padding(.bottom, UIScreen.main.bounds.height * 0.02)

            createProfileButton
            .padding(.bottom, UIScreen.main.bounds.height * 0.02)
            

        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, UIScreen.main.bounds.width * 0.1) // Add 10% padding on the horizontal side
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
                .onChange(of: selectedImage) { _ in
                    viewModel.uploadImage(image: selectedImage!)
                }
        }
    }

    var createProfileButton: some View {
        Button(action: {
            viewModel.createUser()
            loginHaptics.hapticEffectThree()
        }) {
            Text("create profile")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
                .background(
                    LinearGradient(gradient: Gradient(colors: viewModel.displayName.isEmpty ? [Color.clear, Color.clear] : [.darkRed, .red]), startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(viewModel.displayName.isEmpty ? Color.clear : .white)
                .cornerRadius(15)
                .multilineTextAlignment(.center)
        }
    }

    var nameBackgroundBox: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedImage == nil ? Color.clear : Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                
                if viewModel.displayName == "" {
                    Text("your name")
                        .foregroundColor(selectedImage == nil ? Color.clear : Color.gray.opacity(0.5))
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity)
                        .font(.title2)
                        .multilineTextAlignment(.center) // Center the text
                }
                displayNameField
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center) // Center the input text
            }
        }
        .frame(height: 50)
    }

    var displayNameField: some View {
        TextField("", text: $viewModel.displayName)
            .textContentType(.name)
            .padding()
            .textFieldStyle(PlainTextFieldStyle())
            .font(.title2)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
    }


    var profileImageView: some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .cornerRadius(40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.white, lineWidth: 2)
                    )
            } else {
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Image("profile_pic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                .padding()
            }
        }
    }



}

