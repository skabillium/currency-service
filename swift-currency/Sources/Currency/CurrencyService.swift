import Foundation
import SQLKit

struct CurrencyService {
    let db: any SQLDatabase

    func findOne(code: String) async -> Result<Currency?, Error> {
        await Task {
            try await db.select()
                .column("*")
                .from("currency")
                .where("code", .equal, code)
                .first(decoding: Currency.self)
        }.result
    }

    func setUpdated(code: String, to date: Date) async -> Result<Void, Error> {
        await Task {
            try await db.update("currency")
                .set("updated_at", to: date)
                .where("code", .equal, code)
                .run()
        }.result
    }
}
