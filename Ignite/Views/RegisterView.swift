//
//  RegisterView.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join our platform for teen entrepreneurs and investors")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 16) {
                    // Full Name
                    TextField("Full Name", text: $viewModel.name)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    
                    // Email
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    
                    // Password
                    SecureField("Password (min. 6 characters)", text: $viewModel.password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    
                    // Confirm Password
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                    
                    // User Type Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I am a:")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            userTypeButton(type: .entrepreneur, title: "Entrepreneur", icon: "lightbulb.fill")
                            userTypeButton(type: .investor, title: "Investor", icon: "dollarsign.circle.fill")
                        }
                    }
                    .padding(.top, 5)
                    
                    // Error Message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                
                // Terms and Conditions
                HStack {
                    Button(action: { viewModel.agreedToTerms.toggle() }) {
                        Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.agreedToTerms ? .blue : .gray)
                    }
                    
                    Text("I agree to the ")
                        .foregroundColor(.secondary)
                    
                    Button(action: { viewModel.showTerms = true }) {
                        Text("Terms & Conditions")
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                .font(.subheadline)
                
                // Sign Up Button
                Button(action: viewModel.register) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
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
                
                // Sign In Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.secondary)
                    
                    Button(action: { dismiss() }) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.subheadline)
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $viewModel.showTerms) {
            TermsView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registration Successful", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your account has been created successfully. You can now sign in.")
        }
    }
    
    private func userTypeButton(type: UserType, title: String, icon: String) -> some View {
        Button(action: { viewModel.userType = type }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.userType == type ? .white : .blue)
                    .padding(.bottom, 4)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.userType == type ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.userType == type ? Color.blue : Color.gray.opacity(0.1))
            )
        }
    }
}

// Terms and Conditions View
struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms and Conditions")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Last Updated: April 6, 2025")
                            .foregroundColor(.secondary)
                        
                        Text("1. Introduction")
                            .font(.headline)
                        
                        Text("Welcome to Teen Business Connect. By using our app, you agree to these terms and conditions.")
                        
                        Text("2. Age Requirement")
                            .font(.headline)
                        
                        Text("Entrepreneurs must be between 13-19 years old. Investors must be 18 years or older.")
                        
                        Text("3. User Accounts")
                            .font(.headline)
                        
                        Text("You are responsible for maintaining the confidentiality of your account information.")
                    }
                    
                    Group {
                        Text("4. Investment Rules")
                            .font(.headline)
                        
                        Text("All investments are subject to applicable securities laws. Teen Business Connect does not provide investment advice.")
                        
                        Text("5. Platform Rules")
                            .font(.headline)
                        
                        Text("Users may not post inappropriate content or harass other users. Teen Business Connect reserves the right to remove any content.")
                    }
                }
                .padding()
            }
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel for RegisterView
class RegisterViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var userType: UserType = .entrepreneur
    @Published var agreedToTerms = false
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showTerms = false
    @Published var showSuccessAlert = false
    
    var isValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreedToTerms
    }
    
    func register() {
        guard isValid else {
            if !agreedToTerms {
                errorMessage = "You must agree to the Terms & Conditions"
            } else if password != confirmPassword {
                errorMessage = "Passwords do not match"
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters long"
            } else {
                errorMessage = "Please fill in all fields correctly"
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        AuthService.shared.signUp(
            email: email,
            password: password,
            name: name,
            userType: userType
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success:
                    self.showSuccessAlert = true
                    
                case .failure(let error):
                    switch error {
                    case .signUpFailed(let message):
                        self.errorMessage = message
                    case .profileUpdateFailed(let message):
                        self.errorMessage = message
                    default:
                        self.errorMessage = "Failed to create account"
                    }
                }
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RegisterView()
        }
    }
}
