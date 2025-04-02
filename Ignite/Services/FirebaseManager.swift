//
//  FirebaseManager.swift
//  Ignite
//
//  Created by Henry Bowman on 4/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

/// Central manager for Firebase services
class FirebaseManager {
    // MARK: - Singleton
    static let shared = FirebaseManager()
    
    // MARK: - Properties
    private(set) var isConfigured = false
    
    // MARK: - Firebase Services
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure Firebase for the app
    func configure() {
        guard !isConfigured else { return }
        
        // Only configure Firebase once
        FirebaseApp.configure()
        
        // Set up Firestore settings
        let settings = db.settings
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        // Set up caching for Storage
        storage.maxUploadRetryTime = 60
        storage.maxDownloadRetryTime = 60
        
        isConfigured = true
        print("Firebase configured successfully")
    }
    
    // MARK: - Helpers
    
    /// Get a reference to a Firestore document
    func document(collection: String, id: String) -> DocumentReference {
        return db.collection(collection).document(id)
    }
    
    /// Get a reference to a Firestore collection
    func collection(_ path: String) -> CollectionReference {
        return db.collection(path)
    }
    
    /// Get a reference to a Storage file path
    func storageReference(path: String) -> StorageReference {
        return storage.reference().child(path)
    }
    
    /// Generate a unique ID for documents
    func generateID() -> String {
        return db.collection("_").document().documentID
    }
    
    // MARK: - User Management
    
    /// Get the current user ID
    var currentUserID: String? {
        return auth.currentUser?.uid
    }
    
    /// Check if a user is signed in
    var isUserSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    // MARK: - Transaction Helpers
    
    /// Run a transaction with Firestore
    func runTransaction<T>(_ updateBlock: @escaping (Transaction) throws -> T?, completion: @escaping (Result<T?, Error>) -> Void) {
        db.runTransaction(updateBlock) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(result))
            }
        }
    }
    
    /// Run a batch write operation with Firestore
    func performBatchOperation(_ operations: @escaping (WriteBatch) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = db.batch()
        operations(batch)
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
