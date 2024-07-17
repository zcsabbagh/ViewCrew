//
//  ContactUploadViewModel.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/17/24.
//

import Foundation
import SwiftUI
import Contacts
import FirebaseFirestore
import Combine
import FirebaseAuth
import CoreData
/*
Contact fetching & recommending tasks
*/
struct IntroContacts: Identifiable, Codable {
    var id = UUID()
    var displayName: String = ""
    var contactImage: Data?
    var profileImage: String?
    var strippedPhoneNumber: String = ""
    var isAdded: Bool = false
    var friendsOnRoll: Int = 1
    var firebaseDocument: String?
}

class ContactUploadViewModel: ObservableObject {
    @Published var strippedContactList: [String] = [] {
        didSet {
            UserDefaults.standard.set(strippedContactList, forKey: "strippedContactList")
        }
    }
    @Published var strippedToFirebaseDict: [String: [Any]] = [:] {
        didSet {
            UserDefaults.standard.set(strippedToFirebaseDict, forKey: "strippedToFirebaseDict")
        }
    }
    @Published var sortedStrippedContactList: [String] = [] {
        didSet {
            UserDefaults.standard.set(sortedStrippedContactList, forKey: "sortedStrippedContactList")
        }
    }
    @Published var sortedIntroContacts: [IntroContacts] = [] {
        didSet {
            let encodedData = try? JSONEncoder().encode(sortedIntroContacts)
            UserDefaults.standard.set(encodedData, forKey: "sortedIntroContacts")
        }
    }
    @Published var contactsProcessed: Bool = UserDefaults.standard.bool(forKey: "contactsUploaded")

