import Foundation

struct Currency: Codable, Identifiable {
    // Using code as the primary key/identifier
    var id: String { code }

    let code: String
    let decimalDigits: Int
    let createdAt: Date
    let updatedAt: Date

    // CodingKeys to match the database column names
    enum CodingKeys: String, CodingKey {
        case code
        case decimalDigits = "decimal_digits"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
