//
//  AddFriendsView.swift
//  Roll
//
//  Created by Zane Sabbagh on 5/23/24.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import MessageUI
import Contacts
import FirebaseAuth
import Combine

public struct FriendView: View {
    @State var searchText: String = ""
    @ObservedObject var viewModel: NewNewFriendsViewModel
    public var debouncer = Debouncer(delay: 0.5) 
    
    @State public var isMessageComposerPresented: Bool = false
    @State private var messageRecepients: [String] = []
    @State private var isContactAccessGranted: Bool = true
    @State private var contactUploadViewModel: ContactUploadViewModel = ContactUploadViewModel()
    
    public var body: some View {
        VStack (spacing: 5) {

            // Title
            friendsTitle
            
            
            // Alert if contacts haven't been allowed
            if !isContactAccessGranted {
                SettingsAlertView()
            }
            
            // Searh bar
            ClassySearchBar(searchText: $searchText)
                .onChange(of: searchText) { newValue in
                    debouncer.debounce {
                        viewModel.searchContacts(matching: newValue)
                        viewModel.searchAllUsers(matching: newValue)
                    }
                }

            ScrollView (showsIndicators: false) {

                // friends & friend search results
                FriendsListView(
                    searchText: $searchText,
                    viewModel: viewModel
                )
                

                if searchText == "" {
                    ShareButtons()
                }

                
                // suggestions & search results
                AddContactsListView(
                    searchText: $searchText,
                    viewModel: viewModel,
                    isMessageComposerPresented: $isMessageComposerPresented,
                    messageRecepients: $messageRecepients
                )
                
                
                
            }
        }
        .padding(.horizontal, 10)
        .background(Color.appBackground)
        .environment(\.colorScheme, .light) // Set environment color scheme to light
        .onAppear {
           requestContactsAccess()
        }
        .sheet(isPresented: $isMessageComposerPresented, onDismiss: {
            print("Message Composer was dismissed")
        }) {
            MessageComposerViewFriends(
                bodyMessage: "I need friends [on Vitalz]. Please help.\n\nHere's a link:\nhttps://apps.apple.com/us/app/vitalz-share-more/id6503488338",
                recipients: $messageRecepients
            )
        }
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
    
    public var friendsTitle: some View {
        Text("Friends")
            .font(.custom("Roboto-Bold", size: 25))
            .padding(.top, 10)
            .foregroundColor(.white)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)
    }

    public var contactSettings: some View {
        Group {
            if !isContactAccessGranted {
                SettingsAlertView()
            }
        }

    }

}





struct SettingsAlertView: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Change in Settings")
                    .font(.custom("Roboto-Regular", size: 17))
                    .underline()
                    .foregroundColor(.red)
                    .font(.headline)
            }
            .padding(.top, 10)
            
            Text("Sync your contacts to know which of your friends are already here.")
                .font(.custom("Roboto-Regular", size: 12))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.top, 5)
            
            Button(action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                HapticFeedbackGenerator.shared.generateHapticLight()
            }) {
                Text("Allow contacts")
                    .font(.custom("Roboto-Regular", size: 12))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 2)
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 15)
    }
}

struct ClassySearchBar: View {
    @Binding var searchText: String


    var body: some View {
        HStack {
            TextField("", text: $searchText)
                .foregroundColor(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 37)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .padding(.leading, 10)
                        if searchText.isEmpty {
                            Text("Search")
                                .font(.custom("Roboto-Regular", size: 15))
                                .foregroundColor(.white)
                        }

                        Spacer()
                        if !searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                                HapticFeedbackGenerator.shared.generateHapticLight()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.vertical, 5)
    }
}


public class Debouncer {
    public var timer: Timer?
    public let delay: TimeInterval

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    public func debounce(action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false, block: { _ in
            action()
        })
    }
}

struct MessageComposerViewFriends: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var bodyMessage: String
    @Binding var recipients: [String] // Changed to Binding
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.body = bodyMessage
        composer.recipients = recipients
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // Update the view controller if needed.
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposerViewFriends
        
        init(_ parent: MessageComposerViewFriends) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.presentationMode.wrappedValue.dismiss()
            // switch result {
            // case .sent:
            //     parent.$numInvited.wrappedValue += 1
            //     parent.$wasSent.wrappedValue = true
            //     print("sent")
            // case .cancelled:
            //     parent.$wasSent.wrappedValue = false
            //     print("cancelled")
            // case .failed:
            //     parent.$wasSent.wrappedValue = false
            //     print("failed")
            // @unknown default:
            //     parent.$wasSent.wrappedValue = false
            //     print("unknown result")
            // }
        }
    }
}
