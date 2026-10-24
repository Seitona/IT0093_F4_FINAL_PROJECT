import UIKit

/// Design tokens and small styling helpers for the Soft UI (neumorphism) look.
/// Every screen reads its colors from here so the whole app stays consistent.
enum Theme {

    // MARK: - Colors
    /// The single surface color: cards, buttons, and the screen share it so the
    /// light/dark shadow pair can make shapes look pushed out of the surface.
    static let background = UIColor(red: 0.878, green: 0.898, blue: 0.925, alpha: 1)
    /// Slightly darker tone for "pressed in" areas such as text fields.
    static let inset = UIColor(red: 0.820, green: 0.847, blue: 0.890, alpha: 1)
    static let textPrimary = UIColor(red: 0.216, green: 0.251, blue: 0.322, alpha: 1)
    static let textSecondary = UIColor(red: 0.420, green: 0.459, blue: 0.541, alpha: 1)
    static let accent = UIColor(red: 0.294, green: 0.400, blue: 0.847, alpha: 1)
    static let lightShadow = UIColor.white.withAlphaComponent(0.9)
    static let darkShadow = UIColor(red: 0.620, green: 0.678, blue: 0.784, alpha: 0.75)

    static let priorityGreen = UIColor(red: 0.20, green: 0.72, blue: 0.42, alpha: 1)
    static let priorityYellow = UIColor(red: 0.98, green: 0.76, blue: 0.12, alpha: 1)
    static let priorityRed = UIColor(red: 0.92, green: 0.30, blue: 0.30, alpha: 1)

    /// Priority is stored as a number in Core Data (0 Low, 1 Medium, 2 High).
    static func priorityColor(for value: Int16) -> UIColor {
        switch value {
        case 0:  return priorityGreen
        case 2:  return priorityRed
        default: return priorityYellow
        }
    }

    // MARK: - Layout constants
    /// Space around a row card so its shadows have room and rows do not touch.
    static let cardInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
    static let cardCornerRadius: CGFloat = 16

    // MARK: - Appearance
    /// Called once at launch: makes navigation bars blend into the soft surface.
    static func applyAppearance() {
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.backgroundColor = background
        standard.titleTextAttributes = [.foregroundColor: textPrimary]
        // At the top of a scroll view the bar is fully transparent, like the surface.
        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.titleTextAttributes = [.foregroundColor: textPrimary]
        UINavigationBar.appearance().standardAppearance = standard
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge
        UINavigationBar.appearance().tintColor = accent
    }

    // MARK: - Form controls
    /// Gives a text field a soft "pressed in" look instead of the system border.
    static func styleField(_ field: UITextField) {
        field.borderStyle = .none
        field.backgroundColor = inset
        field.textColor = textPrimary
        field.layer.cornerRadius = 12
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        if let placeholder = field.placeholder {
            field.attributedPlaceholder = NSAttributedString(
                string: placeholder, attributes: [.foregroundColor: textSecondary])
        }
    }

    /// Same pressed-in look for the multi-line note editor.
    static func styleTextView(_ textView: UITextView) {
        textView.layer.borderWidth = 0
        textView.backgroundColor = inset
        textView.textColor = textPrimary
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
    }

    /// Rounded, recessed frame for photo previews.
    static func styleImageWell(_ imageView: UIImageView) {
        imageView.backgroundColor = inset
        imageView.layer.cornerRadius = cardCornerRadius
        imageView.clipsToBounds = true
    }

    /// Colors every label under `view` so form text matches the soft palette.
    static func tintLabels(in view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel { label.textColor = textPrimary }
            tintLabels(in: subview)
        }
    }
}

extension UITableViewCell {
    /// Turns a plain table row into a raised soft card.
    func applySoftCardStyle() {
        backgroundColor = .clear
        selectedBackgroundView = UIView()   // no gray highlight; it would flatten the card
        if !(backgroundView is NeumorphicView) {
            backgroundView = NeumorphicView(cardInsets: Theme.cardInsets,
                                            cornerRadius: Theme.cardCornerRadius)
        }
    }
}
