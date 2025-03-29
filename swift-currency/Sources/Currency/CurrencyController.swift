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

    func convert(req: Request, context: BasicRequestContext) async throws -> ConvertResponse {
        let convertRequest = try await req.decode(as: ConvertRequest.self, context: context)
        try convertRequest.validate()

        let from = convertRequest.from
        let to = convertRequest.to
        let amount = convertRequest.amount

        let fromCurrency = await currencyService.findOne(code: from)
        guard case let .success(fromCurrency) = fromCurrency else {
            throw AppError(code: .internalServerError)
        }

        guard let fromCurrency = fromCurrency else {
            throw AppError(code: .unsupportedCurrency)
        }

        let toCurrency = await currencyService.findOne(code: to)
        guard case let .success(toCurrency) = toCurrency else {
            throw AppError(code: .internalServerError)
        }

        guard let toCurrency = toCurrency else {
            throw AppError(code: .unsupportedCurrency)
        }

        let exchangeRate = await exchangeRateService.getRate(from: from, to: to)
        guard case let .success(exchangeRate) = exchangeRate else {
            throw AppError(code: .internalServerError)
        }

        guard let exchangeRate = exchangeRate else {
            throw AppError(code: .exchangeRateNotFound)
        }

        return ConvertResponse(
            from: GetCurrencyResponse(
                code: fromCurrency.code,
                decimalDigits: fromCurrency.decimalDigits,
                updatedAt: fromCurrency.updatedAt
            ),
            to: GetCurrencyResponse(
                code: toCurrency.code,
                decimalDigits: toCurrency.decimalDigits,
                updatedAt: toCurrency.updatedAt
            ),
            amount: amount,
            convertedAmount: convertAmount(
                amount: amount, rate: exchangeRate.rate, currencyFrom: fromCurrency,
                currencyTo: toCurrency),
            exchangeRate: exchangeRate.rate,
            updatedAt: exchangeRate.updatedAt
        )
    }
}

struct GetCurrencyResponse: ResponseCodable {
    let code: String
    let decimalDigits: Int
    let updatedAt: Date
}

struct ConvertRequest: Decodable {
    let from: String
    let to: String
    let amount: Decimal

    func validate() throws {
        guard from != "" else {
            throw AppError(code: .currencyRequired, message: "'from' currency is required")
        }

        guard to != "" else {
            throw AppError(code: .currencyRequired, message: "'to' currency is required")
        }

        guard from != to else {
            throw AppError(code: .cannotConvertToSameCurrency)
        }

        guard amount > 0 else {
            throw AppError(code: .invalidAmount, message: "Amount must be greater than 0")
        }
    }
}

struct ConvertResponse: ResponseCodable {
    let from: GetCurrencyResponse
    let to: GetCurrencyResponse
    let amount: Decimal
    let convertedAmount: Decimal
    let exchangeRate: Double
    let updatedAt: Date
}
