import SwiftUI

struct WeatherView: View {

    @ObservedObject var weatherVM: WeatherViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if let weather = weatherVM.weatherData {
                    LazyVStack(spacing: 20) {
                        currentConditionsCard(weather: weather)
                        statsRow(weather: weather)
                        hourlyForecastCard(weather: weather)
                        dailyForecastCard(weather: weather)
                        if let sunrise = weather.sunrise, let sunset = weather.sunset {
                            sunCard(sunrise: sunrise, sunset: sunset)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                } else if weatherVM.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading weather...")
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondaryText)
                        Text("Weather unavailable")
                            .foregroundColor(.secondaryText)
                        Button("Retry") {
                            Task { await weatherVM.fetchWeather() }
                        }
                        .foregroundColor(.primaryPurple)
                    }
                    .padding(.top, 100)
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await weatherVM.fetchWeather()
            }
        }
    }

    // MARK: - Current Conditions Card

    private func currentConditionsCard(weather: WeatherData) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.weatherGradient)
                .shadow(color: Color.accentBlue.opacity(0.3), radius: 12, y: 6)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(weather.description)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(Int(weather.temperature))°")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                    Text("Feels like \(Int(weather.feelsLike))°")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: weather.systemImageName)
                    .font(.system(size: 72))
                    .foregroundColor(.white.opacity(0.9))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(24)
        }
    }

    // MARK: - Stats Row

    private func statsRow(weather: WeatherData) -> some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "sun.max.fill",
                iconColor: .accentOrange,
                label: "UV Index",
                value: uvLabel(weather.uvIndex)
            )
            StatCard(
                icon: "wind",
                iconColor: .accentBlue,
                label: "Wind",
                value: "\(Int(weather.windSpeed)) mph"
            )
            StatCard(
                icon: "thermometer",
                iconColor: .accentRed,
                label: "Feels Like",
                value: "\(Int(weather.feelsLike))°F"
            )
        }
    }

    private func uvLabel(_ uv: Double) -> String {
        switch Int(uv) {
        case 0...2:  return "\(Int(uv)) Low"
        case 3...5:  return "\(Int(uv)) Mod"
        case 6...7:  return "\(Int(uv)) High"
        case 8...10: return "\(Int(uv)) VHigh"
        default:     return "\(Int(uv)) Ex"
        }
    }

    // MARK: - Hourly Forecast

    private func hourlyForecastCard(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(weather.hourlyForecasts) { hour in
                        VStack(spacing: 8) {
                            Text(hour.time.toTimeString())
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                            Image(systemName: hour.systemImageName)
                                .font(.system(size: 20))
                                .foregroundColor(.accentBlue)
                                .symbolRenderingMode(.hierarchical)
                            Text("\(Int(hour.temperature))°")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primaryText)
                        }
                        .frame(width: 52)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Daily Forecast

    private func dailyForecastCard(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("7-Day Forecast", systemImage: "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryText)
                .padding(.bottom, 8)

            ForEach(weather.dailyForecasts) { day in
                HStack {
                    Text(day.date.isToday ? "Today" : day.date.toDisplayString())
                        .font(.system(size: 15))
                        .foregroundColor(.primaryText)
                        .frame(width: 100, alignment: .leading)

                    Image(systemName: day.systemImageName)
                        .font(.system(size: 18))
                        .foregroundColor(.accentBlue)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28)

                    Spacer()

                    Text("\(Int(day.low))°")
                        .font(.system(size: 15))
                        .foregroundColor(.secondaryText)
                        .frame(width: 36, alignment: .trailing)

                    // Temperature range bar
                    GeometryReader { geo in
                        let allHighs = weather.dailyForecasts.map { $0.high }
                        let allLows  = weather.dailyForecasts.map { $0.low  }
                        let minTemp  = allLows.min() ?? day.low
                        let maxTemp  = allHighs.max() ?? day.high
                        let range    = maxTemp - minTemp == 0 ? 1 : maxTemp - minTemp

                        let lowFrac  = CGFloat((day.low  - minTemp) / range)
                        let highFrac = CGFloat((day.high - minTemp) / range)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondaryText.opacity(0.2))
                                .frame(height: 6)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.accentBlue, .accentOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * (highFrac - lowFrac), height: 6)
                                .offset(x: geo.size.width * lowFrac)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(day.high))°")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primaryText)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.vertical, 8)

                if day.id != weather.dailyForecasts.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Sun Card

    private func sunCard(sunrise: Date, sunset: Date) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentOrange)
                    .symbolRenderingMode(.hierarchical)
                Text("Sunrise")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                Text(sunrise.toTimeString())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            Spacer()
            Divider().frame(height: 50)
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "sunset.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.1))
                    .symbolRenderingMode(.hierarchical)
                Text("Sunset")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                Text(sunset.toTimeString())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .symbolRenderingMode(.hierarchical)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.primaryText)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }
}
