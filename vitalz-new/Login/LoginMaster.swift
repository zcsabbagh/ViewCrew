import SwiftUI

enum LoginState: String {
    case authentication
    case netflixSignIn
    case profileCreation
}

struct LoginMaster: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var hasRenderedNetflixSignIn = false
    
    var body: some View {
        switch viewModel.loginState {
        case .authentication:
            PhoneAuthentication(loginViewModel: viewModel, onComplete: {
                viewModel.moveToNextState()
            })
            .onAppear { print("Rendering PhoneAuthentication") }
        case .netflixSignIn:
            NetflixLoginView(viewModel: viewModel, onComplete: {
                viewModel.moveToNextState()
            })
            .onAppear { print("Rendering NetflixLoginView") }
        case .profileCreation:
           
            ProfileCreationView(viewModel: viewModel, onComplete: {
                viewModel.moveToNextState()
            })
            .onAppear { print("Rendering ProfileCreationView") }
        }
    }
}


struct SamplePage: View {
    let onComplete: () -> Void

    var body: some View {
        VStack {
            Button(action: {
                onComplete()
            }) {
                Text("Complete Action")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}
