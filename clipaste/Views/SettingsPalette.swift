import SwiftUI

enum SettingsPalette {
    private static let sidebarAccent = Color.settingsSidebarAccent

    static func updateAccent(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            sidebarAccent.opacity(0.92)
        default:
            sidebarAccent.opacity(0.88)
        }
    }

    static func sidebarSelectionAccent(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            sidebarAccent.opacity(0.98)
        default:
            sidebarAccent.opacity(0.92)
        }
    }

    static func updateSurface(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            Color(.sRGB, red: 0.13, green: 0.18, blue: 0.22, opacity: 1.0)
        default:
            Color(.sRGB, red: 0.93, green: 0.96, blue: 0.97, opacity: 1.0)
        }
    }

    static func updateSurfaceBorder(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            Color(.sRGB, red: 0.24, green: 0.30, blue: 0.36, opacity: 1.0)
        default:
            Color(.sRGB, red: 0.84, green: 0.89, blue: 0.93, opacity: 1.0)
        }
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            Color(.sRGB, red: 0.10, green: 0.12, blue: 0.15, opacity: 1.0)
        default:
            Color(.sRGB, red: 0.98, green: 0.98, blue: 0.98, opacity: 1.0)
        }
    }

    static func sidebarSelectionFill(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            sidebarAccent.opacity(0.26)
        default:
            sidebarAccent.opacity(0.18)
        }
    }

    static func sidebarSelectionBorder(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            sidebarAccent.opacity(0.42)
        default:
            sidebarAccent.opacity(0.30)
        }
    }
}
