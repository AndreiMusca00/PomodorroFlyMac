//
//  UserModel.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import Foundation

struct UserModel: Codable, Equatable,Identifiable {
    var id: String
    var addedDateTime: String
    var email: String
    var name: String
    var isUsernameSet: Bool
    
    // ---- Subscription fields ----
        var isPremium: Bool        // rapid check dacă e premium
        var subscriptionType: String? // ex: "monthly", "yearly", "lifetime"
        var subscriptionStartDate: String? // ISO8601
        var subscriptionEndDate: String?   // ISO8601
        var lastReceiptData: String? // base64 encoded, pentru verificare server-side
}

extension UserModel {
    static let empty = UserModel(id: "",addedDateTime: "",email: "",name: "",isUsernameSet: false,isPremium: false,subscriptionType: nil,subscriptionStartDate: nil,subscriptionEndDate: nil,lastReceiptData: nil)
}
