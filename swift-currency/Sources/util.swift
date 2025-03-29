import Foundation

/// Check if a date is within the past interval
func isWithinPastInterval(_ date: Date, seconds: TimeInterval) -> Bool {
    let timeDiff = date.timeIntervalSinceNow
    return timeDiff > -seconds && timeDiff < 0
}

/// Get an environment variable or crash if it's not set
func mustGetEnv(_ key: String) -> String {
    guard let value = ProcessInfo.processInfo.environment[key] else {
        fatalError("Environment variable \(key) is not set")
    }
    return value
}

/// Convert an amount from one currency to another
func convertAmount(amount: Decimal, rate: Double, currencyFrom: Currency, currencyTo: Currency)
    -> Decimal
{
    let amountDouble = Double(truncating: amount as NSNumber)
    let convertedAmount = amountDouble * rate
    let decimalDigits = currencyTo.decimalDigits
    var result = Decimal(convertedAmount)
    var roundedResult = result
    NSDecimalRound(&roundedResult, &result, decimalDigits, .plain)
    return roundedResult
}
