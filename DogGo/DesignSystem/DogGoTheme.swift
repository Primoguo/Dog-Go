import SwiftUI

enum DogGoTheme {
    enum Colors {
        static let canvas = Color(red: 0.96, green: 0.91, blue: 0.80)
        static let ink = Color(red: 0.25, green: 0.20, blue: 0.14)
        static let secondaryInk = Color(red: 0.43, green: 0.37, blue: 0.28)
        static let ochre = Color(red: 0.73, green: 0.49, blue: 0.20)
        static let olive = Color(red: 0.38, green: 0.40, blue: 0.27)
    }

    enum Typography {
        static let title = Font.system(.largeTitle, design: .serif, weight: .medium)
        static let headline = Font.system(.title2, design: .serif, weight: .medium)
        static let body = Font.system(.body, design: .serif, weight: .regular)
        static let caption = Font.system(.subheadline, design: .serif, weight: .regular)
        static let button = Font.system(.body, design: .rounded, weight: .semibold)
    }

    enum Spacing {
        static let small: CGFloat = 12
        static let medium: CGFloat = 20
        static let large: CGFloat = 28
        static let page: CGFloat = 28
    }
}
