//
//  PhoneAuth.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/9/24.
//

import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import Contacts

struct PhoneAuthentication: View {
    @ObservedObject var loginViewModel: LoginViewModel
    @State var onComplete: () -> Void
    @ObservedObject var viewModel = AuthenticationViewModel()
    @State private var verificationCode: String = ""
    @FocusState private var isVerificationCodeFocused: Bool
    @State var phoneNumber = ""
    @FocusState private var isPhoneNumberFocused: Bool
    let loginHaptics = LoginHaptics()
    @State private var hasStartedVerification = false
    
    var body: some View {
        VStack {
            Text("Log in or Sign up")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, UIScreen.main.bounds.height * 0.02)
            phoneBackgroundBox
                .padding(.bottom, UIScreen.main.bounds.height * 0.02)
            verificationCodeBackgroundBox
        }
        .padding(.horizontal, UIScreen.main.bounds.width * 0.08)
        .padding(.vertical, UIScreen.main.bounds.height * 0.1)
        .onAppear {
            isPhoneNumberFocused = true
        }
    }

    
    var phoneBackgroundBox: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 0) {             
                    Text("🇺🇸")
                        .font(.system(size: 50))
                        .padding(.leading, 5)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if phoneNumber.isEmpty {
                    Text("10-digit number")
                        .foregroundColor(.gray.opacity(0.5))
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
                phoneNumberField
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 50)
    }

    var verificationCodeBackgroundBox: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(phoneNumber == "" ? Color.clear : Color.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                
                if verificationCode.isEmpty {
                    Text("4-digit code")
                        .foregroundColor(phoneNumber == "" ? Color.clear : Color.gray.opacity(0.5))
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity)
                        .font(.title2)
                        .multilineTextAlignment(.center) // Center the text
                }
                verificationCodeField
                    .multilineTextAlignment(.center) // Center the input text
            }
        }
        .frame(height: 50)
    }
    

    var phoneNumberField: some View {
        TextField("", text: $phoneNumber)
            .keyboardType(.numberPad)
            .focused($isPhoneNumberFocused)
            .textContentType(.telephoneNumber)
            .onChange(of: phoneNumber) { newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    self.phoneNumber = filtered
                }
                if filtered.count == 10 {
                    let formattedNumber = "+1" + filtered
                    viewModel.sendCode(phoneNumber: formattedNumber)
                    loginViewModel.phoneNumber = formattedNumber
                    loginHaptics.hapticEffectTwo()
                    isVerificationCodeFocused = true
                }
            }
            .padding()
            .textFieldStyle(PlainTextFieldStyle())
            .font(.title2)
            .fontWeight(.semibold)
    }
    


    
    var verificationCodeField: some View {
        TextField("", text: $verificationCode)
            .keyboardType(.numberPad)
            .focused($isVerificationCodeFocused)
            .onReceive(Just(verificationCode)) { newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    self.verificationCode = filtered
                }
                if filtered.count == 4 && !hasStartedVerification {
                    viewModel.verifyCode(verificationCode: filtered) { success in
                            hasStartedVerification = true
                    print("Verification code entered: \(filtered)")
                    viewModel.verifyCode(verificationCode: filtered) { success in
                        if success {
                            print("Verification callback received with success")
                            Task {
                                do {
                                    await loginViewModel.checkUser()
                                    print("User check completed")
                                    onComplete()
                                    loginHaptics.hapticEffectThree()
                                } catch {
                                    print("Error checking if user exists: \(error)")
                                }
                            }
                        } else {
                            print("Verification failed")
                            hasStartedVerification = false // Reset if verification fails
                        }
                    }
                    }
                }
            }
            .padding()
            .textFieldStyle(PlainTextFieldStyle())
            .font(.title2)
            .fontWeight(.semibold)
    }
}