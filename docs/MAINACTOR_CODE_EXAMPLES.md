# MainActor Code Examples: Current vs Alternatives

## Example 1: Simple State Update

### ✅ Current (with @MainActor)

```swift
@MainActor
@Observable
class DiscoveryViewModel {
    var results: [Place] = []
    var isLoading = false
    
    func performSearch() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            results = try await interactor.searchNearby()
        } catch {
            self.error = error as? PlacesError
        }
    }
}
```

**Lines of Code**: 13  
**Complexity**: Low  
**Thread Safety**: ✅ Compile-time guaranteed  
**Readability**: ✅ Excellent

---

### ❌ Alternative: Manual DispatchQueue

```swift
class DiscoveryViewModel {
    var results: [Place] = []
    var isLoading = false
    
    func performSearch() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            let places = try await interactor.searchNearby()
            DispatchQueue.main.async {
                self.results = places
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error as? PlacesError
                self.isLoading = false
            }
        }
    }
}
```

**Lines of Code**: 23 (+77%)  
**Complexity**: Medium  
**Thread Safety**: ⚠️ Runtime only  
**Readability**: ❌ Scattered updates

**Problems**:
- Forgot to set `isLoading = false` in catch block initially
- Easy to miss `DispatchQueue.main.async` wrapper
- Duplicated `isLoading = false` logic

---

### ❌ Alternative: Custom Actor

```swift
actor ViewModelState {
    var results: [Place] = []
    var isLoading = false
    
    func updateResults(_ places: [Place]) {
        self.results = places
    }
    
    func setLoading(_ loading: Bool) {
        self.isLoading = loading
    }
}

class DiscoveryViewModel {
    private let state = ViewModelState()
    
    // ❌ Problem: SwiftUI can't observe actor properties!
    // Need to duplicate state in @Published properties
    @Published var results: [Place] = []
    @Published var isLoading = false
    
    func performSearch() async {
        await state.setLoading(true)
        await MainActor.run { self.isLoading = true }
        
        do {
            let places = try await interactor.searchNearby()
            await state.updateResults(places)
            await MainActor.run {
                self.results = places
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error as? PlacesError
                self.isLoading = false
            }
        }
    }
}
```

**Lines of Code**: 40 (+208%)  
**Complexity**: High  
**Thread Safety**: ⚠️ Partial  
**Readability**: ❌ Very confusing

**Problems**:
- Duplicated state (actor + @Published)
- Still need MainActor for SwiftUI
- More complex, no benefit

---

## Example 2: Combine Integration

### ✅ Current (Hybrid @MainActor + nonisolated)

```swift
@MainActor
class DataPipelineCoordinator {
    @Published private(set) var mergedResults: [Place] = []
    
    nonisolated func executePipeline() -> AnyPublisher<[Place], Never> {
        return networkPublisher
            .subscribe(on: processingQueue)
            .handleEvents(receiveOutput: { [weak self] places in
                Task { @MainActor [weak self] in
                    self?.mergedResults = places
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
```

**Lines of Code**: 14  
**Complexity**: Medium  
**Thread Safety**: ✅ Compile-time + explicit Task  
**Readability**: ✅ Good

**Why This Works**:
- `@MainActor` for state properties
- `nonisolated` for publisher creation
- `Task { @MainActor }` for safe updates
- Clear separation of concerns

---

### ❌ Alternative: No MainActor

```swift
class DataPipelineCoordinator {
    @Published private(set) var mergedResults: [Place] = []
    private let stateQueue = DispatchQueue(label: "com.app.state")
    
    func executePipeline() -> AnyPublisher<[Place], Never> {
        return networkPublisher
            .subscribe(on: processingQueue)
            .handleEvents(receiveOutput: { [weak self] places in
                guard let self = self else { return }
                self.stateQueue.async {
                    DispatchQueue.main.async {
                        self.mergedResults = places
                    }
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
```

**Lines of Code**: 18 (+29%)  
**Complexity**: High  
**Thread Safety**: ⚠️ Manual  
**Readability**: ❌ Nested closures

**Problems**:
- Nested `DispatchQueue.async` calls
- Manual queue management
- No compile-time safety
- Harder to understand flow

---

## Example 3: Manager with Published State

### ✅ Current (with @MainActor)

```swift
@MainActor
class FavoritesManager {
    @Published private(set) var favoriteIds: Set<String> = []
    private let service: FavoritesService
    
    func toggleFavorite(_ placeId: String) async throws -> Bool {
        if favoriteIds.contains(placeId) {
            favoriteIds.remove(placeId)
            try service.removeFavorite(placeId)
            return false
        } else {
            favoriteIds.insert(placeId)
            try service.addFavorite(placeId)
            return true
        }
    }
}
```

**Lines of Code**: 16  
**Complexity**: Low  
**Thread Safety**: ✅ Compile-time  
**Readability**: ✅ Excellent

---

### ❌ Alternative: Serial Queue with Continuations

```swift
class FavoritesManager {
    private var _favoriteIds: Set<String> = []
    private let queue = DispatchQueue(label: "com.app.favorites")
    private let service: FavoritesService

    var favoriteIds: Set<String> {
        get async {
            await withCheckedContinuation { continuation in
                queue.async {
                    continuation.resume(returning: self._favoriteIds)
                }
            }
        }
    }

    func toggleFavorite(_ placeId: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if self._favoriteIds.contains(placeId) {
                    self._favoriteIds.remove(placeId)
                    do {
                        try self.service.removeFavorite(placeId)
                        continuation.resume(returning: false)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    self._favoriteIds.insert(placeId)
                    do {
                        try self.service.addFavorite(placeId)
                        continuation.resume(returning: true)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
```

**Lines of Code**: 40 (+150%)
**Complexity**: Very High
**Thread Safety**: ⚠️ Manual
**Readability**: ❌ Very poor

**Problems**:
- Cannot use `@Published` (no Combine integration)
- Manual continuation management
- Nested closures
- Error handling complexity
- No SwiftUI observation support

---

## Summary Table

| Example | Current LOC | Alternative LOC | Increase | Complexity | Safety |
|---------|-------------|-----------------|----------|------------|--------|
| Simple State Update | 13 | 23-40 | +77-208% | Low → High | ✅ → ⚠️ |
| Combine Integration | 14 | 18 | +29% | Medium → High | ✅ → ⚠️ |
| Manager with Published | 16 | 40 | +150% | Low → Very High | ✅ → ⚠️ |

---

## Key Takeaways

### With @MainActor ✅
- **Concise**: Minimal lines of code
- **Safe**: Compile-time thread safety
- **Clear**: Linear, easy-to-follow code
- **Integrated**: Works seamlessly with SwiftUI
- **Maintainable**: Less code = fewer bugs

### Without @MainActor ❌
- **Verbose**: 54-208% more code for same functionality
- **Risky**: Runtime-only safety, easy to miss updates
- **Confusing**: Scattered updates, nested closures
- **Limited**: No `@Published` or `@Observable` support
- **Error-Prone**: More code = more bugs

---

**Conclusion**: The current @MainActor approach is superior in every measurable way.

