import Dependencies
import Foundation

extension PersistenceReaderKey {
  /// Creates a persistence key for sharing data in-memory for the lifetime of an application.
  ///
  /// For example, one could initialize a key with the date and time at which the application was
  /// most recently launched, and access this date from anywhere using the ``Shared`` property
  /// wrapper:
  ///
  /// ```swift
  /// @Shared(.inMemory("appLaunchedAt")) var appLaunchedAt = Date()
  /// ```
  ///
  /// - Parameter key: A string key identifying a value to share in memory.
  /// - Returns: An in-memory persistence key.
  public static func inMemory<Value>(_ key: String) -> Self
  where Self == InMemoryKey<Value> {
    InMemoryKey(key)
  }
}

/// A type defining an in-memory persistence strategy
///
/// See ``PersistenceReaderKey/inMemory(_:)`` to create values of this type.
public struct InMemoryKey<Value: Sendable>: PersistenceKey, Sendable {
  private let key: String
  private let store: InMemoryStorage
  fileprivate init(_ key: String) {
    @Dependency(\.defaultInMemoryStorage) var defaultInMemoryStorage
    self.key = key
    self.store = defaultInMemoryStorage
  }
  public typealias ID = InMemoryKeyID
  public var id: ID {
    InMemoryKeyID(key: self.key, store: self.store)
  }
  public func load(initialValue: Value?) -> Value? {
    store.storage.withValue { $0[key] as? Value } ?? initialValue
  }
  public func save(_ value: Value) {
    store.storage.withValue { $0[key] = value }
  }
}

public struct InMemoryStorage: Hashable, Sendable {
  let id = UUID()
  fileprivate let storage = LockIsolated<[AnyHashable: Any]>([:])
  public init() {}
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public struct InMemoryKeyID: Hashable, Sendable {
  let key: String
  let store: InMemoryStorage
}

private enum DefaultInMemoryStorageKey: DependencyKey {
  static var liveValue: InMemoryStorage { InMemoryStorage() }
  static var testValue: InMemoryStorage { InMemoryStorage() }
}

extension DependencyValues {
  public var defaultInMemoryStorage: InMemoryStorage {
    get { self[DefaultInMemoryStorageKey.self] }
    set { self[DefaultInMemoryStorageKey.self] = newValue }
  }
}
