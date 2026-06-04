# Persistence: SwiftData, the Keychain, Files, and CryptoKit

On a backend, persistence is somebody else's process. You write
`@Entity` classes, point `persistence.xml` at a connection pool, and
Hibernate talks to a Postgres that runs on its own host with its own
backups, its own disk encryption, its own auth. Your application is a
stateless client of that durable thing.

On a phone there is no other process. Your app *is* the database host,
the file server, the key-management service, and the backup policy — all
inside one sandboxed directory that the OS can wipe, encrypt, or back up
to iCloud depending on *which subfolder* you chose. Alltag pushes this to
the limit: it is a paid app with **no backend at all**. Every byte —
structured metadata, encrypted document blobs, the encryption key itself
— lives on the device. This chapter maps the four pieces of that local
stack onto the JVM tools you already know, then shows how Alltag wires
them together.

| Concern | Backend (Java) | Alltag (iOS) |
|---|---|---|
| Structured data | JPA + Postgres | SwiftData |
| Bulk bytes | S3 / filesystem | Files + CryptoKit |
| Secrets | Java `KeyStore` | the Keychain |
| Small prefs | properties file | `UserDefaults` |

## SwiftData: JPA without the server

`SwiftData` is Apple's modern ORM, layered over the old Core Data
engine the way JPA is layered over JDBC. If you have used Panache, the
ergonomics will feel familiar — declarative models, very little
boilerplate — but the runtime is an embedded SQLite file, not a remote
server.

A model is a class annotated with the `@Model` macro. This is the
`@Entity` of the framework. Here is Alltag's `DocumentRecord` verbatim:

```swift
@Model
final class DocumentRecord {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var category: String
    var createdAt: Date
    var expiresAt: Date?

    init(
        id: UUID = UUID(),
        fileName: String,
        category: String = "uncategorized",
        createdAt: Date = .now,
        expiresAt: Date? = nil
    ) { /* assign each property */ }
}
```

Three things differ sharply from JPA. First, `@Model` is a *macro*, not
a runtime annotation: at compile time it rewrites the class, turning
every stored property into an observed, persisted attribute and
synthesizing the schema. There is no reflection-at-startup scan and no
`persistence.xml` listing classes. Second, `@Attribute(.unique)` on `id`
is the rough equivalent of a `@Column(unique = true)` plus upsert
semantics — inserting a second record with the same `id` *updates* the
existing row rather than throwing a constraint violation. Third, there is
no separate `@Id` annotation forcing a primary key; SwiftData manages an
internal row identity for you, and `id` here is just an application key
that doubles as the address of the encrypted blob on disk.

> **Quarkus analogy.** `@Model` is `@Entity`, but the class is `final`
> and value-typed in spirit — no lazy proxies, no `@ManyToOne` fetch
> joins firing N+1 queries behind your back. Relationships exist (see
> below) but the cost model is local SQLite, not a network round trip,
> so the failure modes you instrument for in Quarkus mostly evaporate.

### The container, the configuration, the context

Alltag's `PersistenceController` owns the stack. Compare its members to
the JPA bootstrap you know:

| SwiftData | JPA |
|---|---|
| `Schema` | set of `@Entity` classes |
| `ModelConfiguration` | `persistence.xml` unit |
| `ModelContainer` | `EntityManagerFactory` |
| `ModelContext` | `EntityManager` / session |

The `Schema` is built explicitly, listing the model types:

```swift
static let schema = Schema([
    DocumentRecord.self,
])
```

The init then assembles a `ModelConfiguration` (which store file, in
memory or not) and from it a `ModelContainer`:

```swift
let configuration = ModelConfiguration(
    schema: Self.schema, url: url)
container = try ModelContainer(
    for: Self.schema, configurations: [configuration])
```

