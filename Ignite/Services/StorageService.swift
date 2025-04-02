//
//  StorageService.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage

enum StorageError: Error {
    case imageConversionFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case urlRetrievalFailed
    case deleteFailed(String)
    case invalidPath
}

/// Service to handle Firebase Storage operations
class StorageService {
    // MARK: - Singleton
    static let shared = StorageService()
    
    // MARK: - Properties
    private let storage = FirebaseManager.shared.storage.reference()
    private let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Upload Operations
    
    /// Upload an image to Firebase Storage
    /// - Parameters:
    ///   - image: UIImage to upload
    ///   - path: Storage path to save the image
    ///   - quality: Compression quality (0.0 to 1.0)
    ///   - metadata: Optional metadata for the upload
    ///   - completion: Result with the download URL or error
    func uploadImage(_ image: UIImage,
                     to path: String,
                     quality: CGFloat = 0.7,
                     metadata customMetadata: [String: String]? = nil,
                     completion: @escaping (Result<URL, StorageError>) -> Void) {
        
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            completion(.failure(.imageConversionFailed))
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        if let customMetadata = customMetadata {
            metadata.customMetadata = customMetadata
        }
        
        uploadData(imageData, to: path, metadata: metadata, completion: completion)
    }
    
    /// Upload Data to Firebase Storage
    /// - Parameters:
    ///   - data: Data to upload
    ///   - path: Storage path to save the data
    ///   - metadata: Optional metadata for the upload
    ///   - completion: Result with the download URL or error
    func uploadData(_ data: Data,
                    to path: String,
                    metadata: StorageMetadata? = nil,
                    completion: @escaping (Result<URL, StorageError>) -> Void) {
        
        let storageRef = storage.child(path)
        
        let uploadTask = storageRef.putData(data, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(.uploadFailed(error.localizedDescription)))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(.urlRetrievalFailed))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(.urlRetrievalFailed))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
        
        // Add progress observer if needed
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload progress: \(percentComplete * 100)%")
        }
    }
    
    /// Upload a file to Firebase Storage
    /// - Parameters:
    ///   - fileURL: Local URL of the file to upload
    ///   - path: Storage path to save the file
    ///   - metadata: Optional metadata for the upload
    ///   - completion: Result with the download URL or error
    func uploadFile(from fileURL: URL,
                    to path: String,
                    metadata: StorageMetadata? = nil,
                    completion: @escaping (Result<URL, StorageError>) -> Void) {
        
        let storageRef = storage.child(path)
        
        let uploadTask = storageRef.putFile(from: fileURL, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(.uploadFailed(error.localizedDescription)))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(.urlRetrievalFailed))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(.urlRetrievalFailed))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
        
        // Add progress observer if needed
        uploadTask.observe(.progress) { snapshot in
            let percentComplete = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            print("Upload progress: \(percentComplete * 100)%")
        }
    }
    
    // MARK: - Download Operations
    
    /// Download data from Firebase Storage
    /// - Parameters:
    ///   - path: Storage path of the file
    ///   - maxSize: Maximum size in bytes to download
    ///   - completion: Result with the data or error
    func downloadData(from path: String,
                      maxSize: Int64 = 10 * 1024 * 1024, // 10MB default
                      completion: @escaping (Result<Data, StorageError>) -> Void) {
        
        let storageRef = storage.child(path)
        
        storageRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                completion(.failure(.downloadFailed(error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.downloadFailed("No data returned")))
                return
            }
            
            completion(.success(data))
        }
    }
    
    /// Download an image from Firebase Storage
    /// - Parameters:
    ///   - path: Storage path of the image
    ///   - completion: Result with the UIImage or error
    func downloadImage(from path: String,
                       completion: @escaping (Result<UIImage, StorageError>) -> Void) {
        
        downloadData(from: path, maxSize: maxImageSize) { result in
            switch result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    completion(.success(image))
                } else {
                    completion(.failure(.downloadFailed("Could not convert data to image")))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get download URL for a file in Firebase Storage
    /// - Parameters:
    ///   - path: Storage path of the file
    ///   - completion: Result with the URL or error
    func getDownloadURL(for path: String,
                        completion: @escaping (Result<URL, StorageError>) -> Void) {
        
        let storageRef = storage.child(path)
        
        storageRef.downloadURL { url, error in
            if let error = error {
                completion(.failure(.urlRetrievalFailed))
                return
            }
            
            guard let downloadURL = url else {
                completion(.failure(.urlRetrievalFailed))
                return
            }
            
            completion(.success(downloadURL))
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a file from Firebase Storage
    /// - Parameters:
    ///   - path: Storage path of the file to delete
    ///   - completion: Result with success or error
    func deleteFile(at path: String,
                    completion: @escaping (Result<Void, StorageError>) -> Void) {
        
        let storageRef = storage.child(path)
        
        storageRef.delete { error in
            if let error = error {
                completion(.failure(.deleteFailed(error.localizedDescription)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Delete a file using its full URL from Firebase Storage
    /// - Parameters:
    ///   - url: Full URL of the file to delete
    ///   - completion: Result with success or error
    func deleteFile(url: URL,
                    completion: @escaping (Result<Void, StorageError>) -> Void) {
        
        guard let path = extractPathFromURL(url) else {
            completion(.failure(.invalidPath))
            return
        }
        
        deleteFile(at: path, completion: completion)
    }
    
    // MARK: - Helper Methods
    
    /// Extract the storage path from a full Firebase Storage URL
    /// - Parameter url: The full Firebase Storage URL
    /// - Returns: The storage path if successful, nil otherwise
    private func extractPathFromURL(_ url: URL) -> String? {
        let urlString = url.absoluteString
        
        // Check if it's a Firebase Storage URL
        guard urlString.contains("firebasestorage.googleapis.com") else {
            return nil
        }
        
        // Try to extract the path from the URL format
        if let pathComponent = urlString.components(separatedBy: "?").first,
           let path = pathComponent.components(separatedBy: "/o/").last {
            // URL decode the path
            return path.removingPercentEncoding
        }
        
        return nil
    }
    
    /// Generate a unique filename with extension
    /// - Parameters:
    ///   - prefix: Optional prefix for the filename
    ///   - extension: File extension (without the dot)
    /// - Returns: A unique filename
    func generateUniqueFilename(prefix: String = "", extension fileExtension: String) -> String {
        let uuid = UUID().uuidString
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let cleanPrefix = prefix.isEmpty ? "" : "\(prefix)_"
        return "\(cleanPrefix)\(dateString)_\(uuid).\(fileExtension)"
    }
}
