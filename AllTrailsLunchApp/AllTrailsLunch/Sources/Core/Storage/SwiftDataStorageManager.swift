//
//  SwiftDataStorageManager.swift
//  AllTrailsLunch
//
//  Created by Tri Le on 01/11/25.
//

import Foundation
import SwiftData

// MARK: - SwiftData Storage Manager

@MainActor
final class SwiftDataStorageManager {
    static let shared = SwiftDataStorageManager()
    
    let container: ModelContainer
    
    var mainContext: ModelContext {
        container.mainContext
    }
    
    // MARK: - Initialization
    
    private init() {
        let schema = Schema([
            FavoritePlace.self,
            SavedSearch.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            print("✅ SwiftData container initialized successfully")
        } catch {
            fatalError("❌ Failed to initialize SwiftData container: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Create a new background context for async operations
    func newBackgroundContext() -> ModelContext {
        let context = ModelContext(container)
        return context
    }
}

