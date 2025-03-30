import Foundation
import Logging
import SQLKit

struct ExchangeRateDao {
    let logger = Logger(label: String(describing: Self.self))
    let db: any SQLDatabase

    func findOne(from: String, to: String) async -> Result<ExchangeRate?, Error> {
        await Task {
            try await db.select()
                .column("*")
                .from("exchange_rate")
                .where("currency_from", .equal, from)
                .where("currency_to", .equal, to)
                .first(decoding: ExchangeRate.self)
        }.result
    }

    func findAll(from: String) async -> Result<[ExchangeRate], Error> {
        await Task {
            try await db.select()
                .column("*")
                .from("exchange_rate")
                .where("currency_from", .equal, from)
                .all(decoding: ExchangeRate.self)
        }.result
    }
}
