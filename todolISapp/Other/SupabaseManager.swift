import Foundation
import Supabase

class SupabaseManager {
  static let shared = SupabaseManager()  // Singleton pattern

  let client: SupabaseClient

  private init() {
    let supabaseURL = URL(string: "https://xaxkrrkfgopaoeqyrjgn.supabase.co")!
    let supabaseKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhheGtycmtmZ29wYW9lcXlyamduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwOTE3NzksImV4cCI6MjA2NDY2Nzc3OX0.Y-MJJhNhM6Jii0kd-x0duBqP1mW1IHXJUCOKz2qDLqE"

    client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
  }
}
