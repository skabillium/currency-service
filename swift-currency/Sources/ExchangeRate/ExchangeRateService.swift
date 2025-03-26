import Foundation
import Logging
import SQLKit

struct ExchangeRatesService {
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

    func batchUpdateRates(from: String, rates: [String: Decimal], updatedAt: Date)
        async -> Result<Void, Error>
    {
        do {
            logger.info("Updating \(rates.count) exchange rates for currency \(from) in database")
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (to, rate) in rates {
                    group.addTask {
                        do {
                            try await db
                                .update("exchange_rate")
                                .set("rate", to: rate)
                                .set("updated_at", to: updatedAt)
                                .where("currency_from", .equal, from)
                                .where("currency_to", .equal, to)
                                .run()
                        } catch {
                            print("Failed to update \(from) → \(to): \(error)")
                        }
                    }
                }
                try await group.waitForAll()
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
