//
//  User.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//

import Foundation

struct User: Codable {
    let id:String
    let name:String
    let email: String
    let joined: TimeInterval
}
