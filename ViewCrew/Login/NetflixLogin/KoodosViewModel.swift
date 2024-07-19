//
//  KoodosViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/15/24.
//

import SwiftUI

class KoodosViewModel: ObservableObject {
    @AppStorage("netflix_country") var country: String?
    @AppStorage("netflix_profileId") var profileId: String?
    @AppStorage("netflix_netflixId") var netflixId: String?
    @AppStorage("netflix_secureNetflixId") var secureNetflixId: String?
    @AppStorage("netflix_email") var email: String?
    @AppStorage("netflix_password") var password: String?
    @AppStorage("netflix_authURL") var authURL: String?
    @Published var signInReady: Bool = false

    func fetchCountry(completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.country.is") else {
            return completion("US")
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return completion("US") }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
            let country = json["country"] {
                print("country: \(country)")
                completion(country)
            } else {
                completion("US")
            }
        }.resume()
    }

    func updateLoginInfo(email: String, password: String, authURL: String) {
        DispatchQueue.main.async {
            self.email = email
            self.password = password
            self.authURL = authURL
        }
    }

    func updateProfileInfo(profileId: String?, netflixId: String?, secureNetflixId: String?) {
        DispatchQueue.main.async {
            if let profileId = profileId {
                self.profileId = profileId
            }
            if let netflixId = netflixId {
                self.netflixId = netflixId
            }
            if let secureNetflixId = secureNetflixId {
                self.secureNetflixId = secureNetflixId
            }
        }
    }
}