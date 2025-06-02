//
//  todolISappApp.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import Firebase
import SwiftUI

@main
struct todolISappApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
