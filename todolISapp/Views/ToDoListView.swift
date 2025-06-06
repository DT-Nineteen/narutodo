//
//  ToDoListItemsView.swift
//  todolISapp
//
//  Created by Aiden on 28/5/25.
//
import FirebaseFirestore
import SwiftUI

struct ToDoListView: View {
    @StateObject var viewModel: ToDoListViewViewModel
    @FirestoreQuery var items: [TodoListItem]
    
    init(userId: String){
        self._items = FirestoreQuery(collectionPath: "users/\(userId)/todos")
        
        self._viewModel = StateObject(wrappedValue: ToDoListViewViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            VStack{
                List(items) {item in
                    ToDoListItemView(item: item)
                        .swipeActions {
                            Button("Delete"){
                                viewModel.detele(id: item.id)
                            } .tint(.red)
                        }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("To Do List")
            .toolbar {
                Button {
                    viewModel.isShowNewItemView = true
                }label: {
                    Image(systemName: "plus")
                }
            }
        }.sheet(isPresented: $viewModel.isShowNewItemView){
            NewItemView(newItemPresented: $viewModel.isShowNewItemView)
        }
    }
}

#Preview {
    ToDoListView(userId: "FC123681-D157-4081-908E-B90C6F663973")
}
