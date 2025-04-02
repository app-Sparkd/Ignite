//
//  Business.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import Foundation
import FirebaseFirestore

enum BusinessStage: String, Codable, CaseIterable, Identifiable {
    case idea = "Idea"
    case prototype = "Prototype"
    case mvp = "Minimum Viable Product"
    case growth = "Growth"
    case scaling = "Scaling"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .idea:
            return "Initial concept without a product"
        case .prototype:
            return "Early working model being tested"
        case .mvp:
            return "Basic product with core features"
        case .growth:
            return "Established product with growing user base"
        case .scaling:
            return "Expanding to new markets or segments"
        }
    }
}

struct Business: Identifiable, Codable {
    var id: String
    var entrepreneurId: String
    var name: String
    var tagline: String
    var description: String
    var problem: String
    var solution: String
    var targetMarket: String
    var businessModel: String
    var competitiveLandscape: String
    var stage: BusinessStage
    var category: String
    var fundingGoal: Double
    var fundingRaised: Double
    var equity: Double // Percentage offered
    var imageURLs: [String]
    var videoURL: String?
    var websiteURL: String?
    var pitchDeckURL: String?
    var teamMembers: [TeamMember]?
    var likedByInvestors: [String] // Investor IDs
    var dislikedByInvestors: [String] // Investor IDs
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var isApproved: Bool
    
    // MARK: - Computed Properties
    
    var fundingProgress: Double {
        return fundingGoal > 0 ? min((fundingRaised / fundingGoal) * 100, 100) : 0
    }
    
    var formattedFundingGoal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: fundingGoal)) ?? "$\(Int(fundingGoal))"
    }
    
    var formattedFundingRaised: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: fundingRaised)) ?? "$\(Int(fundingRaised))"
    }
    
    // MARK: - Initializers
    
    init(id: String = UUID().uuidString,
         entrepreneurId: String,
         name: String,
         tagline: String,
         description: String,
         problem: String,
         solution: String,
         targetMarket: String,
         businessModel: String,
         competitiveLandscape: String = "",
         stage: BusinessStage,
         category: String,
         fundingGoal: Double,
         fundingRaised: Double = 0,
         equity: Double,
         imageURLs: [String] = [],
         videoURL: String? = nil,
         websiteURL: String? = nil,
         pitchDeckURL: String? = nil,
         teamMembers: [TeamMember]? = nil,
         likedByInvestors: [String] = [],
         dislikedByInvestors: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         isActive: Bool = true,
         isApproved: Bool = false) {
        
        self.id = id
        self.entrepreneurId = entrepreneurId
        self.name = name
        self.tagline = tagline
        self.description = description
        self.problem = problem
        self.solution = solution
        self.targetMarket = targetMarket
        self.businessModel = businessModel
        self.competitiveLandscape = competitiveLandscape
        self.stage = stage
        self.category = category
        self.fundingGoal = fundingGoal
        self.fundingRaised = fundingRaised
        self.equity = equity
        self.imageURLs = imageURLs
        self.videoURL = videoURL
        self.websiteURL = websiteURL
        self.pitchDeckURL = pitchDeckURL
        self.teamMembers = teamMembers
        self.likedByInvestors = likedByInvestors
        self.dislikedByInvestors = dislikedByInvestors
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isActive = isActive
        self.isApproved = isApproved
    }
    
    // MARK: - Firebase Helpers
    
    /// Create a dictionary representation for Firestore
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "entrepreneurId": entrepreneurId,
            "name": name,
            "tagline": tagline,
            "description": description,
            "problem": problem,
            "solution": solution,
            "targetMarket": targetMarket,
            "businessModel": businessModel,
            "competitiveLandscape": competitiveLandscape,
            "stage": stage.rawValue,
            "category": category,
            "fundingGoal": fundingGoal,
            "fundingRaised": fundingRaised,
            "equity": equity,
            "imageURLs": imageURLs,
            "likedByInvestors": likedByInvestors,
            "dislikedByInvestors": dislikedByInvestors,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "isActive": isActive,
            "isApproved": isApproved
        ]
        
        // Add optional fields
        if let videoURL = videoURL {
            dict["videoURL"] = videoURL
        }
        
        if let websiteURL = websiteURL {
            dict["websiteURL"] = websiteURL
        }
        
        if let pitchDeckURL = pitchDeckURL {
            dict["pitchDeckURL"] = pitchDeckURL
        }
        
        if let teamMembers = teamMembers {
            dict["teamMembers"] = teamMembers.map { $0.asDictionary() }
        }
        
        return dict
    }
    
    /// Create a Business from a Firestore document
    static func fromFirestore(_ document: DocumentSnapshot) -> Business? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        
        guard let entrepreneurId = data["entrepreneurId"] as? String,
              let name = data["name"] as? String,
              let tagline = data["tagline"] as? String,
              let description = data["description"] as? String,
              let problem = data["problem"] as? String,
              let solution = data["solution"] as? String,
              let targetMarket = data["targetMarket"] as? String,
              let businessModel = data["businessModel"] as? String,
              let stageString = data["stage"] as? String,
              let stage = BusinessStage(rawValue: stageString),
              let category = data["category"] as? String,
              let fundingGoal = data["fundingGoal"] as? Double,
              let fundingRaised = data["fundingRaised"] as? Double,
              let equity = data["equity"] as? Double,
              let imageURLs = data["imageURLs"] as? [String],
              let likedByInvestors = data["likedByInvestors"] as? [String],
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        let competitiveLandscape = data["competitiveLandscape"] as? String ?? ""
        let videoURL = data["videoURL"] as? String
        let websiteURL = data["websiteURL"] as? String
        let pitchDeckURL = data["pitchDeckURL"] as? String
        let dislikedByInvestors = data["dislikedByInvestors"] as? [String] ?? []
        let isApproved = data["isApproved"] as? Bool ?? false
        
        let createdAtTimestamp = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())
        let updatedAtTimestamp = data["updatedAt"] as? Timestamp ?? Timestamp(date: Date())
        
        var teamMembers: [TeamMember]?
        if let teamMembersData = data["teamMembers"] as? [[String: Any]] {
            teamMembers = teamMembersData.compactMap { TeamMember.fromDictionary($0) }
        }
        
        return Business(
            id: id,
            entrepreneurId: entrepreneurId,
            name: name,
            tagline: tagline,
            description: description,
            problem: problem,
            solution: solution,
            targetMarket: targetMarket,
            businessModel: businessModel,
            competitiveLandscape: competitiveLandscape,
            stage: stage,
            category: category,
            fundingGoal: fundingGoal,
            fundingRaised: fundingRaised,
            equity: equity,
            imageURLs: imageURLs,
            videoURL: videoURL,
            websiteURL: websiteURL,
            pitchDeckURL: pitchDeckURL,
            teamMembers: teamMembers,
            likedByInvestors: likedByInvestors,
            dislikedByInvestors: dislikedByInvestors,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue(),
            isActive: isActive,
            isApproved: isApproved
        )
    }
}

// MARK: - Team Member Model

struct TeamMember: Codable {
    var name: String
    var role: String
    var bio: String
    var photoURL: String?
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "role": role,
            "bio": bio
        ]
        
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> TeamMember? {
        guard let name = dict["name"] as? String,
              let role = dict["role"] as? String,
              let bio = dict["bio"] as? String else {
            return nil
        }
        
        let photoURL = dict["photoURL"] as? String
        
        return TeamMember(
            name: name,
            role: role,
            bio: bio,
            photoURL: photoURL
        )
    }
}
