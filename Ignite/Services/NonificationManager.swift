//
//  NonificationManager.swift
//  Ignite
//
//  Created by Henry Bowman on 4/6/25.
//

import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseMessaging

enum NotificationType: String, Codable {
    case newMatch = "new_match"           // Investor liked entrepreneur's business
    case newInvestment = "new_investment" // Investment was made
    case fundingGoal = "funding_goal"     // Funding goal reached
    case message = "message"              // Direct message
    case businessApproved = "business_approved" // Business was approved by admin
    case systemAlert = "system_alert"     // System notification
}

struct NotificationData: Codable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let senderID: String?
    let recipientID: String
    let businessID: String?
    let investmentID: String?
    let createdAt: Date
    let read: Bool
    let additionalData: [String: String]?
    
    var asFirestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "type": type.rawValue,
            "title": title,
            "body": body,
            "recipientID": recipientID,
            "createdAt": Timestamp(date: createdAt),
            "read": read
        ]
        
        if let senderID = senderID {
            data["senderID"] = senderID
        }
        
        if let businessID = businessID {
            data["businessID"] = businessID
        }
        
        if let investmentID = investmentID {
            data["investmentID"] = investmentID
        }
        
        if let additionalData = additionalData {
            data["additionalData"] = additionalData
        }
        
        return data
    }
    
    static func fromFirestore(_ document: DocumentSnapshot) -> NotificationData? {
        guard
            let data = document.data(),
            let typeString = data["type"] as? String,
            let type = NotificationType(rawValue: typeString),
            let title = data["title"] as? String,
            let body = data["body"] as? String,
            let recipientID = data["recipientID"] as? String,
            let createdTimestamp = data["createdAt"] as? Timestamp,
            let read = data["read"] as? Bool
        else {
            return nil
        }
        
        let id = document.documentID
        let senderID = data["senderID"] as? String
        let businessID = data["businessID"] as? String
        let investmentID = data["investmentID"] as? String
        let additionalData = data["additionalData"] as? [String: String]
        
        return NotificationData(
            id: id,
            type: type,
            title: title,
            body: body,
            senderID: senderID,
            recipientID: recipientID,
            businessID: businessID,
            investmentID: investmentID,
            createdAt: createdTimestamp.dateValue(),
            read: read,
            additionalData: additionalData
        )
    }
}

/// Manager for handling local and remote notifications
class NotificationManager: NSObject {
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Properties
    private let db = FirebaseManager.shared.db
    private let notificationCenter = UNUserNotificationCenter.current()
    private var deviceToken: String?
    
    private let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Setup
    
