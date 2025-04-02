import Foundation
import FirebaseFirestore

enum UserType: String, Codable {
    case entrepreneur
    case investor
    case admin
}

struct User: Identifiable, Codable {
    var id: String
    var email: String
    var name: String
    var photoURL: String?
    var userType: UserType
    var bio: String?
    var createdAt: Date
    var lastActive: Date
    
    // MARK: - Initializers
    
    init(id: String,
         email: String,
         name: String,
         photoURL: String? = nil,
         userType: UserType,
         bio: String? = nil,
         createdAt: Date = Date(),
         lastActive: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.photoURL = photoURL
        self.userType = userType
        self.bio = bio
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
    
    // MARK: - Firebase Helpers
    
    /// Create a dictionary representation for Firestore
    func asDictionary() -> [String: Any] {
        return [
            "id": id,
            "email": email,
            "name": name,
            "photoURL": photoURL as Any,
            "userType": userType.rawValue,
            "bio": bio as Any,
            "createdAt": Timestamp(date: createdAt),
            "lastActive": Timestamp(date: lastActive)
        ]
    }
    
    /// Create a User from a Firestore document
    static func fromFirestore(_ document: DocumentSnapshot) -> User? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        
        guard let email = data["email"] as? String,
              let name = data["name"] as? String,
              let userTypeString = data["userType"] as? String,
              let userType = UserType(rawValue: userTypeString) else {
            return nil
        }
        
        let photoURL = data["photoURL"] as? String
        let bio = data["bio"] as? String
        
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let lastActiveTimestamp = data["lastActive"] as? Timestamp ?? Timestamp(date: Date())
        
        return User(
            id: id,
            email: email,
            name: name,
            photoURL: photoURL,
            userType: userType,
            bio: bio,
            createdAt: createdAtTimestamp.dateValue(),
            lastActive: lastActiveTimestamp.dateValue()
        )
    }
}
