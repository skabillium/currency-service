import Foundation

struct OpenExchangeRatesClient {
    let appID: String
    let baseURL = "https://openexchangerates.org/api"

    func getLatest(from: String) async -> Result<OpenExchangeRatesResponse, Error> {
        do {
            let url = URL(string: "\(baseURL)/latest.json?app_id=\(appID)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenExchangeRatesResponse.self, from: data)

            return .success(response)
        } catch {
            return .failure(error)
        }
    }
}

struct OpenExchangeRatesResponse: Codable {
    let rates: [String: Decimal]
}
