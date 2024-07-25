//
//  NewNewFriendsModel.swift
//  Roll
//
//  Created by Zane Sabbagh on 5/23/24.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Contacts
import UIKit

/* 

TODO: REMOVE YOUR OWN USERNAME FROM THE let currentUserID = statements

*/


struct PersonToAdd {
    var name: String
    var contactImageURL: String?
    var contactImage: UIImage?
    var friends: [String]
    var phoneNumber: String?
    var userID: String?
    var username: String?
    var isFriend: Bool?
}


class NewNewFriendsViewModel: ObservableObject {
    
    @Published var friendsChanged: Bool = true
    @Published var userID: String = ""
    @Published var userProfile: PersonToAdd = PersonToAdd(name: "", friends: [])
    @Published var friendProfiles: [PersonToAdd] = [PersonToAdd]()
    @Published var matchedFriends: [PersonToAdd] = [PersonToAdd]()
    
    @Published var suggestionsOnApp: [PersonToAdd] = []
    @Published var suggestionsFromContacts: [PersonToAdd] = []
    
    @Published var matchedContacts: [PersonToAdd] = []
    @Published var searchResults: [PersonToAdd] = []
    
    @Published var blockedUsers: [String] = []
    @Published var allRequests: [String] = []
    @Published var friendsToRemove: [String] = []
    
     private let sharedDefaults: UserDefaults
    @Published var friendUserIDs: [String] = []
    @Published var friendDisplayNames: [String] = []
    
    @Published var incomingRequests: [PersonToAdd] = []
    
    private let REQUEST_LIMIT: Int = 50 // max num of results to show
    
    init() {
        // Load friendUserIDs and friendDisplayNames from UserDefaults
        self.sharedDefaults = UserDefaults(suiteName: "group.zane.ShareDefaults")!

        // Load friendUserIDs and friendDisplayNames from sharedDefaults
        self.friendUserIDs = UserDefaults.standard.array(forKey: "friendUserIDs") as? [String] ?? []
        self.friendDisplayNames = UserDefaults.standard.array(forKey: "friendDisplayNames") as? [String] ?? []
        
        /* get user's info */
        // modify this next line in case it can't find auth
        // set self.userID to the userID value of userdefaults
        self.userID = UserDefaults.standard.string(forKey: "userID") ?? "XwpBrxfjzaksc6hUJZPz"
        createUserFromUserID(self.userID) { personToAdd in
            if let personToAdd = personToAdd {
                self.userProfile = personToAdd
                self.generateFriendSuggestions()
                self.generateContactSuggestions()
                self.createUsersFromUserIDs(self.userProfile.friends) { friendProfiles in
                    self.friendProfiles = friendProfiles
                    self.friendUserIDs = friendProfiles.map { $0.userID ?? "" }
                    self.friendDisplayNames = friendProfiles.map { $0.name }
                    
                    // Save updated friendUserIDs and friendDisplayNames to UserDefaults
                    UserDefaults.standard.set(self.friendUserIDs, forKey: "friendUserIDs")
                    // also save to shared defaults
                    self.sharedDefaults.set(self.friendUserIDs, forKey: "friendIDs")
                    if let friendIDs = self.sharedDefaults.stringArray(forKey: "friendIDs") {
                        print("SharedDefaults friendIDs: \(friendIDs)")
                    } else {
                        print("No friendIDs found in SharedDefaults")
                    }
                    self.sharedDefaults.set(self.friendDisplayNames, forKey: "friendDisplayNames")
                    self.saveFriendProfileImages(friendProfiles)
                }
            }
        }
        
        findBlockedUsers()
        findAllRequests()
        listenForFriendRequestsAndChanges()
    }

