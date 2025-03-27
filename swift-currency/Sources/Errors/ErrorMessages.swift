import Hummingbird

enum AppErrorCode: String {
    case unsupportedCurrency = "unsupported_currency"
    case exchangeRateNotFound = "exchange_rate_not_found"
    case internalServerError = "internal_server_error"
}

enum AppErrorType: String {
    case invalidRequest = "invalid_request_error"
    case server = "api_error"
}

let ErrorMessages: [AppErrorCode: (HTTPResponse.Status, AppErrorType, String)] = [
    .unsupportedCurrency: (.badRequest, .invalidRequest, "Currency not supported"),
    .exchangeRateNotFound: (.notFound, .invalidRequest, "Exchange rate not found"),
    .internalServerError: (.internalServerError, .server, "Unexpected error"),
]
