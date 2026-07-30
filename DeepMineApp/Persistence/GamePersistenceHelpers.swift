import Foundation

func encodeSet<Element: Codable>(_ values: Set<Element>) throws -> Data {
    try JSONEncoder().encode(Array(values))
}

func decodeSet<Element: Codable & Hashable>(_ data: Data) throws -> Set<Element> {
    Set(try JSONDecoder().decode([Element].self, from: data))
}

func value<Value: RawRepresentable>(
    _ type: Value.Type,
    rawValue: String,
    field: String
) throws -> Value where Value.RawValue == String {
    guard let result = Value(rawValue: rawValue) else {
        throw GamePersistenceError.invalidStoredValue(field: field, value: rawValue)
    }
    return result
}

extension GamePersistenceError {
    var isUnsupportedSchema: Bool {
        if case .unsupportedSchemaVersion = self { return true }
        return false
    }
}
