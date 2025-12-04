# Combine Framework: Quick Reference Guide

> **Quick lookup for common patterns and operators**  
> **Last Updated**: December 3, 2025

---

## 🎯 Common Patterns

### **Pattern: Simple Network Request**

```swift
func fetchData() -> AnyPublisher<Data, Error> {
    URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}
```

---

### **Pattern: Network + JSON Decoding**

```swift
func fetchUsers() -> AnyPublisher<[User], Error> {
    URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: [User].self, decoder: JSONDecoder())
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
}
```

---

### **Pattern: Background Processing**

```swift
func processData() -> AnyPublisher<Result, Error> {
    dataPublisher
        .subscribe(on: backgroundQueue)      // Process on background
        .map { expensiveTransform($0) }      // Heavy work here
        .receive(on: DispatchQueue.main)     // Deliver on main
        .eraseToAnyPublisher()
}
```

---

### **Pattern: Debounced Search**

```swift
searchTextField.textPublisher
    .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
    .removeDuplicates()
    .filter { !$0.isEmpty }
    .flatMap { query in searchAPI(query) }
    .receive(on: DispatchQueue.main)
    .sink { results in updateUI(results) }
    .store(in: &cancellables)
```

---

### **Pattern: Throttled Events**

```swift
locationPublisher
    .throttle(for: .seconds(2.0), scheduler: DispatchQueue.main, latest: true)
    .removeDuplicates()
    .sink { location in updateMap(location) }
    .store(in: &cancellables)
```

---

### **Pattern: Merge Multiple Sources**

```swift
let merged = Publishers.Merge(networkPublisher, cachePublisher)
    .collect()
    .map { arrays in arrays.flatMap { $0 } }
    .eraseToAnyPublisher()
```

---

### **Pattern: Combine Latest**

```swift
Publishers.CombineLatest(dataPublisher, settingsPublisher)
    .map { data, settings in process(data, with: settings) }
    .sink { result in updateUI(result) }
    .store(in: &cancellables)
```

---

### **Pattern: Error Handling**

```swift
publisher
    .mapError { error -> MyError in
        return .network(error)
    }
    .retry(3)
    .catch { error in
        Just(defaultValue)
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
```

---

### **Pattern: @MainActor Service**

```swift
@MainActor
class Service {
    @Published private(set) var isLoading = false
    private var cancellables = Set<AnyCancellable>()
    nonisolated private let processingQueue = DispatchQueue(...)
    
    nonisolated func fetchPublisher() -> AnyPublisher<Data, Error> {
        return URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents(
                receiveSubscription: { _ in
                    Task { @MainActor [weak self] in
                        self?.isLoading = true
                    }
                },
                receiveCompletion: { _ in
                    Task { @MainActor [weak self] in
                        self?.isLoading = false
                    }
                }
            )
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
```

---

## 🔧 Operator Cheat Sheet

### **Transformation**

| Operator | Input → Output | Use Case |
|----------|----------------|----------|
| `.map { }` | `T → U` | Transform each value |
| `.flatMap { }` | `T → Publisher<U>` | Chain publishers |
| `.compactMap { }` | `T → U?` | Transform + filter nil |
| `.tryMap { }` | `T throws → U` | Transform with errors |
| `.decode(type:decoder:)` | `Data → Decodable` | JSON decoding |
| `.scan(initial) { }` | `(Acc, T) → Acc` | Accumulate values |

### **Filtering**

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `.filter { }` | Keep matching values | Validate input |
| `.removeDuplicates()` | Skip consecutive duplicates | Avoid redundant work |
| `.first()` | Take first value only | Get current state |
| `.last()` | Take last value only | Final result |
| `.dropFirst(n)` | Skip first n values | Ignore initial state |
| `.prefix(n)` | Take first n values | Limit results |

### **Combining**

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `Publishers.Merge` | Emit from any source | Network + Cache |
| `Publishers.CombineLatest` | Emit when any updates | Data enrichment |
| `Publishers.Zip` | Pair values | Synchronize streams |
| `.flatMap { }` | Switch to new publisher | Dependent requests |
| `.switchToLatest()` | Cancel previous | Search-as-you-type |

### **Timing**

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `.debounce(for:scheduler:)` | Wait for pause | Text input |
| `.throttle(for:scheduler:latest:)` | Limit frequency | Location updates |
| `.delay(for:scheduler:)` | Delay emission | Animations |
| `.timeout(_:scheduler:)` | Fail if too slow | Network timeout |

### **Error Handling**

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `.catch { }` | Recover from error | Fallback value |
| `.retry(n)` | Retry n times | Network resilience |
| `.mapError { }` | Transform error | Error mapping |
| `.replaceError(with:)` | Replace with value | Default value |
| `.setFailureType(to:)` | Change error type | Type compatibility |

### **Side Effects**

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `.handleEvents(...)` | Observe lifecycle | Logging, state updates |
| `.print(_)` | Debug logging | Development |

### **Threading**

| Operator | Behavior | Critical! |
|----------|----------|-----------|
| `.subscribe(on:)` | Set upstream thread | Where work happens |
| `.receive(on:)` | Set downstream thread | Where results go |

---

## 🧵 Threading Rules

### **Golden Rules**

1. **Use `.subscribe(on:)` for expensive work**
   ```swift
   .subscribe(on: backgroundQueue)  // Network, decoding, transformation
   ```

2. **Use `.receive(on:)` for UI updates**
   ```swift
   .receive(on: DispatchQueue.main)  // Always before sink/assign
   ```

