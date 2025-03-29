import Hummingbird

enum AppErrorCode: String {
    // Validation errors
    case unsupportedCurrency = "unsupported_currency"
    case currencyRequired = "currency_required"
    case exchangeRateNotFound = "exchange_rate_not_found"
    case cannotConvertToSameCurrency = "cannot_convert_to_same_currency"
    case invalidAmount = "invalid_amount"

    // Server errors
    case internalServerError = "internal_server_error"
}

enum AppErrorType: String {
    case invalidRequest = "invalid_request_error"
    case server = "api_error"
}

let ErrorMessages: [AppErrorCode: (HTTPResponse.Status, AppErrorType, String)] = [
    .unsupportedCurrency: (.badRequest, .invalidRequest, "Currency not supported"),
    .exchangeRateNotFound: (.notFound, .invalidRequest, "Exchange rate not found"),
    .cannotConvertToSameCurrency: (
        .badRequest, .invalidRequest, "Cannot convert currency to itself"
    ),
    .invalidAmount: (.badRequest, .invalidRequest, "Invalid amount"),
    .currencyRequired: (.badRequest, .invalidRequest, "Currency is required"),
    .internalServerError: (.internalServerError, .server, "Unexpected error"),
]
