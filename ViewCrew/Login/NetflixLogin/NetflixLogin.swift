//
//  NetflixLoginTry2.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import SwiftUI
import WebKit
import Contacts
import FirebaseAuth


/* Note to self:
    The reason I kept this is as a page of it's own
    is so that in the future I can add other sign in options
    here without having to rework the login flow
*/

struct NetflixLoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @StateObject var koodosViewModel = KoodosViewModel()
    @State private var showWebView = false
    let onComplete: () -> Void
    let loginHaptics = LoginHaptics()
    @State private var isContactAccessGranted: Bool = true
    @State private var contactUploadViewModel: ContactUploadViewModel = ContactUploadViewModel()

    var body: some View {
        VStack {
            WebViewWrapper(koodosIntegration: koodosViewModel, onDismiss: {
                showWebView = false
            })
                .onChange(of: koodosViewModel.signInReady) { newValue in
                    if koodosViewModel.signInReady == true {
                        loginHaptics.hapticEffectThree()
                        print("""
                        KoodosIntegration Variables:
                        Email: \(koodosViewModel.email ?? "nil")
                        Password: \(koodosViewModel.password ?? "nil")
                        NetflixId: \(koodosViewModel.netflixId ?? "nil")
                        SecureNetflixId: \(koodosViewModel.secureNetflixId ?? "nil")
                        AuthURL: \(koodosViewModel.authURL ?? "nil")
                        ProfileId: \(koodosViewModel.profileId ?? "nil")
                        Country: \(koodosViewModel.country ?? "nil")
                        """)
                        
                        // Call onComplete after a short delay to ensure the view has time to update
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showWebView = false
                            shareCredentialsWithDataMover()
                            onComplete()
                        }
                }
            }
        }
        .onAppear {
            HapticFeedbackGenerator.shared.generateHapticMedium()
        }
    }

    
    func shareCredentialsWithDataMover() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "DATA_MOVER_API_KEY") as? String, !apiKey.isEmpty else {
            print("Data Mover API key not found in Info.plist.")
            return
        }
        
        let url = URL(string: "https://www.shelf.im/api/data-mover/netflix")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "data-mover-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": UserDefaults.standard.string(forKey: "userID") ?? "test",
            "email": koodosViewModel.email ?? "",
            "password": koodosViewModel.password ?? "",
            "profile_id": koodosViewModel.profileId ?? "",
            "auth_url": koodosViewModel.authURL ?? "",
            "netflix_id": koodosViewModel.netflixId ?? "",
            "secure_netflix_id": koodosViewModel.secureNetflixId ?? "",
            "country": koodosViewModel.country ?? ""
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending POST request: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Data Mover response status code: \(httpResponse.statusCode)")
            }
        }
        
        task.resume()
    }

    

}