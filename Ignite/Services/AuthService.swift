//
//  AuthService.swift
//  Ignite
//
//  Created for Teen Business Platform
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Combine

enum AuthError: Error {
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case userNotFound
    case profileUpdateFailed(String)
}

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = AuthService()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for authentication state changes
        let _ = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            if let user = user {
                self.isLoading = true
                self.fetchUserData(userId: user.uid) { fetchedUser in
                    self.isLoading = false
                    if let fetchedUser = fetchedUser {
                        self.currentUser = fetchedUser
                        self.isAuthenticated = true
                    } else {
                        self.isAuthenticated = false
                        self.error = "Failed to load user profile"
                    }
                }
            } else {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - Auth Methods
    
    func signUp(email: String, password: String, name: String, userType: UserType, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        error = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                completion(.failure(.signUpFailed(error.localizedDescription)))
                return
            }
            
            guard let authResult = result else {
                self.isLoading = false
                self.error = "Failed to create account"
                completion(.failure(.signUpFailed("Failed to create account")))
                return
            }
            
            let userId = authResult.user.uid
            
            // Create user profile
            let user = User(
                id: userId,
                email: email,
                name: name,
                userType: userType
            )
            
            // Save to Firestore
            self.db.collection("users").document(userId).setData(user.asDictionary()) { error in
                self.isLoading = false
                
                if let error = error {
                    self.error = error.localizedDescription
                    completion(.failure(.profileUpdateFailed(error.localizedDescription)))
                    return
                }
                
                self.currentUser = user
                self.isAuthenticated = true
                completion(.success(user))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        error = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.error = error.localizedDescription
                completion(.failure(.signInFailed(error.localizedDescription)))
                return
            }
            
            guard let userId = result?.user.uid else {
                self.isLoading = false
                self.error = "User ID not found"
                completion(.failure(.userNotFound))
                return
            }
            
            self.fetchUserData(userId: userId) { user in
                self.isLoading = false
                
                if let user = user {
                    self.currentUser = user
                    self.isAuthenticated = true
                    completion(.success(user))
                } else {
                    self.error = "Failed to load user profile"
                    completion(.failure(.userNotFound))
                }
            }
        }
    }
    
    func signOut(completion: @escaping (Result<Void, AuthError>) -> Void) {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
            completion(.success(()))
        } catch {
            self.error = error.localizedDescription
            completion(.failure(.signOutFailed(error.localizedDescription)))
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchUserData(userId: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            let user = User.fromFirestore(snapshot)
            completion(user)
        }
    }
    
    func updateUserProfile(user: User, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        error = nil
        
        db.collection("users").document(user.id).setData(user.asDictionary(), merge: true) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                completion(.failure(.profileUpdateFailed(error.localizedDescription)))
                return
            }
            
            self.currentUser = user
            completion(.success(user))
        }
    }
}