    func fetchAndProcessContactNumbers(userID: String) async {

        if contactsProcessed {
            return
        }
        let contactStore = CNContactStore()
        var contacts: [CNContact] = []
        let keys = [CNContactPhoneNumbersKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            try contactStore.enumerateContacts(with: request) { (contact, stop) in
                contacts.append(contact)
            }
        } catch {
            print("Failed to fetch contacts, error: \(error)")
            return
        }
        
        let processedNumbers = contacts.flatMap { contact -> [String] in
            contact.phoneNumbers.compactMap { phoneNumber -> String? in
                let digits = phoneNumber.value.stringValue.filter("0123456789".contains)
                guard digits.count >= 10 else { return nil }
                return String(digits.suffix(10))
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            print("Should call checkAndCreate")
            self?.strippedContactList = processedNumbers
            self?.checkAndCreateContactDocuments(userID: Auth.auth().currentUser?.uid ?? "") {
                self?.checkPhoneNumberExistenceInUsersCollection() {
                    self?.sortStrippedToFirebaseDict() {
                        Task {
                            await self?.generateIntroContacts(from: self!.sortedStrippedContactList)
                            self?.contactsProcessed = true
                            UserDefaults.standard.set(true, forKey: "contactsUploaded")
                        }
                    }
                }
            }
        }
    }
    func checkAndCreateContactDocuments(userID: String, completion: @escaping () -> Void) {
        print("STARTING")
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        strippedContactList.forEach { phoneNumber in
            group.enter() // Enter the group when starting an async task
            let query = db.collection("contactNumbers").whereField("phoneNumber", isEqualTo: phoneNumber)
            query.getDocuments { [weak self] (querySnapshot, error) in
                guard let querySnapshot = querySnapshot else {
                    group.leave() // Leave the group if query fails
                    return
                }
                
                if querySnapshot.isEmpty {
                    // No document exists, create a new one
                    db.collection("contactNumbers").addDocument(data: [
                        "phoneNumber": phoneNumber,
                        "contactsOnApp": [userID]
                    ]) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Document added with phoneNumber: \(phoneNumber), including userID in contactsOnApp.")
                            // Perform any immediate state updates needed here
                            db.collection("contactNumbers").whereField("phoneNumber", isEqualTo: phoneNumber).getDocuments { (querySnapshot, err) in
                                if let err = err {
                                    print("Error getting document: \(err)")
                                } else if let document = querySnapshot?.documents.first {
                                    self?.strippedToFirebaseDict[phoneNumber] = [document.documentID, 1] // Assuming the length of contactNumbers is 1 for a new document
                                }
                            }
                        }
                        group.leave() // Leave the group after document is added or if there's an error
                    }
                } else if let document = querySnapshot.documents.first {
                    // Document exists, update it
                    let docRef = db.collection("contactNumbers").document(document.documentID)
                    var contactsOnApp = document.data()["contactsOnApp"] as? [String] ?? []
                    // Remove the userID if it already exists to prevent duplicates
                    if let index = contactsOnApp.firstIndex(of: userID) {
                        contactsOnApp.remove(at: index)
                    }
                    // Re-add the userID to ensure it's in the array
                    contactsOnApp.append(userID)
                    docRef.updateData(["contactsOnApp": contactsOnApp]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document for \(phoneNumber) updated with userID: \(userID).")
                            // Perform any immediate state updates needed here
                            self?.strippedToFirebaseDict[phoneNumber] = [document.documentID, contactsOnApp.count] // Update with the current documentID and the new length of contactsOnApp
                        }
                        group.leave() // Leave the group after updating document or if there's an error
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }

    func checkPhoneNumberExistenceInUsersCollection(completion: @escaping () -> Void) {
        print("Entering checkPhoneNumbers with \(self.strippedContactList.count) numbers to check \n\n\n\n")
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        self.strippedContactList.forEach { phoneNumber in
            group.enter()
            let query = db.collection("users").whereField("phoneNumber", isEqualTo: phoneNumber)
            query.getDocuments { [weak self] (querySnapshot, error) in
                if let querySnapshot = querySnapshot, !querySnapshot.isEmpty, let documentID = querySnapshot.documents.first?.documentID {
                    self?.strippedToFirebaseDict[phoneNumber]?.append(documentID)
                    print("User exists with phoneNumber: \(phoneNumber), documentID: \(documentID)")
                    group.leave()
                } else {
                    // If no document is found for the phoneNumber, it's considered an error case but not stopping the flow
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            completion()
        }
    }


    func sortStrippedToFirebaseDict(completion: @escaping () -> Void) {
        print("Entering sortStrippedToFirebase dict with \(self.strippedToFirebaseDict.count) \n\n\n\n")
        print("Stripped to Firebase Dictionary: \(self.strippedToFirebaseDict)")
        DispatchQueue.global(qos: .userInitiated).async {
            let sortedKeys = self.strippedToFirebaseDict.keys.sorted { firstKey, secondKey in
                guard let firstValue = self.strippedToFirebaseDict[firstKey], let secondValue = self.strippedToFirebaseDict[secondKey] else {
                    return false
                }
                // Check if both have a 3rd index
                if firstValue.count > 2, secondValue.count <= 2 {
                    return true
                } else if firstValue.count <= 2, secondValue.count > 2 {
                    return false
                } else {
                    // If both have a 3rd index or both don't, compare the 2nd index
                    return firstValue[1] as! Int > secondValue[1] as! Int
                }
            }
            DispatchQueue.main.async {
                self.sortedStrippedContactList = sortedKeys
                print("sortedStrippedContact list is : \(self.sortedStrippedContactList.count) long")
                completion()
            }
        }
    }

    func generateIntroContacts(from sortedKeys: [String]) async {
        print("Entering generateIntroContacts with this many contacts to sort: \(self.sortedStrippedContactList.count) \n\n\n\n")
        var introContacts = [IntroContacts]()
        let db = Firestore.firestore()
        let contactStore = CNContactStore()
        var introContactsCount = 0 // Counter for the number of introContacts generated

        for key in sortedKeys {
            guard let value = strippedToFirebaseDict[key] else { continue }
            
            if value.count == 3, let documentID = value[2] as? String {
                let docRef = db.collection("users").document(documentID)
                let docSnapshot = try? await docRef.getDocument()
                
                if let docSnapshot = docSnapshot, docSnapshot.exists {
                    let displayName = docSnapshot.get("displayName") as? String ?? ""
                    let profileImage = docSnapshot.get("profileImageURL") as? String ?? ""
                    let friendsOnRoll = (docSnapshot.get("friends") as? [String])?.count ?? 0
                    let firebaseDocument = docSnapshot.documentID
                    
                    introContacts.append(IntroContacts(displayName: displayName, contactImage: nil, profileImage: profileImage, strippedPhoneNumber: key, friendsOnRoll: friendsOnRoll, firebaseDocument: firebaseDocument))
                    introContactsCount += 1 // Increment the counter
                    print("Generating intro contact: \(introContactsCount)")
                }
            } else if value.count == 2 {
                let predicate = CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: key))
                let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
                
                let contacts = try? contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                
                if let contact = contacts?.first {
                    let displayName = "\(contact.givenName) \(contact.familyName)"
                    let contactImage = contact.thumbnailImageData
                    let friendsOnRoll = value[1] as? Int ?? 0
                    
                    introContacts.append(IntroContacts(displayName: displayName, contactImage: contactImage, profileImage: nil, strippedPhoneNumber: key, friendsOnRoll: friendsOnRoll))
                    introContactsCount += 1 // Increment the counter
                    print("Generating intro contact: \(introContactsCount)")
                }
            }
        }
        
        print("Number of introContacts generated: \(introContactsCount)") // Print the count of introContacts generated
        self.sortedIntroContacts = introContacts
        
        self.generateSuggestions()
    }

    /* Duplicate code from the friends view model */
    func generateSuggestions() {
        print("Entering generate suggestions")
        var allPotentialSuggestions: Set<String> = []
        var suggestions: [String] = []
        var mutualFriendsCount: [String: Int] = [:]
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser?.uid ?? "test"
        // Fetch current user's friends, contact list, and blocked users
        db.collection("users").document(userID).getDocument { [weak self] (documentSnapshot, error) in
            guard let self = self, let userData = documentSnapshot?.data(), error == nil else { return }
            let userFriends = Set(userData["friends"] as? [String] ?? [])
            let userContacts = Set(userData["contactList"] as? [String] ?? [])
            let userBlocked = Set(userData["blocked"] as? [String] ?? [])

            // Fetch all users to start forming potential suggestions
            db.collection("users").getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents, error == nil else { return }

                for document in documents {
                    let id = document.documentID
                    let blockedByUsers = Set(document.data()["blocked"] as? [String] ?? [])
                    if !userFriends.contains(id) && !userContacts.contains(id) && !userBlocked.contains(id) && !blockedByUsers.contains(userID) && id != userID {
                        allPotentialSuggestions.insert(id)
                    }
                }

                // Remove friends of friends and blocked users from potential suggestions
                let dispatchGroup = DispatchGroup()
                for friendID in userFriends {
                    dispatchGroup.enter()
                    db.collection("users").document(friendID).getDocument { (docSnapshot, err) in
                        defer { dispatchGroup.leave() }
                        if let friendData = docSnapshot?.data(), err == nil {
                            let friendsOfFriend = Set(friendData["friends"] as? [String] ?? [])
                            allPotentialSuggestions.subtract(friendsOfFriend)
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    // Calculate mutual friends count for remaining suggestions
                    for suggestionID in allPotentialSuggestions {
                        db.collection("users").document(suggestionID).getDocument { (suggestionDocSnapshot, suggestionError) in
                            guard let suggestionData = suggestionDocSnapshot?.data(), suggestionError == nil else { return }
                            let suggestionFriends = Set(suggestionData["friends"] as? [String] ?? [])
                            let mutualFriends = suggestionFriends.intersection(userFriends)
                            mutualFriendsCount[suggestionID] = mutualFriends.count
                        }
                    }

                    // Sort final suggestions by mutual friends count and save to user's document
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Delay to ensure all async tasks are completed
                        suggestions = allPotentialSuggestions.sorted { (first, second) -> Bool in
                            let firstCount = mutualFriendsCount[first] ?? 0
                            let secondCount = mutualFriendsCount[second] ?? 0
                            return firstCount > secondCount
                        }
                        db.collection("users").document(userID).updateData(["suggestions": suggestions]) { error in
                            if let error = error {
                                print("Error updating suggestions: \(error.localizedDescription)")
                            } else {
                                print("Suggestions updated successfully with \(suggestions.count) suggestions.")
                            }
                        }
                    }
                }
            }
        }
    }


    
}
