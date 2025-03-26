struct ErrorResponse: ResponseCodable {
    let code: String
    let message: String
    let details: String?
    let type: String

    init(code: AppErrorCode, message: String, type: AppErrorType, details: String?) {
        self.code = code.rawValue
        self.message = message
        self.details = details
        self.type = type.rawValue
    }

    init(code: String, type: String, message: String, details: String?) {
        self.code = code
        self.message = message
        self.details = details
        self.type = type
    }
}
