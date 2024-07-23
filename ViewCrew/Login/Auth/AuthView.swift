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
    @State private var isContactAccessGranted: Bool = false
    @State private var contactUploadViewModel: ContactUploadViewModel = ContactUploadViewModel()
    
    var body: some View {
        VStack {
            Text("Log in or Sign up")
                .font(.custom("Roboto-Regular", size: 25))
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
            HapticFeedbackGenerator.shared.generateHapticMedium()
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
                        .font(.custom("Roboto-Regular", size: 18))
                        .foregroundColor(.gray.opacity(0.5))
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity)
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
                        .font(.custom("Roboto-Regular", size: 18))
                        .foregroundColor(phoneNumber == "" ? Color.clear : Color.gray.opacity(0.5))
                        .fontWeight(.light)
                        .frame(maxWidth: .infinity)
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
            .font(.custom("Roboto-Regular", size: 18))
            .keyboardType(.numberPad)
            .focused($isPhoneNumberFocused)
            .textContentType(.telephoneNumber)
            .onChange(of: phoneNumber) { newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                let last10Digits = String(filtered.suffix(10))
                if last10Digits != phoneNumber {
                    self.phoneNumber = last10Digits
                }
                if last10Digits.count == 10 {
                    let formattedNumber = "+1" + last10Digits
                    viewModel.sendCode(phoneNumber: formattedNumber)
                    loginViewModel.phoneNumber = formattedNumber
                    loginHaptics.hapticEffectTwo()
                    isVerificationCodeFocused = true
                }
            }
            .padding()
            .textFieldStyle(PlainTextFieldStyle())
            .font(.custom("Roboto-Regular", size: 18))
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
                                    requestContactsAccess()

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
            .font(.custom("Roboto-Regular", size: 18))
            .fontWeight(.semibold)
    }

    func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting access to contacts: \(error)")
                    isContactAccessGranted = false
                } else {
                    print("Access to contacts granted: \(granted)")
                    isContactAccessGranted = granted
                    if granted == true {
                        Task {
                            await contactUploadViewModel.fetchAndProcessContactNumbers(userID: UserDefaults.standard.string(forKey: "userID") ?? "test")
                        }
                       
                    }
                }
            }
        }
    }

}