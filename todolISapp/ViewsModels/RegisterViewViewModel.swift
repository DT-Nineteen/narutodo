//
//  RegisterViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import FirebaseFirestore
import FirebaseAuth
import Foundation

class RegisterViewViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var errorMessage = ""
    
    init(){}
    
    func register(){
        errorMessage = ""
        
        guard validate() else {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let userId = result?.user.uid else {
                return
            }
            
            self?.insertUserRecord(id: userId)
            
            
            
            
        }
        
    }
    
    private func insertUserRecord (id: String){
        let newUser = User(id: id, name: fullName, email: email, joined: Date().timeIntervalSince1970)
        
        let db = Firestore.firestore()
        
        db.collection("users").document(id).setData(newUser.asDictionary())
    }
    
    private func validate() -> Bool{
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty, !password.trimmingCharacters(in: .whitespaces).isEmpty, !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Can not be empty"
            return false
        }
        
        // email@xxx.com
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Invalid Email"
            return false
        }
        
        // 123456
        guard password.count >= 6 else {
            errorMessage = "Invalid Passwrod"
            return false
        }
        
        return true
    }
}
