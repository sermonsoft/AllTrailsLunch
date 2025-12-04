# MainActor Quick Reference Guide

## TL;DR

**Question**: Can we replace MainActor with other concurrency approaches?

**Answer**: **Yes, but DON'T.** MainActor is the right tool for this codebase.

---

## Decision Matrix

### Use @MainActor When:

✅ **ViewModels** - Always  
✅ **Managers** - When managing UI-bound state  
✅ **Interactors** - When coordinating UI-bound managers  
✅ **UI State** - Any property that affects SwiftUI views  
✅ **@Observable/@Published** - Required for proper isolation

### Use Custom Actor When:

✅ **Caches** - Background data storage  
✅ **Heavy Computation** - CPU-intensive work  
✅ **No UI Dependencies** - Pure business logic  
✅ **Thread Isolation** - Need separate execution context

### Use DispatchQueue When:

✅ **One-off Tasks** - Single background operations  
✅ **Legacy Integration** - Existing non-async code  
✅ **Combine Pipelines** - `.subscribe(on:)` for processing  
✅ **Fine-grained Control** - Specific QoS requirements

### Use Combine When:

✅ **Reactive Streams** - Multiple data sources  
✅ **Debouncing/Throttling** - User input handling  
✅ **Data Pipelines** - Complex transformations  
✅ **Event Streams** - Publisher/subscriber patterns

---

## Common Patterns in This Codebase

### Pattern 1: ViewModel (Always @MainActor)

```swift
@MainActor
@Observable
class MyViewModel {
    var state: ViewState = .idle
    private let interactor: MyInteractor
    
    func performAction() async {
        state = .loading
        defer { state = .idle }
        // All updates guaranteed on main thread
    }
}
```

### Pattern 2: Manager (Always @MainActor)

```swift
@MainActor
class MyManager {
    @Published private(set) var data: [Item] = []
    
    func updateData() async throws {
        // All updates guaranteed on main thread
        data = try await service.fetch()
    }
}
```

### Pattern 3: Interactor (Always @MainActor)

```swift
@MainActor
class CoreInteractor {
    private let manager1: Manager1
    private let manager2: Manager2
    
    func coordinate() async throws {
        // No cross-actor calls needed
        let data1 = await manager1.getData()
        let data2 = await manager2.getData()
        return combine(data1, data2)
    }
}
```

### Pattern 4: Service (nonisolated)

```swift
class MyService {
    // No @MainActor - can be called from any context
    func fetch() async throws -> [Item] {
        // Network call on background thread
        return try await URLSession.shared.data(from: url)
    }
}
```

### Pattern 5: Cache (Custom Actor)

```swift
actor MyCache {
    private var storage: [String: Data] = [:]
    
    func get(_ key: String) -> Data? {
        // Background thread - doesn't block UI
        return storage[key]
    }
}
```

### Pattern 6: Combine Coordinator (@MainActor + nonisolated)

```swift
@MainActor
class PipelineCoordinator {
    @Published private(set) var results: [Item] = []
    
    nonisolated func executePipeline() -> AnyPublisher<[Item], Never> {
        return publisher
            .subscribe(on: processingQueue)
            .handleEvents(receiveOutput: { [weak self] items in
                Task { @MainActor [weak self] in
                    self?.results = items
                }
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
```

---

## Anti-Patterns to Avoid

### ❌ Don't: Remove @MainActor from ViewModels

```swift
// ❌ WRONG
class MyViewModel {
    var state: ViewState = .idle
    
    func update() async {
        DispatchQueue.main.async {
            self.state = .loading  // Manual, error-prone
        }
    }
}
```

### ❌ Don't: Use Custom Actor for UI State

```swift
// ❌ WRONG
actor ViewModelState {
    var items: [Item] = []
}

class MyViewModel {
    private let state = ViewModelState()
    @Published var items: [Item] = []  // Duplicated!
}
```

### ❌ Don't: Mix Isolation Domains Unnecessarily

```swift
// ❌ WRONG
@MainActor
class MyManager {
    private let actor = MyActor()
    
    func getData() async -> [Item] {
        await actor.fetch()  // Unnecessary actor hop
    }
}
```

### ❌ Don't: Use Locks/Semaphores

```swift
// ❌ WRONG - Use actors instead
class MyManager {
    private let lock = NSLock()
    private var data: [Item] = []
    
    func update() {
        lock.lock()
        defer { lock.unlock() }
        data.append(item)  // Blocks thread!
    }
}
```

---

## Migration Checklist

If you're considering removing MainActor, ask yourself:

- [ ] Does this improve performance? (Probably not)
- [ ] Does this simplify the code? (Definitely not)
- [ ] Does this reduce bugs? (No, increases them)
- [ ] Is there a specific requirement? (Unlikely)
- [ ] Have you measured the impact? (Required)

**If you answered "No" to any of these, keep @MainActor.**

---

## Performance Guidelines

### MainActor is Fast Enough When:

✅ UI updates (always)  
✅ Coordination logic (< 100ms)  
✅ Simple transformations (< 10ms)  
✅ State management (always)

### Move to Background When:

⚠️ Heavy computation (> 100ms)  
⚠️ Large data processing (> 1MB)  
⚠️ File I/O operations  
⚠️ Image processing

---

## Testing Patterns

### Testing @MainActor Code

```swift
@MainActor
final class MyViewModelTests: XCTestCase {
    func testUpdate() async {
        let viewModel = MyViewModel(interactor: mockInteractor)
        await viewModel.performAction()
        XCTAssertEqual(viewModel.state, .success)
    }
}
```

### Testing nonisolated Code

```swift
final class MyServiceTests: XCTestCase {
    func testFetch() async throws {
        let service = MyService()
        let result = try await service.fetch()
        XCTAssertFalse(result.isEmpty)
    }
}
```

---

## Troubleshooting

### Compiler Error: "Call to main actor-isolated property 'x' in a synchronous nonisolated context"

**Solution**: Add `@MainActor` to the calling function or use `Task { @MainActor }`

### Compiler Error: "Expression is 'async' but is not marked with 'await'"

**Solution**: Add `await` before the async call

### Runtime Warning: "Publishing changes from background threads is not allowed"

**Solution**: Wrap the update in `Task { @MainActor }` or mark the class `@MainActor`

---

## Resources

- [Full Analysis](./MAINACTOR_ALTERNATIVES_ANALYSIS.md)
- [Code Examples](./MAINACTOR_CODE_EXAMPLES.md)
- [Concurrency Analysis](./CONCURRENCY_ANALYSIS.md)
- [Combine Integration](./MAINACTOR_COMBINE_ANALYSIS.md)

---

**Last Updated**: 2025-12-04  
**Status**: ✅ Production Ready

