import Foundation
import Logging
import SQLKit

struct ExchangeRatesService {
    let logger = Logger(label: String(describing: Self.self))
    let db: any SQLDatabase
    let dao: ExchangeRateDao

    func getRate(from: String, to: String) async -> Result<ExchangeRate?, Error> {
        let exchangeRate = await dao.findOne(from: from, to: to)
        guard case let .success(exchangeRate) = exchangeRate else {
            return .failure(
                AppError(code: .internalServerError, message: "Failed to fetch exchange rate"))
        }

        guard let exchangeRate = exchangeRate else {
            return .success(nil)
        }

        let now = Date()
        if isWithinPastInterval(exchangeRate.updatedAt, seconds: 3600) {
            logger.info("Exchange rate for \(from) to \(to) is up to date")
            logger.info("Exchange rate for \(from) to \(to) is \(exchangeRate.rate)")
            return .success(exchangeRate)
        }

        logger.info(
            "Exchange rates for \(from) to \(to) is outdated, fetching from OpenExchangeRates")
        let openExchangeRatesResponse = await openExchangeRatesClient.getLatest(from: from)
        guard case let .success(openExchangeRatesResponse) = openExchangeRatesResponse else {
            return .failure(
                AppError(code: .internalServerError, message: "Failed to get exchange rate"))
        }

        guard let rate = openExchangeRatesResponse.rates[to] else {
            logger.info("Exchange rate for \(from) to \(to) not found in response, using database")
            return .success(exchangeRate)
        }

        Task {
            _ = await batchUpdateRates(
                from: from, rates: openExchangeRatesResponse.rates, updatedAt: now)
            _ = await currencyService.setUpdated(code: from, to: now)
        }

        return .success(
            ExchangeRate(
                from: from, to: to, rate: rate, updatedAt: now))
    }

    func getRates(from: String) async -> Result<[ExchangeRate], Error> {
        let currency = await currencyService.findOne(code: from)
        guard case let .success(currency) = currency else {
            return .failure(AppError(code: .internalServerError))
        }

        guard let currency = currency else {
            return .failure(AppError(code: .unsupportedCurrency))
        }

        if isWithinPastInterval(currency.updatedAt, seconds: 3600) {
            logger.info("Exchange rates for currency \(from) are up to date")
            let exchangeRates = await dao.findAll(from: from)
            guard case let .success(exchangeRates) = exchangeRates else {
                return .failure(
                    AppError(code: .internalServerError, message: "Failed to get exchange rates"))
            }

            return .success(exchangeRates)
        }

        logger.info(
            "Exchange rates for currency \(from) are outdated, fetching from OpenExchangeRates")
        let openExchangeRatesResponse = await openExchangeRatesClient.getLatest(from: from)
        guard case let .success(openExchangeRatesResponse) = openExchangeRatesResponse else {
            return .failure(
                AppError(code: .internalServerError, message: "Failed to get exchange rates"))
        }

        let now = Date()
        Task {
            _ = await batchUpdateRates(
                from: from, rates: openExchangeRatesResponse.rates, updatedAt: now)
            _ = await currencyService.setUpdated(code: from, to: now)
        }

        return .success(
            openExchangeRatesResponse.rates.map { to, rate in
                ExchangeRate(from: from, to: to, rate: rate, updatedAt: now)
            })
    }

    func batchUpdateRates(from: String, rates: [String: Double], updatedAt: Date)
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
