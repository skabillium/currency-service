import Foundation
import Logging
import SQLKit

struct ExchangeRateDao {
    let logger = Logger(label: String(describing: Self.self))
    let db: any SQLDatabase

    func findOne(from: String, to: String) async -> Result<ExchangeRate?, Error> {
        do {
            return .success(
                try await db.select()
                    .column("*")
                    .from("exchange_rate")
                    .where("currency_from", .equal, from)
                    .where("currency_to", .equal, to)
                    .first(decoding: ExchangeRate.self))
        } catch {
            return .failure(error)
        }
    }

    func findAll(from: String) async -> Result<[ExchangeRate], Error> {
        do {
            return .success(
                try await db.select()
                    .column("*")
                    .from("exchange_rate")
                    .where("currency_from", .equal, from)
                    .all(decoding: ExchangeRate.self))
        } catch {
            return .failure(error)
        }
    }
}
