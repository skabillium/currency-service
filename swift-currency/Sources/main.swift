import Foundation
import Hummingbird
import MySQLKit
import NIO
import SQLKit

let logger = Logger(label: "main")

let mysql = getDatabaseConnection()
logger.info("Connected to MySQL database")

let router = Router()

let openExchangeRatesClient = OpenExchangeRatesClient(
    appID: mustGetEnv("OPEN_EXCHANGE_RATES_APP_ID"))
let exchangeRateService = ExchangeRatesService(db: mysql.sql())
let currencyService = CurrencyService(db: mysql.sql())

let currencyController = CurrencyController(db: mysql.sql(), currencyService: currencyService)
let exchangeRateController = ExchangeRateController(
    db: mysql.sql(),
    openExchangeRatesClient: openExchangeRatesClient,
    exchangeRateService: exchangeRateService,
    currencyService: currencyService
)

router.get("currencies/:currency", use: currencyController.getCurrency)
router.get("exchange-rates/:from", use: exchangeRateController.getExchangeRates)
router.get("exchange-rates/:from/:to", use: exchangeRateController.getExchangeRate)

let app = Application(
    router: router,
    configuration: .init(address: .hostname("127.0.0.1", port: Int(mustGetEnv("PORT")) ?? 8080))
)
try await app.runService()