The `ModelContainer` is the heavyweight, thread-safe, app-lifetime
object — exactly like an `EntityManagerFactory`. You build **one**. From
it you draw `ModelContext` instances, which are the unit-of-work,
short-lived, *not* thread-safe analogue of an `EntityManager`. The
container hands you a `mainContext` bound to the main actor for UI work;
background work creates its own `ModelContext(container)` off the
`Sendable` container, just as you would open a fresh `EntityManager` per
request rather than sharing one across threads.

Note the class is `@MainActor`:

```swift
@MainActor
final class PersistenceController {
    let container: ModelContainer
```

That annotation is the concurrency contract: the default context lives
on the main thread, so accessing it from a background task is a compile
error, not a runtime `IllegalStateException`. Strict concurrency turns
the "never share an `EntityManager`" rule into a checked invariant.

### CRUD and `@Query`

A context exposes `insert(_:)`, `delete(_:)`, and `save()`. The
unit-of-work shape mirrors JPA's persistence context: inserted objects
are tracked, mutations are flushed on `save()`. SwiftData also
auto-saves periodically, which has no clean JPA equivalent — treat
explicit `save()` as you would `flush()` plus `commit()`.

```swift
let record = DocumentRecord(fileName: "Anmeldung")
context.insert(record)
try context.save()
```

Reading is where SwiftData diverges most pleasantly. Instead of writing
JPQL or a Panache `list(...)`, views declare a `@Query` property that the
framework keeps *live*: it re-runs and re-renders when the underlying
data changes.

```swift
@Query(sort: \DocumentRecord.createdAt, order: .reverse)
private var records: [DocumentRecord]
```

There is no JPA analogue to a query that is also a reactive data source
wired straight into the render loop. The closest mental model is a
Panache `list()` whose result is automatically re-fetched and pushed to
the client whenever a relevant row changes — except it is synchronous,
in-process, and free. For imperative fetches outside a view you use a
`FetchDescriptor` with a `#Predicate`, which is the type-safe,
compile-checked cousin of a JPA `CriteriaQuery`.

> **Note.** `#Predicate` closures are compiled into SQLite `WHERE`
> clauses, so only a subset of Swift is legal inside them — much like a
> JPA criteria expression cannot contain arbitrary Java. If you reach
> for something the translator rejects, you get a build-time or
> runtime error, not a silent full-table scan.

### Migrations, briefly

Add a non-optional property without a default and the existing store no
longer matches the schema. SwiftData performs **lightweight migrations**
automatically for additive, inferable changes (new optional attribute,
renamed-with-hint) — the equivalent of Hibernate's `hbm2ddl.auto=update`
but safer, because it refuses ambiguous changes rather than guessing.
For anything structural you write a `SchemaMigrationPlan` with explicit
`VersionedSchema` stages, the disciplined analogue of a Flyway script.
Alltag is on its foundation slice (one entity), so it relies on
lightweight inference for now; the model comments flag where richer
fields land later.

## The sandbox: which directory, and why it matters

A backend has no concept of this. Your process can write anywhere its
user can; backup and cleanup are the ops team's problem. An iOS app runs
in a **sandbox** — a per-app container the OS owns — and the subfolder
you choose silently decides three policies: *is it backed up to iCloud /
iTunes*, *can the OS delete it under storage pressure*, and *does it
survive app updates*.

| Directory | Backed up | OS may purge | Use for |
|---|---|---|---|
| Documents | yes | no | user-visible files |
| App Support | yes | no | app-private data |
| Caches | no | yes | rebuildable data |
| tmp | no | yes | scratch |

Getting this wrong is a real bug class with no server analogue: put your
SQLite store in Caches and the OS may delete it mid-flight to reclaim
space; put rebuildable thumbnails in Documents and you bloat the user's
iCloud backup. `FileManager` is the API — there is no `new File(path)`
with an absolute path you control; you *ask* for a directory by its
semantic role:

```swift
let appSupport = try FileManager.default.url(
    for: .applicationSupportDirectory,
    in: .userDomainMask,
    appropriateFor: nil, create: true)
```

