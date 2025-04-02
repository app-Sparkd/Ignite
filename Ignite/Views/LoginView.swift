//
//  LoginView.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo and Header
            VStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Teen Business Connect")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to your account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            
            // Form Fields
            VStack(spacing: 16) {
                // Email Field
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                
                // Password Field
                SecureField("Password", text: $viewModel.password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                
                // Error Message
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                
                // Forgot Password Link
                Button(action: {
                    // Handle forgot password
                }) {
                    Text("Forgot password?")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
            }
            .padding(.horizontal)
            
            // Sign In Button
            Button(action: viewModel.signIn) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(viewModel.isLoading || !viewModel.isValid)
            .opacity(viewModel.isValid ? 1.0 : 0.6)
            
            // Divider
            HStack {
                VStack { Divider() }
                Text("OR")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                VStack { Divider() }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Sign Up Link
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    viewModel.showSignUp = true
                }) {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .font(.subheadline)
            
            Spacer()
        }
        .padding(.top, 50)
        .padding(.bottom, 20)
        .navigationDestination(isPresented: $viewModel.showSignUp) {
            Text("Registration Coming Soon")
            // We'll replace this with RegisterView once it's implemented
        }
    }
}

// ViewModel for the LoginView
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showSignUp = false
    
    var isValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    func signIn() {
        guard isValid else {
            errorMessage = "Please enter valid email and password"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        AuthService.shared.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    // Success is handled by the auth state listener in AuthService
                    // which updates isAuthenticated and currentUser
                    break
                    
                case .failure(let error):
                    switch error {
                    case .signInFailed(let message):
                        self.errorMessage = message
                    case .userNotFound:
                        self.errorMessage = "User not found"
                    default:
                        self.errorMessage = "Failed to sign in"
                    }
                }
            }
        }
    }
}

// MARK: - Authentication View Container
struct AuthenticationView: View {
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.light)
            
            LoginView()
                .preferredColorScheme(.dark)
        }
    }
}
