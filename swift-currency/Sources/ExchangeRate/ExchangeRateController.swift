import Foundation
import Hummingbird
import Logging
import SQLKit

struct ExchangeRateController {
    let logger = Logger(label: String(describing: Self.self))
    let db: any SQLDatabase
    let openExchangeRatesClient: OpenExchangeRatesClient
    let exchangeRateService: ExchangeRatesService
    let currencyService: CurrencyService

    func getExchangeRate(req: Request, context: BasicRequestContext) async throws
        -> GetExchangeRateResponse
    {
        let from = context.parameters.get("from")!
        let to = context.parameters.get("to")!

        let exchangeRate = await exchangeRateService.getRate(from: from, to: to)
        guard case let .success(exchangeRate) = exchangeRate else {
            if case let .failure(error) = exchangeRate, let appError = error as? AppError {
                throw appError
            }
            throw AppError(code: .internalServerError)
        }

        guard let exchangeRate = exchangeRate else {
            throw AppError(code: .exchangeRateNotFound)
        }

        return GetExchangeRateResponse(
            from: exchangeRate.from,
            to: exchangeRate.to,
            rate: exchangeRate.rate,
            updatedAt: exchangeRate.updatedAt
        )
    }

    func getExchangeRates(req: Request, context: BasicRequestContext) async throws
        -> GetExchangeRatesResponse
    {
        let from = context.parameters.get("from")!
        let exchageRates = await exchangeRateService.getRates(from: from)
        guard case let .success(exchageRates) = exchageRates else {
            if case let .failure(error) = exchageRates, let appError = error as? AppError {
                throw appError
            }
            throw AppError(code: .internalServerError)
        }

        let rates = exchageRates.reduce(into: [String: Decimal]()) { result, exchangeRate in
            result[exchangeRate.to] = exchangeRate.rate
        }

        return GetExchangeRatesResponse(
            currency: from,
            updatedAt: exchageRates.first?.updatedAt ?? Date(),
            rates: rates
        )
    }
}

struct GetExchangeRatesResponse: ResponseCodable {
    let currency: String
    let updatedAt: Date
    let rates: [String: Decimal]
}

struct GetExchangeRateResponse: ResponseCodable {
    let from: String
    let to: String
    let rate: Decimal
    let updatedAt: Date
}
