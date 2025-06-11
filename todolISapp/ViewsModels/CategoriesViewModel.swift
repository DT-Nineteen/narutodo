// CategoriesViewModel.swift
import Foundation
import Supabase

@MainActor
class CategoriesViewModel: ObservableObject {
  @Published var categories: [Category] = []

  // get all categories for current user
  func fetchCategories() async {
    do {
      let fetchedCategories: [Category] = try await SupabaseManager.shared.client
        .from("categories")
        .select()
        .order("created_at", ascending: true)
        .execute()
        .value
      self.categories = fetchedCategories
    } catch {
      print("Error fetching categories: \(error.localizedDescription)")
    }
  }

  // add a new category
  func addCategory(name: String, icon: String?) async {
    struct NewCategory: Encodable { let name: String, icon_name: String? }
    let newCategory = NewCategory(name: name, icon_name: icon)

    do {
      try await SupabaseManager.shared.client
        .from("categories")
        .insert(newCategory)
        .execute()

      // reload the list to update the UI
      await fetchCategories()
    } catch {
      print("Error adding category: \(error.localizedDescription)")
    }
  }

  // delete a category (and all activities inside it)
  func deleteCategory(id: UUID) async {
    do {
      // thanks to "ON DELETE CASCADE", you only need to delete the category
      // the database will automatically delete the related activities
      try await SupabaseManager.shared.client
        .from("categories")
        .delete()
        .eq("id", value: id)
        .execute()

      // remove from the local array to update the UI immediately
      categories.removeAll { $0.id == id }
    } catch {
      print("Error deleting category: \(error.localizedDescription)")
    }
  }
}