    /* Saves images to Shared Defaults so we can access in Widget - NOT SURE IF WORKING */
    func saveFriendProfileImages(_ friendProfiles: [PersonToAdd]) {
        let group = DispatchGroup()
        
        for friend in friendProfiles {
            if let imageURL = friend.contactImageURL, let url = URL(string: imageURL) {
                print("Attempting to save image for URL: \(imageURL)")
                group.enter()
                URLSession.shared.dataTask(with: url) { data, response, error in
                    defer { group.leave() }
                    if let data = data, let image = UIImage(data: data) {
                        let resizedImage = self.resizeImage(image, targetSize: CGSize(width: 100, height: 100))
                        if let resizedData = resizedImage.pngData() {
                            let filename = self.getFilenameFromURL(imageURL)
                            if let savedURL = self.saveImageToSharedContainer(resizedData, filename: filename) {
                                print("Successfully saved resized image for URL: \(imageURL) at \(savedURL)")
                            } else {
                                print("Failed to save resized image for URL: \(imageURL)")
                            }
                        } else {
                            print("Failed to convert resized image to PNG data for URL: \(imageURL)")
                        }
                    } else {
                        print("Failed to download or create image from data for URL: \(imageURL)")
                        if let error = error {
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }.resume()
            } else {
                print("Invalid or missing image URL for friend: \(friend.name)")
            }
        }
        
        group.notify(queue: .main) {
            print("Finished processing all friend profile images")
        }
    }

    func getFilenameFromURL(_ url: String) -> String {
        return (url as NSString).lastPathComponent
    }

    func saveImageToSharedContainer(_ imageData: Data, filename: String) -> URL? {
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.zane.ShareDefaults") else {
            print("Failed to get shared container URL")
            return nil
        }
        
        let fileURL = sharedContainer.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving image to shared container: \(error)")
            return nil
        }
    }

    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    /*
     CODE TO LISTEN FOR CHANGES IN FRIEND REQUESTS AND FRIENDS
     */
    
