//
//  DatabaseService.swift
//  Ignite
//
//  Created for Teen Business Platform
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

enum DatabaseError: Error {
    case documentNotFound
    case invalidData
    case operationFailed(String)
}

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Generic CRUD Operations
    
    /// Create a document in a collection
    func create<T: Encodable>(collection: String, document: String? = nil, data: T, completion: @escaping (Result<String, DatabaseError>) -> Void) {
        do {
            let encodedData = try Firestore.Encoder().encode(data)
            
            let docRef: DocumentReference
            if let document = document {
                docRef = db.collection(collection).document(document)
            } else {
                docRef = db.collection(collection).document()
            }
            
            docRef.setData(encodedData) { error in
                if let error = error {
                    completion(.failure(.operationFailed(error.localizedDescription)))
                    return
                }
                
                completion(.success(docRef.documentID))
            }
        } catch {
            completion(.failure(.operationFailed("Failed to encode data: \(error.localizedDescription)")))
        }
    }
    
    /// Get a document from a collection
    func get<T: Decodable>(collection: String, document: String, completion: @escaping (Result<T, DatabaseError>) -> Void) {
        db.collection(collection).document(document).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(.operationFailed(error.localizedDescription)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(.documentNotFound))
                return
            }
            
            do {
                let result = try snapshot.data(as: T.self)
                completion(.success(result))
            } catch {
                completion(.failure(.invalidData))
            }
        }
    }
    
    /// Update a document in a collection
    func update<T: Encodable>(collection: String, document: String, data: T, merge: Bool = true, completion: @escaping (Result<Void, DatabaseError>) -> Void) {
        do {
            let encodedData = try Firestore.Encoder().encode(data)
            
            db.collection(collection).document(document).setData(encodedData, merge: merge) { error in
                if let error = error {
                    completion(.failure(.operationFailed(error.localizedDescription)))
                    return
                }
                
                completion(.success(()))
            }
        } catch {
            completion(.failure(.operationFailed("Failed to encode data: \(error.localizedDescription)")))
        }
    }
    
    /// Delete a document from a collection
    func delete(collection: String, document: String, completion: @escaping (Result<Void, DatabaseError>) -> Void) {
        db.collection(collection).document(document).delete { error in
            if let error = error {
                completion(.failure(.operationFailed(error.localizedDescription)))
                return
            }
            
            completion(.success(()))
        }
    }
    
    // MARK: - Query Operations
    
    /// Get all documents from a collection that match a query
    func query<T: Decodable>(collection: String,
                             field: String? = nil,
                             isEqualTo: Any? = nil,
                             isGreaterThan: Any? = nil,
                             isLessThan: Any? = nil,
                             arrayContains: Any? = nil,
                             limit: Int? = nil,
                             orderBy: String? = nil,
                             descending: Bool = false,
                             completion: @escaping (Result<[T], DatabaseError>) -> Void) {
        
        var query: Query = db.collection(collection)
        
        // Apply field filters if provided
        if let field = field {
            if let value = isEqualTo {
                query = query.whereField(field, isEqualTo: value)
            }
            
            if let value = isGreaterThan {
                query = query.whereField(field, isGreaterThan: value)
            }
            
            if let value = isLessThan {
                query = query.whereField(field, isLessThan: value)
            }
            
            if let value = arrayContains {
                query = query.whereField(field, arrayContains: value)
            }
        }
        
        // Apply ordering if provided
        if let orderBy = orderBy {
            query = query.order(by: orderBy, descending: descending)
        }
        
        // Apply limit if provided
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        // Execute the query
        query.getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(.operationFailed(error.localizedDescription)))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            
            do {
                var results = [T]()
                
                for document in documents {
                    let result = try document.data(as: T.self)
                    results.append(result)
                }
                
                completion(.success(results))
            } catch {
                completion(.failure(.invalidData))
            }
        }
    }
    
    // MARK: - Listener Operations
    
    /// Listen for changes to a document
    func listen<T: Decodable>(collection: String, document: String) -> AnyPublisher<T?, Error> {
        let subject = PassthroughSubject<T?, Error>()
        
        let listener = db.collection(collection).document(document).addSnapshotListener { snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                subject.send(nil)
                return
            }
            
            do {
                let result = try snapshot.data(as: T.self)
                subject.send(result)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
    
    /// Listen for changes to a collection query
    func listenToQuery<T: Decodable>(collection: String,
                                     field: String? = nil,
                                     isEqualTo: Any? = nil,
                                     orderBy: String? = nil,
                                     descending: Bool = false,
                                     limit: Int? = nil) -> AnyPublisher<[T], Error> {
        
        let subject = PassthroughSubject<[T], Error>()
        
        var query: Query = db.collection(collection)
        
        if let field = field, let value = isEqualTo {
            query = query.whereField(field, isEqualTo: value)
        }
        
        if let orderBy = orderBy {
            query = query.order(by: orderBy, descending: descending)
        }
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let listener = query.addSnapshotListener { querySnapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                subject.send([])
                return
            }
            
            do {
                var results = [T]()
                
                for document in documents {
                    let result = try document.data(as: T.self)
                    results.append(result)
                }
                
                subject.send(results)
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                listener.remove()
            })
            .eraseToAnyPublisher()
    }
}
