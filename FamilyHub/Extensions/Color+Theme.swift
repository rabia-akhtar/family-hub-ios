import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors
    static let primaryPurple = Color(red: 0.341, green: 0.361, blue: 0.482)
    static let accentBlue    = Color(red: 0.267, green: 0.533, blue: 0.898)
    static let accentGreen   = Color(red: 0.204, green: 0.780, blue: 0.349)
    static let accentOrange  = Color(red: 1.000, green: 0.584, blue: 0.000)
    static let accentRed     = Color(red: 1.000, green: 0.231, blue: 0.188)

    // MARK: - Semantic / Adaptive Colors
    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.13, blue: 0.18, alpha: 1)
            : UIColor.systemBackground
    })

    static let secondaryCardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.18, blue: 0.24, alpha: 1)
            : UIColor.secondarySystemBackground
    })

    static let appBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)
            : UIColor.systemGroupedBackground
    })

    static let primaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor.label
    })

    static let secondaryText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.65, green: 0.65, blue: 0.70, alpha: 1)
            : UIColor.secondaryLabel
    })

    static let divider = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.25, blue: 0.30, alpha: 1)
            : UIColor.separator
    })

    // MARK: - Category Colors
    static let choreColor      = Color(red: 0.529, green: 0.808, blue: 0.922)
    static let houseColor      = Color(red: 0.678, green: 0.847, blue: 0.902)
    static let catsColor       = Color(red: 1.000, green: 0.808, blue: 0.494)
    static let otherColor      = Color(red: 0.804, green: 0.804, blue: 0.804)

    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "chore":  return .choreColor
        case "house":  return .houseColor
        case "cats":   return .catsColor
        default:       return .otherColor
        }
    }

    // MARK: - Budget Category Colors
    static let budgetColors: [String: Color] = [
        "Groceries":     Color(red: 0.204, green: 0.780, blue: 0.349),
        "Dining":        Color(red: 1.000, green: 0.584, blue: 0.000),
        "Entertainment": Color(red: 0.529, green: 0.271, blue: 0.698),
        "Transport":     Color(red: 0.267, green: 0.533, blue: 0.898),
        "Health":        Color(red: 1.000, green: 0.231, blue: 0.188),
        "Shopping":      Color(red: 1.000, green: 0.176, blue: 0.333),
        "Utilities":     Color(red: 0.608, green: 0.349, blue: 0.714),
        "Other":         Color(red: 0.556, green: 0.556, blue: 0.576)
    ]

    static func budgetColor(for category: String) -> Color {
        return budgetColors[category] ?? .otherColor
    }

    // MARK: - Gradient Helpers
    static var homeGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPurple, primaryPurple.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var weatherGradient: LinearGradient {
        LinearGradient(
            colors: [accentBlue, Color(red: 0.529, green: 0.808, blue: 0.922)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
