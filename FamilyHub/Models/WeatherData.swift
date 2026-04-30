import Foundation

struct WeatherData {
    // MARK: - Current Conditions
    var temperature: Double
    var feelsLike: Double
    var windSpeed: Double
    var uvIndex: Double
    var weatherCode: Int
    var description: String
    var systemImageName: String

    // MARK: - Forecasts
    var hourlyForecasts: [HourlyForecast]
    var dailyForecasts: [DailyForecast]

    // MARK: - Sun
    var sunrise: Date?
    var sunset: Date?
}

struct HourlyForecast: Identifiable {
    var id: String { time.toISO8601() }
    var time: Date
    var temperature: Double
    var weatherCode: Int
    var systemImageName: String
}

struct DailyForecast: Identifiable {
    var id: String { date.toDateKey() }
    var date: Date
    var high: Double
    var low: Double
    var weatherCode: Int
    var systemImageName: String
    var sunrise: Date?
    var sunset: Date?
}
