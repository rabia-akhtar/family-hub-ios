import Foundation

@MainActor
final class WeatherViewModel: ObservableObject {

    @Published var weatherData: WeatherData?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service = WeatherService()

    var latitude: Double {
        UserDefaults.standard.double(forKey: AppConfig.UserDefaultsKey.locationLatitude).nonZeroOr(AppConfig.defaultLatitude)
    }

    var longitude: Double {
        UserDefaults.standard.double(forKey: AppConfig.UserDefaultsKey.locationLongitude).nonZeroOr(AppConfig.defaultLongitude)
    }

    init() {
        Task { await fetchWeather() }
    }

    // MARK: - Fetch

    func fetchWeather() async {
        isLoading = true
        errorMessage = nil
        do {
            weatherData = try await service.fetchWeather(latitude: latitude, longitude: longitude)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setLocation(latitude: Double, longitude: Double) async {
        UserDefaults.standard.set(latitude,  forKey: AppConfig.UserDefaultsKey.locationLatitude)
        UserDefaults.standard.set(longitude, forKey: AppConfig.UserDefaultsKey.locationLongitude)
        await fetchWeather()
    }
}

private extension Double {
    func nonZeroOr(_ fallback: Double) -> Double {
        self == 0.0 ? fallback : self
    }
}
