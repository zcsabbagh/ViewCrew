//
//  AuthViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/11/24.
//

import Foundation
import SwiftUI
import Combine


class AuthenticationViewModel: ObservableObject {

    // Test phone numbers and verification codes
    private let testNumbers = [
        "+11111111111": "1111",
        "+12222222222": "2222",
        "+13333333333": "3333"
    ]
    
    func sendCode(phoneNumber: String) {
        // Check if it's a test number
        if testNumbers.keys.contains(phoneNumber) {
            print("Test code sent successfully")
            return
        }
        
        let url = URL(string: "https://api.ding.live/v1/authentication")!
        var request = URLRequest(url: url)
        var CUSTOMER_UUID = ProcessInfo.processInfo.environment["PRELUDE_CUSTOMER_UUID"]
        var API_KEY = ProcessInfo.processInfo.environment["PRELUDE_X_API"]
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_KEY, forHTTPHeaderField: "x-api-key")
        
        let parameters: [String: Any] = [
            "customer_uuid": CUSTOMER_UUID,
            "phone_number": phoneNumber
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Code sent successfully")
            } else {
                print("Failed to send code")
            }
        }
        
        task.resume()
    }
    
    func verifyCode(verificationCode: String, completion: @escaping (Bool) -> Void) {
        print("verifyCode called with code: \(verificationCode)")
        
        // Check if it's a test number and code
        if let testCode = testNumbers.first(where: { $0.value == verificationCode })?.key {
            print("Test verification successful")
            completion(true)
            return
        }
        
        let url = URL(string: "https://api.ding.live/v1/check")!
        var request = URLRequest(url: url)
        var CUSTOMER_UUID = ProcessInfo.processInfo.environment["PRELUDE_CUSTOMER_UUID"]
        var AUTH_UUID = ProcessInfo.processInfo.environment["PRELUDE_AUTH_UUID"]
        var API_KEY = ProcessInfo.processInfo.environment["PRELUDE_X_API"]
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(API_KEY, forHTTPHeaderField: "x-api-key")
        
        let parameters: [String: Any] = [
            "customer_uuid": CUSTOMER_UUID,
            "authentication_uuid": AUTH_UUID,
            "check_code": verificationCode
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Verification successful")
                    completion(true)
                } else {
                    print("Failed to verify code")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
        
        task.resume()
    }
}