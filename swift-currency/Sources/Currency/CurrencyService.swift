import Foundation
import SQLKit

struct CurrencyService {
    let db: any SQLDatabase

    func findOne(code: String) async -> Result<Currency?, Error> {
        do {
            return .success(
                try await db.select()
                    .column("*")
                    .from("currency")
                    .where("code", .equal, code)
                    .first(decoding: Currency.self))
        } catch {
            return .failure(error)
        }
    }

    func setUpdated(code: String, to date: Date) async -> Result<Void, Error> {
        do {
            return .success(
                try await db.update("currency")
                    .set("updated_at", to: date)
                    .where("code", .equal, code)
                    .run())
        } catch {
            return .failure(error)
        }
    }
}