    /// Request permission to show notifications
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: authOptions) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    /// Configure Firebase Messaging
    func configureFCM() {
        Messaging.messaging().delegate = self
    }
    
    /// Set device token for Firebase Messaging
    func setDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        print("Device Token: \(token)")
    }
    
    // MARK: - Local Notifications
    
    /// Schedule a local notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - data: Additional data to include
    ///   - delay: Time delay before showing the notification
    func scheduleLocalNotification(
        title: String,
        body: String,
        data: [String: String]? = nil,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let data = data {
            content.userInfo = data
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Firestore Notifications
    
    /// Save a notification to Firestore
    /// - Parameters:
    ///   - notification: The notification data to save
    ///   - sendPush: Whether to also send as a push notification
    ///   - completion: Result with success or error
    func saveNotification(
        _ notification: NotificationData,
        sendPush: Bool = true,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(Constants.Collections.notifications)
            .document(notification.id)
            .setData(notification.asFirestoreData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    if sendPush {
                        // In a real app, you would trigger a cloud function here
                        // to send the push notification via Firebase Cloud Messaging
                        self.scheduleLocalNotification(
                            title: notification.title,
                            body: notification.body
                        )
                    }
                    completion(.success(()))
                }
            }
    }
    
    /// Get all notifications for a user
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - limit: Maximum number of notifications to retrieve
    ///   - completion: Result with notifications or error
    func getNotifications(
        for userID: String,
        limit: Int = 50,
        completion: @escaping (Result<[NotificationData], Error>) -> Void
    ) {
        db.collection(Constants.Collections.notifications)
            .whereField("recipientID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let notifications = documents.compactMap { NotificationData.fromFirestore($0) }
                completion(.success(notifications))
            }
    }
    
    /// Mark a notification as read
    /// - Parameters:
    ///   - notificationID: The notification's ID
    ///   - completion: Result with success or error
    func markAsRead(
        notificationID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(Constants.Collections.notifications)
            .document(notificationID)
            .updateData(["read": true]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Delete a notification
    /// - Parameters:
    ///   - notificationID: The notification's ID
    ///   - completion: Result with success or error
    func deleteNotification(
        notificationID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(Constants.Collections.notifications)
            .document(notificationID)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Notification Creation Helpers
    
    /// Create a new match notification
    /// - Parameters:
    ///   - businessID: The business that was matched
    ///   - entrepreneurID: The entrepreneur to notify
    ///   - investorID: The investor who liked the business
    ///   - businessName: The name of the business
    func createNewMatchNotification(
        businessID: String,
        entrepreneurID: String,
        investorID: String,
        businessName: String
    ) {
        let notification = NotificationData(
            id: UUID().uuidString,
            type: .newMatch,
            title: "New Investor Match!",
            body: "An investor is interested in your business: \(businessName)",
            senderID: investorID,
            recipientID: entrepreneurID,
            businessID: businessID,
            investmentID: nil,
            createdAt: Date(),
            read: false,
            additionalData: nil
        )
        
        saveNotification(notification) { _ in }
    }
    
    /// Create a new investment notification
    /// - Parameters:
    ///   - businessID: The business that received an investment
    ///   - entrepreneurID: The entrepreneur to notify
    ///   - investorID: The investor who made the investment
    ///   - investmentID: The ID of the investment
    ///   - amount: The investment amount
    ///   - businessName: The name of the business
    func createNewInvestmentNotification(
        businessID: String,
        entrepreneurID: String,
        investorID: String,
        investmentID: String,
        amount: Double,
        businessName: String
    ) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let amountString = formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
        
        let notification = NotificationData(
            id: UUID().uuidString,
            type: .newInvestment,
            title: "New Investment!",
            body: "Your business \(businessName) received an investment of \(amountString)",
            senderID: investorID,
            recipientID: entrepreneurID,
            businessID: businessID,
            investmentID: investmentID,
            createdAt: Date(),
            read: false,
            additionalData: ["amount": "\(amount)"]
        )
        
        saveNotification(notification) { _ in }
    }
    
    /// Create a funding goal notification
    /// - Parameters:
    ///   - businessID: The business that reached its funding goal
    ///   - entrepreneurID: The entrepreneur to notify
    ///   - businessName: The name of the business
    ///   - fundingGoal: The funding goal amount
    func createFundingGoalNotification(
        businessID: String,
        entrepreneurID: String,
        businessName: String,
        fundingGoal: Double
    ) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let goalString = formatter.string(from: NSNumber(value: fundingGoal)) ?? "$\(Int(fundingGoal))"
        
        let notification = NotificationData(
            id: UUID().uuidString,
            type: .fundingGoal,
            title: "Funding Goal Reached! 🎉",
            body: "Congratulations! Your business \(businessName) has reached its funding goal of \(goalString).",
            senderID: nil,
            recipientID: entrepreneurID,
            businessID: businessID,
            investmentID: nil,
            createdAt: Date(),
            read: false,
            additionalData: ["fundingGoal": "\(fundingGoal)"]
        )
        
        saveNotification(notification) { _ in }
    }
    
    /// Create a business approval notification
    /// - Parameters:
    ///   - businessID: The business that was approved
    ///   - entrepreneurID: The entrepreneur to notify
    ///   - businessName: The name of the business
    func createBusinessApprovedNotification(
        businessID: String,
        entrepreneurID: String,
        businessName: String
    ) {
        let notification = NotificationData(
            id: UUID().uuidString,
            type: .businessApproved,
            title: "Business Approved",
            body: "Your business \(businessName) has been approved and is now visible to investors.",
            senderID: nil,
            recipientID: entrepreneurID,
            businessID: businessID,
            investmentID: nil,
            createdAt: Date(),
            read: false,
            additionalData: nil
        )
        
        saveNotification(notification) { _ in }
    }
    
    /// Create a system notification for all users
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - userIDs: Array of user IDs to notify
    func createSystemNotification(
        title: String,
        body: String,
        userIDs: [String]
    ) {
        for userID in userIDs {
            let notification = NotificationData(
                id: UUID().uuidString,
                type: .systemAlert,
                title: title,
                body: body,
                senderID: nil,
                recipientID: userID,
                businessID: nil,
                investmentID: nil,
                createdAt: Date(),
                read: false,
                additionalData: nil
            )
            
            saveNotification(notification) { _ in }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("Received notification response: \(userInfo)")
        
        // Handle notification response
        // For example, navigate to a specific screen
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "nil")")
        
        // Store this token in Firestore for the current user
        if let token = fcmToken, let userID = FirebaseManager.shared.currentUserID {
            FirebaseManager.shared.db.collection("users")
                .document(userID)
                .updateData(["fcmToken": token]) { error in
                    if let error = error {
                        print("Error updating FCM token: \(error.localizedDescription)")
                    }
                }
        }
    }
}