Alltag places its **SwiftData store** in Application Support
(`Application Support/Alltag/Alltag.store`), because it is app-private
structured data that must outlive updates and is never shown to the user
as files. `PersistenceController.defaultStoreURL()` builds exactly that
path, creating intermediate directories on demand. The **document
blobs**, by contrast, are user-owned content, so `EncryptedFileStore`
puts them under a `Documents/Vault` subfolder:

```swift
let docs = try FileManager.default.url(
    for: .documentDirectory, in: .userDomainMask,
    appropriateFor: nil, create: true)
self.directory = docs.appendingPathComponent(
    "Vault", isDirectory: true)
```

> **Gotcha.** "Backed up to iCloud" cuts against a privacy-first design:
> anything in Documents *can* leave the device in the user's encrypted
> backup. Alltag's answer is that the blobs are themselves encrypted with
> a key marked `ThisDeviceOnly` (next sections), so even a backup of the
> ciphertext is inert without the device's Keychain.

### File protection

Beyond the directory choice, iOS offers per-file at-rest encryption tied
to the device passcode, with no JVM equivalent. `EncryptedFileStore`
writes every blob with `FileProtectionType.complete` semantics via the
write options:

```swift
try ciphertext.write(
    to: url, options: [.atomic, .completeFileProtection])
```

`.completeFileProtection` means the file's bytes are inaccessible — even
to the app — while the device is locked. `.atomic` writes to a temp file
and renames, the same write-then-rename durability trick you would do by
hand on a server. This is a *second* layer beneath Alltag's own
CryptoKit encryption: defence in depth, not redundancy.

## CryptoKit: authenticated encryption without the footguns

If you have written `javax.crypto`, you remember the ceremony: pick a
`Cipher` transformation string, manage an `IvParameterSpec`, choose a
padding, wrap a `SecretKeySpec`, and pray you didn't reuse a nonce or
pick ECB. JCA is powerful and almost entirely misuse-prone — the API
lets you do the wrong thing by default.

**CryptoKit** is the opposite: a small, modern, misuse-resistant API
where the safe path is the only obvious path. Alltag's `FileCryptor` is
the whole encryption surface, and it fits in a screen:

```swift
struct FileCryptor {
    func encrypt(_ plaintext: Data,
                 using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw FileCryptorError.sealingFailed
        }
        return combined
    }

    func decrypt(_ ciphertext: Data,
                 using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }
}
```

Several things are doing heavy lifting here. `AES.GCM.seal` uses
**AES-256 in Galois/Counter Mode**, an *authenticated* cipher: the
output carries an authentication tag, so decryption verifies integrity
*and* authenticity, not just confidentiality. Tamper with one bit and
`AES.GCM.open` throws rather than returning corrupted plaintext — there
is no "decrypt to garbage" failure mode. In JCA you get this with
`AES/GCM/NoPadding` plus a `GCMParameterSpec`, but you must wire it
correctly; here it is the default and only mode.

You never see an IV. `seal` generates a fresh random nonce per call and
packs it into `sealed.combined` as `nonce ‖ ciphertext ‖ tag`. That one
`Data` blob is self-contained and exactly what Alltag writes to disk.
The nonce-reuse catastrophe that haunts GCM in JCA — same key, same IV,
total break — is structurally prevented because you cannot accidentally
hold an IV constant.

The `FileCryptorTests` prove all three properties as executable spec:

```swift
func testTamperedCiphertextFailsAuthentication() throws {
    var ciphertext = try cryptor.encrypt(
        Data("secret".utf8), using: key)
    ciphertext[ciphertext.count - 1] ^= 0xFF
    XCTAssertThrowsError(
        try cryptor.decrypt(ciphertext, using: key))
}
```

Flip a tag bit, `open` throws — round-trip, wrong-key, and tamper cases
are all covered. A `SymmetricKey(size: .bits256)` is just 32 bytes of
secure-random material; the interesting question is where those bytes
*live* between launches. That is the Keychain's job.

