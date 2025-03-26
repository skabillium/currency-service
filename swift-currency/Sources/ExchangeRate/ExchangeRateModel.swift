import Foundation

struct ExchangeRate: Codable {
    let from: String
    let to: String
    let rate: Decimal
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case from = "currency_from"
        case to = "currency_to"
        case rate
        case updatedAt = "updated_at"
    }
}
