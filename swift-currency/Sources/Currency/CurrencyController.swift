import Foundation
import Hummingbird
import SQLKit

struct CurrencyController {
    let db: any SQLDatabase
    let currencyService: CurrencyService
    let exchangeRateService: ExchangeRatesService

    func getCurrency(req: Request, context: BasicRequestContext) async throws -> GetCurrencyResponse
    {
        let code = context.parameters.get("currency")!

        let result = await currencyService.findOne(code: code)
        guard case let .success(currency) = result else {
            throw AppError(code: .internalServerError)
        }

        guard let currency = currency else {
            throw AppError(code: .unsupportedCurrency)
        }

        return GetCurrencyResponse(
            code: currency.code,
            decimalDigits: currency.decimalDigits,
            updatedAt: currency.updatedAt
        )
    }
}

struct GetCurrencyResponse: ResponseCodable {
    let code: String
    let decimalDigits: UInt8
    let updatedAt: Date
}