## The Keychain: the device's KeyStore

A Java `KeyStore` is an encrypted file (JKS, PKCS12) holding keys and
certs, unlocked by a passphrase your app supplies — and critically, *you*
manage that file and that passphrase. The iOS **Keychain** is a
system-wide secure credential store: a small encrypted database the OS
owns, protected by a hardware-backed keybag whose master keys never leave
the Secure Enclave. Your app does not hold the unlock secret; the OS
gates access by the device passcode and per-item accessibility rules.

So the Keychain is less "a `KeyStore` file you open" and more "a managed
secrets service running inside the OS, scoped to your app." It is where
secrets go *because* the device hardware protects it; the SwiftData store
and `UserDefaults`, by contrast, are ordinary files with no such
protection — putting a key there would be like committing your
`keystore.jks` *and* its password to the repo.

Alltag's `KeychainKeyStore` stores the AES key as a **generic-password**
item. The API is the unreconstructed C-style `SecItem*` family — you
build a `[String: Any]` query dictionary out of `kSec...` constants and
hand it to a free function returning an `OSStatus`. It is JCA-grade
verbose; Alltag wraps it behind the tiny `KeyProviding` protocol.

Reading uses `SecItemCopyMatching`:

```swift
var query = baseQuery()
query[kSecReturnData as String] = true
query[kSecMatchLimit as String] = kSecMatchLimitOne

var item: CFTypeRef?
let status = SecItemCopyMatching(query as CFDictionary, &item)
switch status {
case errSecSuccess:    return item as? Data
case errSecItemNotFound: return nil
default: throw KeyStoreError.keychain(status)
}
```

Writing uses `SecItemAdd`, and crucially sets the **accessibility
class**:

```swift
attributes[kSecAttrAccessible as String] =
    kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
```

`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` packs three policy
decisions. *AfterFirstUnlock*: the key is unavailable until the user
unlocks once after boot, then stays available (so background work can
decrypt) — the right tradeoff for at-rest data that the app touches
while running. *ThisDeviceOnly*: the item is never migrated to a new
device and never synced to iCloud Keychain, so the key cannot leave this
hardware. This is the linchpin of the privacy story: even if the
encrypted Documents blobs ride along in an iCloud backup, the key that
opens them does not.

The whole get-or-create lifecycle is one method:

```swift
func symmetricKey() throws -> SymmetricKey {
    if let existing = try loadKeyData() {
        guard existing.count == 32 else {
            throw KeyStoreError.malformedKey
        }
        return SymmetricKey(data: existing)
    }
    let key = SymmetricKey(size: .bits256)
    let data = key.withUnsafeBytes { Data($0) }
    try store(data)
    return key
}
```

First call mints and persists a 256-bit key; every later call returns the
same bytes. `reset()` wraps `SecItemDelete` and is the GDPR "delete all
my data" hook — wiping the key cryptographically shreds every blob at
once, since the ciphertext is now unopenable. That is a property a
backend rarely gets for free: revoking the key *is* the deletion.

> **Gotcha.** Keychain items survive app *deletion* on some iOS versions
> and are awkward to exercise in unhosted simulator test runs. That is
> exactly why `KeyProviding` is a protocol: production uses
> `KeychainKeyStore`; tests inject `InMemoryKeyStore`, a deterministic
> key with no Keychain dependency at all.

## UserDefaults: the properties file

For small, non-secret preferences — chosen language, chosen theme — the
Keychain is overkill and SwiftData is too heavy. **`UserDefaults`** is
the iOS equivalent of a properties file plus the Java `Preferences` API:
a key-value plist the OS persists for you, ideal for scalars and short
strings, wrong for anything large or sensitive (it is an unencrypted file
in the sandbox).

Alltag's `LanguageStore` and `ThemeController` each persist exactly one
string key. The pattern is identical:

```swift
func select(_ theme: AppTheme) {
    self.theme = theme
    defaults.set(theme.rawValue, forKey: Self.storageKey)
}
```

