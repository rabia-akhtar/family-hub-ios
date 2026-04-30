import Foundation

enum WeatherError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid weather URL."
        case .requestFailed(let c): return "Weather request failed with status \(c)."
        case .decodingFailed:       return "Failed to decode weather response."
        }
    }
}

final class WeatherService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch Weather

    func fetchWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        var components = URLComponents(string: AppConfig.openMeteoBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "latitude",        value: String(latitude)),
            URLQueryItem(name: "longitude",       value: String(longitude)),
            URLQueryItem(name: "current",         value: "temperature_2m,apparent_temperature,wind_speed_10m,uv_index,weather_code"),
            URLQueryItem(name: "hourly",          value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily",           value: "temperature_2m_max,temperature_2m_min,weather_code,sunrise,sunset"),
            URLQueryItem(name: "temperature_unit",value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "timezone",        value: "auto"),
            URLQueryItem(name: "forecast_days",   value: "7")
        ]

        guard let url = components?.url else { throw WeatherError.invalidURL }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WeatherError.requestFailed(http.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WeatherError.decodingFailed
        }

        return try parseWeatherJSON(json)
    }

    // MARK: - Parse

    private func parseWeatherJSON(_ json: [String: Any]) throws -> WeatherData {
        // Current
        guard let current = json["current"] as? [String: Any] else {
            throw WeatherError.decodingFailed
        }
        let temperature = current["temperature_2m"] as? Double ?? 0
        let feelsLike   = current["apparent_temperature"] as? Double ?? 0
        let windSpeed   = current["wind_speed_10m"] as? Double ?? 0
        let uvIndex     = current["uv_index"] as? Double ?? 0
        let weatherCode = current["weather_code"] as? Int ?? 0

        // Hourly – next 24 entries only
        var hourlyForecasts: [HourlyForecast] = []
        if let hourly = json["hourly"] as? [String: Any],
           let times = hourly["time"] as? [String],
           let temps = hourly["temperature_2m"] as? [Double],
           let codes = hourly["weather_code"] as? [Int] {

            let now = Date()
            let isoFormatter = ISO8601DateFormatter()
            var count = 0
            for i in 0..<min(times.count, 48) {
                guard let t = isoFormatter.date(from: times[i]), t >= now else { continue }
                guard count < 24 else { break }
                let code = i < codes.count ? codes[i] : 0
                hourlyForecasts.append(HourlyForecast(
                    time: t,
                    temperature: i < temps.count ? temps[i] : 0,
                    weatherCode: code,
                    systemImageName: weatherSystemImage(code: code)
                ))
                count += 1
            }
        }

        // Daily
        var dailyForecasts: [DailyForecast] = []
        var firstSunrise: Date?
        var firstSunset: Date?

        if let daily = json["daily"] as? [String: Any],
           let dates    = daily["time"] as? [String],
           let highs    = daily["temperature_2m_max"] as? [Double],
           let lows     = daily["temperature_2m_min"] as? [Double],
           let codes    = daily["weather_code"] as? [Int],
           let sunrises = daily["sunrise"] as? [String],
           let sunsets  = daily["sunset"] as? [String] {

            let isoFormatter = ISO8601DateFormatter()

            for i in 0..<dates.count {
                guard let date = Date.from(dateKey: dates[i]) else { continue }
                let code = i < codes.count ? codes[i] : 0
                let sunrise = i < sunrises.count ? isoFormatter.date(from: sunrises[i]) : nil
                let sunset  = i < sunsets.count  ? isoFormatter.date(from: sunsets[i])  : nil

                if i == 0 {
                    firstSunrise = sunrise
                    firstSunset  = sunset
                }

                dailyForecasts.append(DailyForecast(
                    date: date,
                    high: i < highs.count ? highs[i] : 0,
                    low:  i < lows.count  ? lows[i]  : 0,
                    weatherCode: code,
                    systemImageName: weatherSystemImage(code: code),
                    sunrise: sunrise,
                    sunset: sunset
                ))
            }
        }

        return WeatherData(
            temperature: temperature,
            feelsLike: feelsLike,
            windSpeed: windSpeed,
            uvIndex: uvIndex,
            weatherCode: weatherCode,
            description: weatherDescription(code: weatherCode),
            systemImageName: weatherSystemImage(code: weatherCode),
            hourlyForecasts: hourlyForecasts,
            dailyForecasts: dailyForecasts,
            sunrise: firstSunrise,
            sunset: firstSunset
        )
    }

    // MARK: - WMO Code Helpers

    func weatherDescription(code: Int) -> String {
        switch code {
        case 0:             return "Clear Sky"
        case 1:             return "Mainly Clear"
        case 2:             return "Partly Cloudy"
        case 3:             return "Overcast"
        case 45:            return "Foggy"
        case 48:            return "Icy Fog"
        case 51:            return "Light Drizzle"
        case 53:            return "Moderate Drizzle"
        case 55:            return "Dense Drizzle"
        case 61:            return "Slight Rain"
        case 63:            return "Moderate Rain"
        case 65:            return "Heavy Rain"
        case 71:            return "Slight Snow"
        case 73:            return "Moderate Snow"
        case 75:            return "Heavy Snow"
        case 77:            return "Snow Grains"
        case 80:            return "Slight Showers"
        case 81:            return "Moderate Showers"
        case 82:            return "Violent Showers"
        case 85, 86:        return "Snow Showers"
        case 95:            return "Thunderstorm"
        case 96, 99:        return "Thunderstorm with Hail"
        default:            return "Unknown"
        }
    }

    func weatherSystemImage(code: Int) -> String {
        switch code {
        case 0:             return "sun.max.fill"
        case 1, 2:          return "cloud.sun.fill"
        case 3:             return "cloud.fill"
        case 45, 48:        return "cloud.fog.fill"
        case 51, 53, 55, 61, 63, 65: return "cloud.drizzle.fill"
        case 71, 73, 75:    return "cloud.snow.fill"
        case 77:            return "cloud.snow.fill"
        case 80, 81, 82:    return "cloud.rain.fill"
        case 85, 86:        return "cloud.snow.fill"
        case 95, 96, 99:    return "cloud.bolt.rain.fill"
        default:            return "cloud.fill"
        }
    }
}
