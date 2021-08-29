import Foundation
import XCTest

// SimpleCache.swift
protocol SimpleReadableCache {
    associatedtype CacheableItem
    func fetch(key: String) -> CacheableItem?
}

protocol SimpleWritableCache {
    func cache(item: Codable, withKey key: String)
}

typealias SimpleCache = SimpleReadableCache & SimpleWritableCache


// Person.swift

struct Person: Codable, Equatable {
    var name: String
}

// SimpleCacheUserDefaultsWrapper.swift

protocol Storage {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    func synchronize() -> Bool
}

extension UserDefaults: Storage {}

final class SimpleCacheUserDefaultsWrapper<CacheableItem: Codable>: SimpleCache {
    var storage: Storage

    init(storage: Storage = UserDefaults.standard) {
        self.storage = storage
    }

    func fetch(key: String) -> CacheableItem? {
        guard let data = storage.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CacheableItem.self, from: data)
    }

    func cache(item: Codable, withKey key: String) {
        if let concrete = item as? CacheableItem {
            let data = try? JSONEncoder().encode(concrete)
            storage.set(data, forKey: key)
            _ = storage.synchronize()
        }
    }
}

// SimpleCacheUserDefaultsWrapperTests.swift

class SimpleCacheUserDefaultsWrapperTests: XCTestCase {

    func test_fetch_with_non_existent_key() {
        let results = makeSut(storage: FakeUserDefaults()).fetch(key: "A key")

        XCTAssertNil(results)
    }

    func test_fetch_exsiting_key() {
        let fakeUserDefaults = FakeUserDefaults()
        let person = Person(name: "Luke")
        fakeUserDefaults.stub(testObject: person, withKey: "person")

        makeSut(storage: fakeUserDefaults).cache(item: person, withKey: "person")
        XCTAssertEqual(fakeUserDefaults.storage.keys.count, 1)
    }
    
    func test_cache_with_key() {
        let fakeUserDefaults = FakeUserDefaults()
        makeSut(storage: fakeUserDefaults).cache(item: Person(name: "Luke"), withKey: "new person")

        XCTAssertEqual(fakeUserDefaults.storage.keys.count, 1)
    }

    func test_cache_overwrites_exsiting_key() {
        let fakeUserDefaults = FakeUserDefaults()
        let person = Person(name: "Luke")
        fakeUserDefaults.stub(testObject: person, withKey: "person")

        makeSut(storage: fakeUserDefaults).cache(item: person, withKey: "person")
        XCTAssertEqual(fakeUserDefaults.storage.keys.count, 1)
    }

    // MARK: Helpers
    final class FakeUserDefaults: Storage {

        private(set) var storage: [String: Any] = [:]

        func stub(testObject: Person, withKey key: String) {
            storage[key] = testObject
        }

        func data(forKey defaultName: String) -> Data? {
            storage[defaultName] as? Data
        }

        func set(_ value: Any?, forKey defaultName: String) {
            storage[defaultName] = data
        }

        func removeObject(forKey defaultName: String) {
            storage[defaultName] = nil
        }

        func synchronize() -> Bool {
            return true
        }
    }

    func makeSut(storage: FakeUserDefaults) -> SimpleCacheUserDefaultsWrapper<Person> {
        return SimpleCacheUserDefaultsWrapper<Person>(storage: storage)
    }

}