3. **Update @Published on MainActor**
   ```swift
   Task { @MainActor [weak self] in
       self?.isLoading = true
   }
   ```

4. **Mark classes @MainActor for state**
   ```swift
   @MainActor
   class Service {
       @Published var state = ...
   }
   ```

5. **Mark publishers nonisolated**
   ```swift
   nonisolated func fetchPublisher() -> AnyPublisher<...> { }
   ```

---

## 🧠 Memory Management Rules

### **Golden Rules**

1. **Always use [weak self] in closures**
   ```swift
   .flatMap { [weak self] value in
       guard let self = self else { return Empty().eraseToAnyPublisher() }
       return self.process(value)
   }
   ```

2. **Store cancellables**
   ```swift
   private var cancellables = Set<AnyCancellable>()
   
   publisher.sink { }.store(in: &cancellables)
   ```

3. **Clean up in deinit**
   ```swift
   deinit {
       cancellables.removeAll()
   }
   ```

---

## ⚠️ Common Mistakes

### **❌ Mistake 1: Forgetting to store cancellable**

```swift
// ❌ WRONG: Subscription cancelled immediately
publisher.sink { value in print(value) }

// ✅ CORRECT: Store for lifecycle
publisher.sink { value in print(value) }
    .store(in: &cancellables)
```

---

### **❌ Mistake 2: Strong self capture**

```swift
// ❌ WRONG: Retain cycle
.flatMap { value in
    self.process(value)  // Strong reference!
}

// ✅ CORRECT: Weak reference
.flatMap { [weak self] value in
    guard let self = self else { return Empty().eraseToAnyPublisher() }
    return self.process(value)
}
```

---

### **❌ Mistake 3: Blocking main thread**

```swift
// ❌ WRONG: Heavy work on main thread
URLSession.shared.dataTaskPublisher(for: url)
    .decode(type: Data.self, decoder: JSONDecoder())  // Main thread!
    .receive(on: DispatchQueue.main)

// ✅ CORRECT: Decode on background
URLSession.shared.dataTaskPublisher(for: url)
    .subscribe(on: backgroundQueue)
    .decode(type: Data.self, decoder: JSONDecoder())  // Background!
    .receive(on: DispatchQueue.main)
```

---

### **❌ Mistake 4: Accessing @Published from background**

```swift
// ❌ WRONG: Cross-actor access
nonisolated func fetch() {
    self.isLoading = true  // Compiler error!
}

// ✅ CORRECT: Use Task { @MainActor }
nonisolated func fetch() {
    Task { @MainActor [weak self] in
        self?.isLoading = true
    }
}
```

---

### **❌ Mistake 5: Not handling errors**

```swift
// ❌ WRONG: Errors crash the stream
publisher
    .sink { value in print(value) }

// ✅ CORRECT: Handle errors
publisher
    .catch { error in Just(defaultValue) }
    .sink { value in print(value) }
```

---

## 🧪 Testing Patterns

### **Pattern: Mock URLProtocol**

```swift
class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: HTTPURLResponse?
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

// Usage
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)
```

---

### **Pattern: Test with Expectation**

```swift
@MainActor
func testPublisher() async throws {
    let expectation = XCTestExpectation(description: "Completes")
    
    publisher
        .sink(
            receiveCompletion: { _ in expectation.fulfill() },
            receiveValue: { value in XCTAssertEqual(value, expected) }
        )
        .store(in: &cancellables)
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

---

## 📊 Decision Tree

### **When to use which operator?**

```
Need to transform values?
├─ Simple transform? → .map { }
├─ Chain publisher? → .flatMap { }
├─ Filter nil? → .compactMap { }
└─ Can throw? → .tryMap { }

Need to filter values?
├─ Condition? → .filter { }
├─ Duplicates? → .removeDuplicates()
├─ First only? → .first()
└─ Skip initial? → .dropFirst()

Need to combine publishers?
├─ Any source? → Publishers.Merge
├─ All sources? → Publishers.CombineLatest
├─ Pair values? → Publishers.Zip
└─ Switch streams? → .switchToLatest()

Need to control timing?
├─ Wait for pause? → .debounce()
├─ Limit frequency? → .throttle()
├─ Delay? → .delay()
└─ Timeout? → .timeout()

Need to handle errors?
├─ Recover? → .catch { }
├─ Retry? → .retry(n)
├─ Transform? → .mapError { }
└─ Replace? → .replaceError(with:)

Need to control threading?
├─ Background work? → .subscribe(on:)
└─ UI updates? → .receive(on: DispatchQueue.main)
```

---

## ✅ Checklist

Before shipping Combine code, verify:

- ✅ All cancellables stored in `Set<AnyCancellable>`
- ✅ All closures use `[weak self]`
- ✅ Expensive work on background thread (`.subscribe(on:)`)
- ✅ UI updates on main thread (`.receive(on: DispatchQueue.main)`)
- ✅ @Published properties are @MainActor-isolated
- ✅ State updates use `Task { @MainActor }`
- ✅ Errors handled with `.catch` or `.retry`
- ✅ Tests use MockURLProtocol
- ✅ No retain cycles (verified with tests)
- ✅ Proper cleanup in `deinit`

---

**Quick Reference Complete** ✅  
**For detailed explanations, see**: `COMBINE_FRAMEWORK_GUIDE.md`  
**For correctness analysis, see**: `COMBINE_CORRECTNESS_ANALYSIS.md`

