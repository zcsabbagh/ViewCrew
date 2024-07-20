//
//  ContactsFirestore.swift
//  Roll
//
//  Created by Zane Sabbagh on 12/13/23.
//

import Foundation
import SwiftUI
import Contacts
import FirebaseFirestore

class ContactsFirestoreChecker {
    static let shared = ContactsFirestoreChecker()

    public init() {}

    public func checkContactsInFirestore(userPhoneNumber: String, completion: @escaping ([String]) -> Void) {
        // Requesting access to the user's contacts
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("Failed to request access: \(error)")
                completion([])
                return
            }

            if granted {
                // Fetch contacts
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)

                do {
                    var contactNumbers: [String] = []
                    try store.enumerateContacts(with: request) { (contact, stop) in
                        for phoneNumber in contact.phoneNumbers {
                            let formattedNumber = self.normalizePhoneNumber(phoneNumber: phoneNumber.value.stringValue)
                            contactNumbers.append(formattedNumber)
                        }
                    }

                    print(contactNumbers, "fetched contact #s")
                    self.checkNumbersInFirestore(contactNumbers: contactNumbers, completion: completion)
                } catch {
                    print("Failed to fetch contacts")
                    completion([])
                }
            } else {
                print("Access to contacts was denied.")
                completion([])
            }
        }
    }

    public func normalizePhoneNumber(phoneNumber: String) -> String {
        // Normalize the phone number (remove country codes, dashes, or parentheses)
        let digits = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if digits.count == 11 && digits.first == "1" {
             return String(digits.dropFirst())
         }
        return digits
    }

    public func checkNumbersInFirestore(contactNumbers: [String], completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        var matchedUserIds: [String] = []

        let group = DispatchGroup()
        for number in contactNumbers {
            group.enter()
            usersRef.whereField("phoneNumber", isEqualTo: number).getDocuments { (querySnapshot, err) in
                defer { group.leave() }
                if let err = err {
                    print("Error getting documents: \(err)")
                } else if let snapshot = querySnapshot {
                    for document in snapshot.documents {
                        matchedUserIds.append(document.documentID)
                        print("Contact \(number) is a user in Firestore with ID \(document.documentID).")
                    }
                }
            }
        }

        group.notify(queue: .main) {
            completion(matchedUserIds)
        }
    }
}

