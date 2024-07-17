//
//  ProfileOptions.swift
//  vitalz-new
//
//  Created by Zane Sabbagh on 7/16/24.
//

import Foundation
import SwiftUI


struct ProfileOptions: View {
    let viewModel = ProfileOptionsViewModel()
    @State private var showLogOutAlert = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        VStack {       
            List {
                Section(header: Text("DANGER ZONE")) {
                    Button(action: {
                        showLogOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                    }
                    .alert(isPresented: $showLogOutAlert) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                viewModel.signOut()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    Button(action: {
                        showDeleteAccountAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                        .foregroundColor(.red)
                    }
                    .alert(isPresented: $showDeleteAccountAlert) {
                        Alert(
                            title: Text("Delete Account"),
                            message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.deleteAccount()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
        .colorScheme(.dark)
    }
}

struct ProfileOptions_Previews: PreviewProvider {
    static var previews: some View {
        ProfileOptions()
    }
}
