//
//  ToDoListViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import FirebaseFirestore
import Foundation

class ToDoListViewViewModel : ObservableObject {
    @Published var isShowNewItemView = false
    
    private let userId: String
    
    init(userId: String ) {
        self.userId = userId
    }
    
    /// Delete
    /// - Parameter id:item id to delete
    func detele(id: String){
        let db = Firestore.firestore()
        
        
        db.collection("users")
            .document(userId)
            .collection("todos")
            .document(id)
            .delete()
    }
  
}