    func removeFriends() {
        let currentUserID = self.userID
        let db = Firestore.firestore()
        let userQuery = db.collection("users").whereField("userID", isEqualTo: currentUserID)
        
        userQuery.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding user document: \(error)")
            } else {
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for user")
                    return
                }
                let userDocID = document.documentID
                db.collection("users").document(userDocID).updateData([
                    "friends": FieldValue.arrayRemove(self.friendsToRemove)
                ]) { error in
                    if let error = error {
                        print("Error removing friends: \(error)")
                    } else {
                        print("Friends successfully removed")
                    }
                }
            }
        }
    }
    
    
    func listenForFriendRequestsAndChanges() {
        let db = Firestore.firestore()
        
        // Listening for changes in the 'friends' array
        db.collection("users").whereField("userID", isEqualTo: self.userID)
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if diff.type == .modified {
                        let data = diff.document.data()
                        if let friends = data["friends"] as? [String] {
                            self.userProfile.friends = friends
                            print("Updated friends list: \(friends)")
                            print("old value of friendsChanged: \(self.friendsChanged)")
                            self.friendsChanged.toggle()
                            print("new value of friendsChanged: \(self.friendsChanged)")
                        }
                    }
                }
            }
        
        // Listening for new friend requests
        db.collection("friendRequests").whereField("to", isEqualTo: self.userID).whereField("status", isEqualTo: "pending")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error listening for friend requests updates: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        let requestData = diff.document.data()
                        let fromUserID = requestData["from"] as? String ?? "Unknown"
                        // Optionally, fetch user details and update UI
                        self.createUserFromUserID(fromUserID) { personToAdd in
                            if let person = personToAdd {
                                DispatchQueue.main.async {
                                    self.incomingRequests.append(person)
                                    
                                }
                            }
                        }
                    }
                }
            }
    }
    
    
    
    
    /*
     CODE TO GENERATE SUGGESTIONS
     */
    
    func generateFriendSuggestions() {
        findUsersWithMutualFriends { mutualFriendsDict in
            print("Found this many people with mutuals friends: \(mutualFriendsDict.count)")
            let sortedUserIDs = mutualFriendsDict.sorted { $0.value > $1.value }
                .map { $0.key }
                .filter { $0 != self.userID && !self.blockedUsers.contains($0) && !self.allRequests.contains($0) }
            
            self.createUsersFromUserIDs(sortedUserIDs) { personsToAdd in
                DispatchQueue.main.async {
                    self.suggestionsOnApp = personsToAdd
                }
            }
        }
    }
    
    func findUsersWithMutualFriends(completion: @escaping ([String: Int]) -> Void) {
        var mutualFriendsCount = [String: Int]()
        let userFriends = userProfile.friends
        print("Found this many userFriends: \(userFriends.count)")
        let group = DispatchGroup()
        
        for friendUserID in userFriends {
            group.enter()
            fetchFriendsForUserID(friendUserID) { friendList in
                for mutualFriendUserID in friendList where !userFriends.contains(mutualFriendUserID) {
                    mutualFriendsCount[mutualFriendUserID, default: 0] += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(mutualFriendsCount)
        }
    }
    
    func fetchFriendsForUserID(_ userID: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("userID", isEqualTo: userID).getDocuments { (querySnapshot, error) in
            if let querySnapshot = querySnapshot, !querySnapshot.documents.isEmpty {
                let friends = querySnapshot.documents.first?.data()["friends"] as? [String] ?? []
                let friendUserIds = friends
                completion(friends)
            } else {
                print("Document does not exist or error fetching friends for userID: \(userID)")
                completion([])
            }
        }
    }
    
    
    
    
    
    /*
     CODE FOR UPDATING FRIEND REQUESTS
     */
    
    
    
    let db = Firestore.firestore()
    /* Function to create a friend request */
    func createFriendRequest(to: String, from: String) {
        let newRequest = ["to": to, "from": from, "status": "pending", "timestamp": FieldValue.serverTimestamp()] as [String: Any]
        db.collection("friendRequests").addDocument(data: newRequest) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                print("Document added with ID: \(to)")
                Task {
                    try await FirebaseNotificationGenerator.shared.sendFriendRequestNotification(fromUser: from, toUser: to)
                }
            }
        }
    }
    
    /* Function to update the status of a friend request */
    func updateFriendRequestStatus(to: String, from: String, newStatus: String) {
        db.collection("friendRequests").whereField("to", isEqualTo: to).whereField("from", isEqualTo: from).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    self.db.collection("friendRequests").document(document.documentID).updateData(["status": newStatus])
                }
            }
        }
    }
    
    /* Function to handle accepted friend requests */
    func acceptFriendRequest(to: String, from: String) {
        print("Start accept Friends)")
        let userRef = db.collection("users")
        userRef.whereField("userID", isEqualTo: to).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    var friendsArray = document.data()["friends"] as? [String] ?? []
                    if !friendsArray.contains(from) {
                        friendsArray.append(from)
                        userRef.document(to).updateData(["friends": friendsArray])
                    }
                }
            }
            print("FINISH accept friends")
            
        }
        
        userRef.whereField("userID", isEqualTo: from).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    var friendsArray = document.data()["friends"] as? [String] ?? []
                    if !friendsArray.contains(to) {
                        friendsArray.append(to)
                        userRef.document(from).updateData(["friends": friendsArray])
                    }
                }
            }
        }
        Task {
            try await FirebaseNotificationGenerator.shared.sendAcceptFriendRequestNotification(fromUser: from, toUser: to)
        }
    }
    
    
    
    
    
    
    
    
    
    
    /*
     CODE FOR FETCHING ALL FRIEND REQUESTS
     */
    
    /* return all people who've sent friend request */
    func findAllRequests() {
        var allRequests: Set<String> = []
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        fetchOutgoingRequests { [weak self] outgoingUserIDs in
            allRequests.formUnion(outgoingUserIDs)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchIncomingRequests { [weak self] incomingUserIDs in
            allRequests.formUnion(incomingUserIDs)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.allRequests = Array(allRequests)
        }
    }
    
    
    
    /* return all people who user received friend requests to */
    func fetchOutgoingRequests(completion: @escaping ([String]) -> Void) {
        var userIDs: [String] = []
        let friendRequestsCollection = Firestore.firestore().collection("friendRequests")
        friendRequestsCollection.whereField("status", isEqualTo: "pending")
            .whereField("from", isEqualTo: self.userID)
            .getDocuments { (querySnapshot, err) in
                if let querySnapshot = querySnapshot {
                    for document in querySnapshot.documents {
                        if let toUserID = document.data()["to"] as? String {
                            userIDs.append(toUserID)
                        }
                    }
                }
                print("Outgoing number of requests: \(userIDs.count)")
                completion(userIDs)
            }
    }
    
    /* return all people who user sent friend requests to */
    func fetchIncomingRequests(completion: @escaping ([String]) -> Void) {
        var userIDs: [String] = []
        let friendRequestsCollection = Firestore.firestore().collection("friendRequests")
        friendRequestsCollection.whereField("status", isEqualTo: "pending")
            .whereField("to", isEqualTo: self.userID)
            .getDocuments { (querySnapshot, err) in
                if let querySnapshot = querySnapshot {
                    for document in querySnapshot.documents {
                        if let fromUserID = document.data()["from"] as? String {
                            userIDs.append(fromUserID)
                        }
                    }
                }
                print("Incoming number of requests: \(userIDs.count), with userIDs \(userIDs)")
                self.createUsersFromUserIDs(userIDs) { personsToAdd in
                    self.incomingRequests = personsToAdd
                    print("Found this many incoming request profiles: \(self.incomingRequests.count)")
                    
                }
                completion(userIDs)
            }
    }
    
    
    
    
    
    
    
    
    /*
     CREATE [PersonToAdd] FROM USER IDs or DOCUMENT IDs
     */
    
    /* use these two functions to get PersonToAdd from a userID */
    func createUsersFromUserIDs(_ userIDs: [String], completion: @escaping ([PersonToAdd]) -> Void) {
        var personsToAdd: [PersonToAdd] = []
        let group = DispatchGroup()
        
        for userID in userIDs {
            group.enter()
            createUserFromUserID(userID) { personToAdd in
                if let person = personToAdd {
                    personsToAdd.append(person)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(personsToAdd)
        }
    }
    
    func createUserFromUserID(_ userID: String, completion: @escaping (PersonToAdd?) -> Void) {
        guard !userID.isEmpty else {
            print("Error: userID is empty")
            completion(nil)
            return
        }

        let db = Firestore.firestore()
        let userDocument = db.collection("users").document(userID)
        
        print("Fetching document for userID: \(userID)")
        
        userDocument.getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error.localizedDescription)")
                completion(nil)
            } else {
                if let document = document, document.exists {
                    let data = document.data() ?? [:]
                    let person = PersonToAdd(
                        name: data["displayName"] as? String ?? "",
                        contactImageURL: data["profileImageURL"] as? String,
                        friends: data["friends"] as? [String] ?? [],
                        phoneNumber: data["phoneNumber"] as? String,
                        userID: data["userID"] as? String,
                        username: data["username"] as? String
                    )
                    completion(person)
                } else {
                    print("Document does not exist for userID: \(userID)")
                    self.friendsToRemove.append(userID)
                    completion(nil)
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    /*
     CODE TO SEARCH THROUGH DATABASE
     */

    func searchFriends(matching query: String) {
        self.matchedFriends = self.friendProfiles.filter { person in
            let nameContainsQuery = person.name.lowercased().contains(query.lowercased())
            let usernameContainsQuery = person.username?.lowercased().contains(query.lowercased()) ?? false
            return nameContainsQuery || usernameContainsQuery
        }
    }
    
    /* returns all users matching an inputted string and creates an array of [PersonToAdd] for the results */
    func searchAllUsers(matching string: String) {
        searchUsersByDisplayNameOrUsername(containing: string) { userIDs in
            self.createUsersFromUserIDs(userIDs) { persons in
                self.searchResults = persons
            }
        }
    }
    
    /* return all usernames & display names that match, excluding user's friends, blocked users, people that have sent or received friend requests */
    func searchUsersByDisplayNameOrUsername(containing string: String, completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()
            var displayNameResults: [String] = []
            var usernameResults: [String] = []
            
            group.enter()
            self.searchUsersByDisplayName(containing: string) { ids in
                displayNameResults = ids
                group.leave()
            }
            
            group.enter()
            self.searchUsersByUsername(containing: string) { ids in
                usernameResults = ids
                group.leave()
            }
            
            group.notify(queue: .main) {
                var combinedResults = displayNameResults + usernameResults
                combinedResults = combinedResults.filter { !self.blockedUsers.contains($0) }
                combinedResults = combinedResults.filter { !self.allRequests.contains($0) }
                combinedResults = combinedResults.filter { !self.userProfile.friends.contains($0) }
                let uniqueResults = Set(combinedResults)
                DispatchQueue.main.async {
                    completion(Array(uniqueResults.prefix(self.REQUEST_LIMIT)))
                }
            }
        }
    }
    
    // Function to search users by displayName containing a given string
    func searchUsersByDisplayName(containing name: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("displayName", isGreaterThanOrEqualTo: name)
            .whereField("displayName", isLessThanOrEqualTo: name + "\u{f8ff}")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completion([])
                } else {
                    let userIDs = querySnapshot?.documents.compactMap { $0.data()["userID"] as? String } ?? []
                    completion(userIDs)
                }
            }
    }
    
    // Function to search users by username containing a given string
    func searchUsersByUsername(containing username: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isGreaterThanOrEqualTo: username)
            .whereField("username", isLessThanOrEqualTo: username + "\u{f8ff}")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completion([])
                } else {
                    let userIDs = querySnapshot?.documents.compactMap { $0.data()["userID"] as? String } ?? []
                    completion(userIDs)
                }
            }
    }
    
    
    
    
    
    
    
    
    
    
    /*
     CODE TO SEARCH THROUGH CONTACTS AND SUGGEST CONTACTS
     */
    
    /* returns a ranked list of contact suggestions based on who has the most friends on app */
    func generateContactSuggestions() {
      
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        guard authorizationStatus == .authorized else {
            print("Contact access not authorized")
            return
        }

        let store = CNContactStore()
        DispatchQueue.global(qos: .userInitiated).async {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            do {
                try store.enumerateContacts(with: request) { (contact, stop) in
                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    let contactImage = contact.imageData != nil ? UIImage(data: contact.imageData!) : nil
                    let phoneNumber = contact.phoneNumbers.first?.value.stringValue.filter("0123456789".contains)
                    let strippedPhoneNumber = phoneNumber?.suffix(10)
                    
                    if let strippedNumber = strippedPhoneNumber {
                        // Check if phoneNumber exists in the "users" collection
                        let db = Firestore.firestore()
                        db.collection("users")
                            .whereFilter(Filter.orFilter([
                                Filter.whereField("phoneNumber", isEqualTo: String(strippedNumber)),
                                Filter.whereField("strippedPhoneNumber", isEqualTo: String(strippedNumber))
                            ]))
                            .getDocuments { (querySnapshot, error) in
                                if let error = error {
                                    print("Error checking phone number: \(error)")
                                } else if querySnapshot!.documents.isEmpty {
                                    // If phoneNumber does not exist in the database, proceed to fetch friends
                                    self.fetchFriendsOnAppForContact(for: String(strippedNumber)) { fetchedFriends in
                                        let personToAdd = PersonToAdd(name: fullName, contactImageURL: nil, contactImage: contactImage, friends: fetchedFriends, phoneNumber: String(strippedNumber), userID: nil)
                                        DispatchQueue.main.async {
                                            self.suggestionsFromContacts.append(personToAdd)
                                            // Sort suggestionsFromContacts by the length of the friends array in descending order
                                            self.suggestionsFromContacts.sort { $0.friends.count > $1.friends.count }
                                        }
                                    }
                                }
                            }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to fetch contacts: \(error)")
                }
            }
        }
    }
    
    /* searches and returns all contacts given an input string */
    func searchContacts(matching name: String) {
        self.matchedContacts = []  // Clear previous results
        
      
        let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        guard authorizationStatus == .authorized else {
            print("Contact access not authorized")
            return
        }

        let store = CNContactStore()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactImageDataKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            do {
                try store.enumerateContacts(with: request) { (contact, stop) in
                    if contact.givenName.lowercased().contains(name.lowercased()) || contact.familyName.lowercased().contains(name.lowercased()) {
                        let fullName = "\(contact.givenName) \(contact.familyName)"
                        let contactImage = contact.imageData != nil ? UIImage(data: contact.imageData!) : nil
                        let phoneNumber = contact.phoneNumbers.first?.value.stringValue.filter("0123456789".contains)
                        let strippedPhoneNumber = phoneNumber?.suffix(10)
                        
                        if let strippedNumber = strippedPhoneNumber {
                            // Check if phoneNumber exists in the "users" collection
                            let db = Firestore.firestore()
                            db.collection("users")
                                /* TO DO LATER: Correct this to use strippedPhoneNumber only */ 
                                .whereFilter(Filter.orFilter([
                                    Filter.whereField("phoneNumber", isEqualTo: String(strippedNumber)),
                                    Filter.whereField("strippedPhoneNumber", isEqualTo: String(strippedNumber))
                                ]))
                                .getDocuments { (querySnapshot, error) in
                                    if let error = error {
                                        print("Error checking phone number: \(error)")
                                    } else if querySnapshot!.documents.isEmpty {
                                        // If phoneNumber does not exist in the database, proceed to fetch friends
                                        self.fetchFriendsOnAppForContact(for: String(strippedNumber)) { fetchedFriends in
                                            let personToAdd = PersonToAdd(name: fullName, contactImageURL: nil, contactImage: contactImage, friends: fetchedFriends, phoneNumber: String(strippedNumber), userID: nil)
                                            DispatchQueue.main.async {
                                                self.matchedContacts.append(personToAdd)
                                                // Optionally sort matchedContacts by the length of the friends array in descending order
                                                self.matchedContacts.sort { $0.friends.count > $1.friends.count }
                                            }
                                        }
                                    }
                                }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to fetch contacts: \(error)")
                }
            }
        }
    }
    
    /* returns the number of friends a contact has on the app */
    func fetchFriendsOnAppForContact(for phoneNumber: String, completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        let query = db.collection("contactNumbers").whereField("phoneNumber", isEqualTo: phoneNumber)
        
        query.getDocuments { (querySnapshot, error) in
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                let contacts = querySnapshot.documents.first?.data()["contactsOnApp"] as? [String] ?? []
                completion(contacts)
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    /*
     ALL BLOCKING RELATED CODE BELOW
     */
    
    /* function to find document IDs of all users that are blocked or blockedBy user */
    func findBlockedUsers() {
        let currentUserID = self.userID
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUserID).getDocument { (document, error) in
            if let error = error {
                print("Error fetching user data: \(error)")
            } else if let document = document, document.exists {
                let blockedBy = document.data()?["blockedBy"] as? [String] ?? []
                let blocked = document.data()?["blocked"] as? [String] ?? []
                self.blockedUsers = blockedBy + blocked
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    /* function to mutually block users */
    func blockUser(otherUserID: String) {
        let currentUserID = self.userID
        let db = Firestore.firestore()
        
        // Add current user to the 'blockedBy' array of the other user
        let otherUserRef = db.collection("users").whereField("userID", isEqualTo: otherUserID)
        otherUserRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error updating other user's blockedBy: \(error)")
            } else {
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for other user")
                    return
                }
                let otherUserDocID = document.documentID
                db.collection("users").document(otherUserDocID).updateData([
                    "blockedBy": FieldValue.arrayUnion([currentUserID])
                ]) { error in
                    if let error = error {
                        print("Error adding current user to other user's blockedBy: \(error)")
                    }
                }
            }
        }
        
        // Add other user to the 'blocked' array of the current user
        let currentUserRef = db.collection("users").whereField("userID", isEqualTo: currentUserID)
        currentUserRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error updating current user's blocked: \(error)")
            } else {
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for current user")
                    return
                }
                let currentUserDocID = document.documentID
                db.collection("users").document(currentUserDocID).updateData([
                    "blocked": FieldValue.arrayUnion([otherUserID])
                ]) { error in
                    if let error = error {
                        print("Error adding other user to current user's blocked: \(error)")
                    }
                }
            }
        }

        friendProfiles.removeAll { $0.userID == otherUserID }
        matchedFriends.removeAll { $0.userID == otherUserID }
    }
    
    /* function to remove a user from another user's friends list */
    func unfriendUser(otherUserID: String) {
        let currentUserID = self.userID
        let db = Firestore.firestore()
        
        // Remove current user from the 'friends' array of the other user
        let otherUserRef = db.collection("users").whereField("userID", isEqualTo: otherUserID)
        otherUserRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error updating other user's friends: \(error)")
            } else {
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for other user")
                    return
                }
                let otherUserDocID = document.documentID
                db.collection("users").document(otherUserDocID).updateData([
                    "friends": FieldValue.arrayRemove([currentUserID])
                ]) { error in
                    if let error = error {
                        print("Error removing current user from other user's friends: \(error)")
                    }
                }
            }
        }
        
        // Remove other user from the 'friends' array of the current user
        let currentUserRef = db.collection("users").whereField("userID", isEqualTo: currentUserID)
        currentUserRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error updating current user's friends: \(error)")
            } else {
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for current user")
                    return
                }
                let currentUserDocID = document.documentID
                db.collection("users").document(currentUserDocID).updateData([
                    "friends": FieldValue.arrayRemove([otherUserID])
                ]) { error in
                    if let error = error {
                        print("Error removing other user from current user's friends: \(error)")
                    }
                }
            }
        }

        friendProfiles.removeAll { $0.userID == otherUserID }
        matchedFriends.removeAll { $0.userID == otherUserID }
    }
    
}








 /* use these two functions to get PersonToAdd from a documentID */
    // func createUsersFromDocumentIDs(_ documentIDs: [String], completion: @escaping ([PersonToAdd]) -> Void) {
    //     var personsToAdd: [PersonToAdd] = []
    //     let group = DispatchGroup()

    //     for documentID in documentIDs {
    //         group.enter()
    //         createUserFromDocumentID(documentID) { personToAdd in
    //             if let person = personToAdd {
    //                 personsToAdd.append(person)
    //             }
    //             group.leave()
    //         }
    //     }

    //     group.notify(queue: .main) {
    //         completion(personsToAdd)
    //     }
    // }


    // func createUserFromDocumentID(_ documentID: String, completion: @escaping (PersonToAdd?) -> Void) {
    //     let db = Firestore.firestore()
    //     db.collection("users").document(documentID).getDocument { (document, error) in
    //         if let document = document, document.exists {
    //             let data = document.data()
    //             let person = PersonToAdd(
    //                 name: data?["displayName"] as? String ?? "",
    //                 contactImageURL: data?["profileImageURL"] as? String,
    //                 friends: data?["friends"] as? [String] ?? [],
    //                 phoneNumber: data?["phoneNumber"] as? String,
    //                 userID: data?["userID"] as? String
    //             )
    //             completion(person)
    //         } else {
    //             print("Document does not exist")
    //             completion(nil)
    //         }
    //     }
    // }

