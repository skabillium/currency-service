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

        let exchangeRateResult = await exchangeRateService.findOne(from: from, to: to)
        guard case let .success(exchangeRate) = exchangeRateResult else {
            throw AppError(code: .internalServerError, message: "Failed to fetch exchange rate")
        }

        guard let exchangeRate = exchangeRate else {
            throw AppError(code: .exchangeRateNotFound)
        }

        let now = Date()
        if isWithinPastInterval(exchangeRate.updatedAt, seconds: 3600) {
            logger.info("Exchange rate for \(from) to \(to) is up to date")
            return GetExchangeRateResponse(
                from: exchangeRate.from,
                to: exchangeRate.to,
                rate: exchangeRate.rate,
                updatedAt: exchangeRate.updatedAt
            )
        }

        logger.info(
            "Exchange rates for \(from) to \(to) is outdated, fetching from OpenExchangeRates")
        let openExchangeRatesResponse = await openExchangeRatesClient.getLatest(from: from)
        guard case let .success(openExchangeRatesResponse) = openExchangeRatesResponse else {
            throw AppError(code: .internalServerError, message: "Failed to get exchange rate")
        }

        let rate = openExchangeRatesResponse.rates[to]

        guard let rate = rate else {
            // If not found in the response, return the one from the database
            return GetExchangeRateResponse(
                from: exchangeRate.from,
                to: exchangeRate.to,
                rate: exchangeRate.rate,
                updatedAt: exchangeRate.updatedAt
            )
        }

        Task {
            _ = await exchangeRateService.batchUpdateRates(
                from: from, rates: openExchangeRatesResponse.rates, updatedAt: now)
            _ = await currencyService.setUpdated(code: from, to: now)
        }

        return GetExchangeRateResponse(
            from: from,
            to: to,
            rate: rate,
            updatedAt: now
        )
    }

    func getExchangeRates(req: Request, context: BasicRequestContext) async throws
        -> GetExchangeRatesResponse
    {
        let from = context.parameters.get("from")!

        let getCurrencyResult = await currencyService.findOne(code: from)
        guard case let .success(currency) = getCurrencyResult else {
            throw AppError(code: .internalServerError)
        }

        guard let currency = currency else {
            throw AppError(code: .unsupportedCurrency)
        }

        if isWithinPastInterval(currency.updatedAt, seconds: 3600) {
            logger.info("Exchange rates for currency \(from) are up to date")
            let exchangeRates = await exchangeRateService.findAll(from: from)
            guard case let .success(exchangeRates) = exchangeRates else {
                throw AppError(code: .internalServerError, message: "Failed to get exchange rates")
            }

            return GetExchangeRatesResponse(
                currency: from,
                updatedAt: currency.updatedAt,
                rates: Dictionary(
                    uniqueKeysWithValues: exchangeRates.map { ($0.to, $0.rate) })
            )
        }

        logger.info(
            "Exchange rates for currency \(from) are outdated, fetching from OpenExchangeRates")
        let openExchangeRatesResponse = await openExchangeRatesClient.getLatest(from: from)
        guard case let .success(openExchangeRatesResponse) = openExchangeRatesResponse else {
            throw AppError(code: .internalServerError, message: "Failed to get exchange rates")
        }

        Task {
            let now = Date()
            _ = await exchangeRateService.batchUpdateRates(
                from: from, rates: openExchangeRatesResponse.rates, updatedAt: now)
            _ = await currencyService.setUpdated(code: from, to: now)
        }

        return GetExchangeRatesResponse(
            currency: from,
            updatedAt: currency.updatedAt,
            rates: openExchangeRatesResponse.rates
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
