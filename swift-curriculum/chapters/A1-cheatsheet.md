# Java/Quarkus to Swift/SwiftUI Cheat Sheet

A keep-it-open translation table. Left is what you know; right is the
Swift/SwiftUI equivalent. Notes flag the cases where the mapping leaks.
Examples reference the Alltag app (`AppEnvironment`, `DocumentRecord`,
`KeychainKeyStore`).

## Language constructs

| Java/Quarkus | Swift | Note |
|---|---|---|
| `record` | `struct` | Value type; memberwise init free. |
| sealed interface | `enum` | Cases carry associated values. |
| `interface` | `protocol` | Can have default impls. |
| abstract class | protocol + extension | No state in the extension. |
| `Optional<T>` | `T?` | Language-level, no boxing. |
| `null` | `nil` | Only for optionals. |
| `<T>` generics | `<T>` | Reified, not erased. |
| lambda | closure | `{ x in ... }`. |
| `Stream` | `map`/`filter`/`reduce` | Eager, on `Array`. |
| `.collect(toList())` | returns `Array` | No terminal op needed. |
| `final` field | `let` | Immutable binding. |
| `var` (mutable) | `var` | Mutable binding. |
| `instanceof` | `is` | Returns `Bool`. |
| cast `(T)x` | `as?` / `as!` | `as?` is safe, `as!` traps. |
| `static` member | `static` | On struct/enum/class. |
| `static` (overridable) | `class` | On class only. |
| checked exception | `throws` | Untyped; no signature list. |
| `equals`/`hashCode` | `Equatable`/`Hashable` | Often synthesized. |
| `toString()` | `CustomStringConvertible` | `var description`. |
| `Comparable` | `Comparable` | Implement `<`. |
| `cond ? a : b` | `cond ? a : b` | Same ternary. |
| `x != null ? x : y` | `x ?? y` | Nil-coalescing. |
| enhanced `switch` | `switch` | Exhaustive, no fallthrough. |
| `enum` (plain) | `enum` | Plus raw/associated values. |
| varargs `T...` | `T...` | Variadic param. |
| `this` | `self` | Explicit in closures. |

```swift
// sealed interface -> enum with associated values
enum LoadState {
    case idle
    case loading
    case loaded([DocumentRecord])
    case failed(Error)
}
```

```java
// Java equivalent
sealed interface LoadState
    permits Idle, Loading, Loaded, Failed {}
```

## Concurrency

| Java/Quarkus | Swift | Note |
|---|---|---|
| `new Thread(r)` | `Task { }` | Cooperative, not 1:1. |
| `Runnable` | closure / `@Sendable` | |
| `CompletableFuture<T>` | `async` func | Returns `T`. |
| `Uni<T>` (Mutiny) | `async` func | `await` to resolve. |
| `.thenApply` | `await` then call | Linear code. |
| `ExecutorService` | `TaskGroup` | Structured. |
| submit + join | `async let` | Child task, awaited. |
| `synchronized` | `actor` | Serializes access. |
| `Lock` | `actor` | No manual lock/unlock. |
| `volatile` | `Sendable` | Compile-checked. |
| thread-safety | `Sendable` | Enforced by compiler. |
| EDT / UI thread | `@MainActor` | Annotate type or func. |
| `SwingUtilities.invokeLater` | `await MainActor.run` | |
| `ThreadLocal<T>` | `@TaskLocal` | Inherited by children. |
| `future.cancel(true)` | `task.cancel()` | Cooperative. |
| check interrupted | `Task.isCancelled` | Or `try Task.checkCancellation()`. |

```swift
// async let — parallel children, awaited together
async let docs = store.fetchDocuments()
async let user = api.currentUser()
let view = ViewModel(docs: try await docs,
                     user: try await user)
```

## Build & tooling

