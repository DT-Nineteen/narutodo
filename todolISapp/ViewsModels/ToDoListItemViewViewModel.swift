//
//  ToDoListItemViewViewModel.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import FirebaseFirestore
import FirebaseAuth
import Foundation

class ToDoListItemViewViewModel: ObservableObject {
    init() {
        
    }

    func toggleIsDone (item: TodoListItem) {
        var itemCopy = item
        itemCopy.setDone(!item.isDone)
        
        guard let uId = Auth.auth().currentUser?.uid else {
            return
        }
        let db = Firestore.firestore()
        db.collection("users")
            .document(uId)
            .collection("todos")
            .document(itemCopy.id)
            .setData(itemCopy.asDictionary())
    }
    
}
