import Foundation
import Hummingbird

struct AppError: Hummingbird.HTTPResponseError {
    let code: AppErrorCode
    let type: AppErrorType
    let message: String
    let details: String?
    var status: HTTPResponse.Status

    init(code: AppErrorCode, message: String? = nil, details: String? = nil) {
        let (status, type, defaultMessage) = ErrorMessages[code]!
        self.code = code
        self.message = message ?? defaultMessage
        self.status = status
        self.type = type
        self.details = details
    }

    init(message: String) {
        self.code = .unsupportedCurrency
        self.message = message
        self.status = .badRequest
        self.type = .invalidRequest
        self.details = nil
    }

    public func response(from request: Request, context: some RequestContext) -> Response {
        let responseBody: ErrorResponse = ErrorResponse(
            code: self.code, message: self.message, type: self.type, details: self.details)

        var response = try! context.responseEncoder.encode(
            responseBody, from: request, context: context
        )
        response.status = self.status
        return response
    }
}