| Maven/Gradle | Swift | Note |
|---|---|---|
| Maven / Gradle | SPM + Xcode | SPM for libs/deps. |
| `pom.xml` | `Package.swift` | Manifest is Swift code. |
| `build.gradle` | `project.yml` | XcodeGen (Alltag). |
| generated `.idea` | generated `.xcodeproj` | Don't commit it. |
| `mvn test` | `xcodebuild test` | |
| JUnit 5 | Swift Testing | New; XCTest also OK. |
| `@Test` | `@Test` | Swift Testing macro. |
| `assertEquals(a,b)` | `#expect(a == b)` | Swift Testing. |
| `assertEquals(a,b)` | `XCTAssertEqual(a,b)` | XCTest. |
| `assertThrows` | `#expect(throws:)` | |
| Mockito mock | protocol + hand fake | No mock framework. |
| `@InjectMock` | inject a fake impl | Via initializer. |
| JAR artifact | `.app` / `.ipa` | Bundle, not archive. |
| `mvn package` | Archive | Product > Archive. |
| IntelliJ IDEA | Xcode | |
| `~/.m2` | `~/Library/Caches` SPM | Resolved per project. |

```swift
// Mockito -> protocol + hand-written fake
protocol KeyStore {
    func key(for id: String) throws -> SymmetricKey
}
struct FakeKeyStore: KeyStore {
    var stub: SymmetricKey
    func key(for id: String) throws -> SymmetricKey {
        stub
    }
}
```

## Runtime, DI & frameworks

| Java/Quarkus | Swift / SwiftUI | Note |
|---|---|---|
| `@Inject` | `@Environment` | Resolve from env. |
| `@ApplicationScoped` bean | `@Observable` class | Held in environment. |
| CDI producer `@Produces` | `static func live()` | Factory on the type. |
| `@PostConstruct` | initializer | Plain `init`. |
| bean scope (request) | view lifetime / `@State` | |
| `application.properties` | `Info.plist` | Static config. |
| runtime config | `UserDefaults` | Mutable prefs. |
| `@ConfigProperty` | `@AppStorage` | Bound to `UserDefaults`. |
| JPA `@Entity` | `@Model` | SwiftData macro. |
| `EntityManager` | `ModelContext` | Unit of work. |
| `em.persist(x)` | `context.insert(x)` | |
| Panache `list()` | `FetchDescriptor` | Typed query. |
| named query / `@Query` | `#Predicate` | In `FetchDescriptor`. |
| `EntityManagerFactory` | `ModelContainer` | App-wide. |
| `@Transactional` | `context.save()` | Explicit save. |
| Jackson `@JsonProperty` | `Codable` | Synthesized. |
| `@JsonProperty("x")` | `CodingKeys` | Rename mapping. |
| `ObjectMapper` | `JSONEncoder`/`Decoder` | |
| SLF4J `Logger` | `os.Logger` | Unified logging. |
| `log.info(...)` | `logger.info("...")` | |
| JAX-RS `RestClient` | `URLSession` | `data(for:)` async. |
| `@Path` / `@GET` | build `URLRequest` | No annotations. |
| Bean Validation `@NotNull` | `guard` / `throws` | Validate in code. |
| `KeyStore` / JCA | Keychain + CryptoKit | `KeychainKeyStore`. |
| `Cipher` AES-GCM | `AES.GCM.seal` | CryptoKit. |

```swift
// CDI @Inject -> @Environment
struct DocumentList: View {
    @Environment(AppEnvironment.self) private var env
    var body: some View {
        List(env.documents) { Text($0.title) }
    }
}
```

```swift
// CDI producer -> static live() factory
extension AppEnvironment {
    static func live() -> AppEnvironment {
        AppEnvironment(keyStore: KeychainKeyStore(),
                       container: .live())
    }
}
```

```swift
// Panache list() -> FetchDescriptor + #Predicate
let recent = FetchDescriptor<DocumentRecord>(
    predicate: #Predicate { $0.isArchived == false },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
let docs = try context.fetch(recent)
```

**Next:** the gotchas that this table can't warn you about — see *Idioms and Gotchas for Java Developers*.