On init they read the string back and decode it into the enum, falling
back to a default if absent or unrecognized:

```swift
if let raw = defaults.string(forKey: Self.storageKey),
   let stored = AppTheme(rawValue: raw) {
    theme = stored
} else {
    theme = .system
}
```

Note that `defaults` is injected (`init(defaults: UserDefaults =
.standard)`) so tests pass an isolated suite — the same dependency-
inversion move as the `KeyProviding` protocol, applied to the prefs
store. Both classes are `@Observable`, so changing the value re-renders
the views that read it; persistence and reactivity come together.

## Tying it together: the Vault save path

Now the four pieces compose. Alltag's design splits each document into a
*searchable metadata half* and an *encrypted bytes half*, deliberately
kept apart:

- **Metadata** -> SwiftData `DocumentRecord` (id, name, category,
  dates). Small, queryable, drives the UI list.
- **Bytes** -> `EncryptedFileStore`, an encrypted blob on disk addressed
  by the record's `id` (`"\(id).bin"`).
- **Key** -> `KeychainKeyStore`, the one 256-bit key all blobs share.

Keeping blobs out of SwiftData keeps the store small and lets the OS
apply file-level protection to the heavy data — you would not store
multi-megabyte scans as `byte[]` columns in your Postgres either; you'd
put them in object storage and keep a row pointing at them. Same split,
no server.

The save path runs top to bottom in `EncryptedFileStore.save`:

```swift
@discardableResult
func save(_ data: Data, id: String) throws -> URL {
    let key = try keyStore.symmetricKey()
    let ciphertext = try cryptor.encrypt(data, using: key)
    let url = fileURL(for: id)
    try ciphertext.write(
        to: url,
        options: [.atomic, .completeFileProtection])
    return url
}
```

Read it as a pipeline:

1. **Fetch the key** from the Keychain (`symmetricKey()`), minting it on
   first ever call.
2. **Encrypt** the plaintext with `FileCryptor` -> AES-GCM combined
   blob, integrity tag included.
3. **Write** atomically with `.completeFileProtection`, so plaintext
   never touches disk and the ciphertext is itself OS-encrypted at rest.
4. **Index** the metadata: the caller inserts a `DocumentRecord` whose
   `id` matches the blob's filename and `save()`s the context.

Load is the mirror image: read the `.bin`, fetch the same key, `open`
the sealed box (which fails loudly if the file was tampered with).
Delete a document and you remove both the SwiftData row and the blob; run
`KeychainKeyStore.reset()` and you shred *everything* at once.

The whole thing is testable without a device because every boundary is
inverted: `PersistenceController(inMemory: true)` gives an ephemeral
SwiftData store, and `InMemoryKeyStore` gives a fixed key — so the
encryption round-trip and the persistence logic run in milliseconds in
CI, with no Keychain, no disk, and no server anywhere in sight.

## Takeaways

- SwiftData is your JPA: `@Model` for `@Entity`, `ModelContainer` for
  `EntityManagerFactory`, `ModelContext` for the session, `@Query` for a
  *live* JPQL/Panache list — but the store is an embedded SQLite file you
  host yourself.
- The sandbox directory is a policy decision with no server analogue:
  Application Support for the app-private store, Documents for user
  content, never Caches/tmp for anything that must survive.
- CryptoKit's `AES.GCM.seal`/`open` is authenticated encryption with the
  footguns removed — random nonce, integrity tag, no IV to misuse — where
  JCA leaves all of that to you.
- The Keychain is the device's `KeyStore`, but OS-managed and hardware-
  backed; `ThisDeviceOnly` accessibility is what keeps the key from ever
  leaving the device, making encrypted backups inert.
- Alltag composes all four: metadata in SwiftData, ciphertext on disk,
  key in the Keychain — and every boundary is a protocol, so the full
  save path runs in-memory in tests.

**Next:** *The Toolchain: Xcode, SPM, XcodeGen, and the Build*
