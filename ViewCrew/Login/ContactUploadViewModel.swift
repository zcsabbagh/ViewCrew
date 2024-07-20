import Foundation
import SwiftUI
import Contacts
import FirebaseFirestore
import Combine
import FirebaseAuth
import CoreData

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

actor IntroContactsManager {
    var introContacts: [IntroContacts] = []
    
    func append(_ contact: IntroContacts) {
        introContacts.append(contact)
    }
    
    func getAndClear() -> [IntroContacts] {
        let contacts = introContacts
        introContacts.removeAll()
        return contacts
    }
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


    private let introContactsManager = IntroContactsManager()

     private func generateIntroContacts(from batch: [CNContact], processedNumbers: [String]) async {
        let db = Firestore.firestore()
        
        for (contact, number) in zip(batch, processedNumbers) {
            if let value = strippedToFirebaseDict[number] {
                if value.count == 3, let documentID = value[2] as? String {
                    do {
                        let docSnapshot = try await db.collection("users").document(documentID).getDocument()
                        if docSnapshot.exists {
                            let displayName = docSnapshot.get("displayName") as? String ?? ""
                            let profileImage = docSnapshot.get("profileImageURL") as? String ?? ""
                            let friendsOnRoll = (docSnapshot.get("friends") as? [String])?.count ?? 0
                            let firebaseDocument = docSnapshot.documentID
                            
                            let newContact = IntroContacts(displayName: displayName, contactImage: nil, profileImage: profileImage, strippedPhoneNumber: number, friendsOnRoll: friendsOnRoll, firebaseDocument: firebaseDocument)
                            await introContactsManager.append(newContact)
                        }
                    } catch {
                        print("Error fetching user document: \(error)")
                    }
                } else if value.count == 2 {
                    let displayName = "\(contact.givenName) \(contact.familyName)"
                    let contactImage = contact.thumbnailImageData
                    let friendsOnRoll = value[1] as? Int ?? 0
                    
                    let newContact = IntroContacts(displayName: displayName, contactImage: contactImage, profileImage: nil, strippedPhoneNumber: number, friendsOnRoll: friendsOnRoll)
                    await introContactsManager.append(newContact)
                }
            }
        }
        
        let newIntroContacts = await introContactsManager.getAndClear()
        await MainActor.run {
            self.sortedIntroContacts.append(contentsOf: newIntroContacts)
        }
    }

    func fetchAndProcessContactNumbers(userID: String) async {
        if contactsProcessed {
            return
        }
        
        let contactStore = CNContactStore()
        let keys = [CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactThumbnailImageDataKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        let batchSize = 100
        var currentBatch: [CNContact] = []
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try contactStore.enumerateContacts(with: request) { (contact, stop) in
                            currentBatch.append(contact)
                            
                            if currentBatch.count == batchSize {
                                Task {
                                    await self.processBatch(currentBatch, userID: userID)
                                }
                                currentBatch.removeAll()
                            }
                        }
                        
                        if !currentBatch.isEmpty {
                            Task {
                                await self.processBatch(currentBatch, userID: userID)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.contactsProcessed = true
                            UserDefaults.standard.set(true, forKey: "contactsUploaded")
                        }
                        
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            print("Failed to fetch contacts, error: \(error)")
        }
    }

    private func processBatch(_ batch: [CNContact], userID: String) async {
        let processedNumbers = batch.flatMap { contact -> [String] in
            contact.phoneNumbers.compactMap { phoneNumber -> String? in
                let digits = phoneNumber.value.stringValue.filter("0123456789".contains)
                guard digits.count >= 10 else { return nil }
                return String(digits.suffix(10))
            }
        }
        
        DispatchQueue.main.async {
            self.strippedContactList.append(contentsOf: processedNumbers)
        }
        
        await checkAndCreateContactDocuments(for: processedNumbers, userID: userID)
        await checkPhoneNumberExistenceInUsersCollection(for: processedNumbers)
        await sortStrippedToFirebaseDict()
        await generateIntroContacts(from: batch, processedNumbers: processedNumbers)
    }

    private func checkAndCreateContactDocuments(for numbers: [String], userID: String) async {
        let db = Firestore.firestore()
        
        for number in numbers {
            do {
                let querySnapshot = try await db.collection("contactNumbers").whereField("phoneNumber", isEqualTo: number).getDocuments()
                
                if querySnapshot.isEmpty {
                    let newDoc = try await db.collection("contactNumbers").addDocument(data: [
                        "phoneNumber": number,
                        "contactsOnApp": [userID]
                    ])
                    
                    DispatchQueue.main.async {
                        self.strippedToFirebaseDict[number] = [newDoc.documentID, 1]
                    }
                } else if let document = querySnapshot.documents.first {
                    let docRef = db.collection("contactNumbers").document(document.documentID)
                    var contactsOnApp = document.data()["contactsOnApp"] as? [String] ?? []
                    if !contactsOnApp.contains(userID) {
                        contactsOnApp.append(userID)
                        try await docRef.updateData(["contactsOnApp": contactsOnApp])
                    }
                    
                    DispatchQueue.main.async {
                        self.strippedToFirebaseDict[number] = [document.documentID, contactsOnApp.count]
                    }
                }
            } catch {
                print("Error processing number \(number): \(error)")
            }
        }
    }

    private func checkPhoneNumberExistenceInUsersCollection(for numbers: [String]) async {
        let db = Firestore.firestore()
        
        for number in numbers {
            do {
                let querySnapshot = try await db.collection("users").whereField("phoneNumber", isEqualTo: number).getDocuments()
                
                if let documentID = querySnapshot.documents.first?.documentID {
                    DispatchQueue.main.async {
                        self.strippedToFirebaseDict[number]?.append(documentID)
                    }
                }
            } catch {
                print("Error checking number \(number) in users collection: \(error)")
            }
        }
    }

    private func sortStrippedToFirebaseDict() async {
        await MainActor.run {
            self.sortedStrippedContactList = self.strippedToFirebaseDict.keys.sorted { firstKey, secondKey in
                guard let firstValue = self.strippedToFirebaseDict[firstKey],
                      let secondValue = self.strippedToFirebaseDict[secondKey] else {
                    return false
                }
                if firstValue.count > 2, secondValue.count <= 2 {
                    return true
                } else if firstValue.count <= 2, secondValue.count > 2 {
                    return false
                } else {
                    return (firstValue[1] as? Int ?? 0) > (secondValue[1] as? Int ?? 0)
                }
            }
        }
    }

    

    func generateSuggestions() {
        Task {
            await generateSuggestionsAsync()
        }
    }

    private func generateSuggestionsAsync() async {
        print("Entering generate suggestions")
        var allPotentialSuggestions: Set<String> = []
        var suggestions: [String] = []
        var mutualFriendsCount: [String: Int] = [:]
        let db = Firestore.firestore()
        let userID = UserDefaults.standard.string(forKey: "userID") ?? "test"
        
        do {
            let userDoc = try await db.collection("users").document(userID).getDocument()
            guard let userData = userDoc.data() else { return }
            
            let userFriends = Set(userData["friends"] as? [String] ?? [])
            let userContacts = Set(userData["contactList"] as? [String] ?? [])
            let userBlocked = Set(userData["blocked"] as? [String] ?? [])

            let usersSnapshot = try await db.collection("users").getDocuments()
            
            for document in usersSnapshot.documents {
                let id = document.documentID
                let blockedByUsers = Set(document.data()["blocked"] as? [String] ?? [])
                if !userFriends.contains(id) && !userContacts.contains(id) && !userBlocked.contains(id) && !blockedByUsers.contains(userID) && id != userID {
                    allPotentialSuggestions.insert(id)
                }
            }

            for friendID in userFriends {
                let friendDoc = try await db.collection("users").document(friendID).getDocument()
                if let friendData = friendDoc.data() {
                    let friendsOfFriend = Set(friendData["friends"] as? [String] ?? [])
                    allPotentialSuggestions.subtract(friendsOfFriend)
                }
            }

            for suggestionID in allPotentialSuggestions {
                let suggestionDoc = try await db.collection("users").document(suggestionID).getDocument()
                if let suggestionData = suggestionDoc.data() {
                    let suggestionFriends = Set(suggestionData["friends"] as? [String] ?? [])
                    let mutualFriends = suggestionFriends.intersection(userFriends)
                    mutualFriendsCount[suggestionID] = mutualFriends.count
                }
            }

            suggestions = allPotentialSuggestions.sorted { (first, second) -> Bool in
                let firstCount = mutualFriendsCount[first] ?? 0
                let secondCount = mutualFriendsCount[second] ?? 0
                return firstCount > secondCount
            }

            try await db.collection("users").document(userID).updateData(["suggestions": suggestions])
            print("Suggestions updated successfully with \(suggestions.count) suggestions.")
        } catch {
            print("Error generating suggestions: \(error)")
        }
    }
}
