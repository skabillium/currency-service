import MySQLKit

/// Get a connection to the MySQL database
func getDatabaseConnection() -> MySQLDatabase {
    let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    var tlsConfig = TLSConfiguration.makeClientConfiguration()
    tlsConfig.certificateVerification = .none
    tlsConfig.trustRoots = .default
    tlsConfig.additionalTrustRoots = []

    // Create a MySQL database configuration
    let configuration = MySQLConfiguration(
        hostname: mustGetEnv("MYSQL_HOST"),
        port: Int(mustGetEnv("MYSQL_PORT")) ?? 3306,
        username: mustGetEnv("MYSQL_USERNAME"),
        password: mustGetEnv("MYSQL_PASSWORD"),
        database: mustGetEnv("MYSQL_DATABASE"),
        tlsConfiguration: tlsConfig
    )

    // Create a connection pool
    let mysqlSource = MySQLConnectionSource(configuration: configuration)
    let pool =
        EventLoopGroupConnectionPool(
            source: mysqlSource,
            maxConnectionsPerEventLoop: 1,
            on: eventLoopGroup
        )

    return pool.database(logger: Logger(label: "database"))
}
