import UIKit

/// Two stacked layers, each casting one shadow: a light one toward the top-left
/// and a dark one toward the bottom-right. Together they make a shape look raised.
/// (A single CALayer can only cast one shadow, hence two layers.)
final class SoftShadow {
    private let lightLayer = CALayer()
    private let darkLayer = CALayer()

    init(host: CALayer, distance: CGFloat = 5, blur: CGFloat = 10) {
        let configs: [(CALayer, UIColor, CGFloat)] = [
            (darkLayer, Theme.darkShadow, 1),
            (lightLayer, Theme.lightShadow, -1)
        ]
        for (layer, color, direction) in configs {
            layer.backgroundColor = Theme.background.cgColor
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = blur
            layer.shadowOffset = CGSize(width: direction * distance,
                                        height: direction * distance)
            // Index 0 keeps the shadows behind the host's own subviews.
            host.insertSublayer(layer, at: 0)
        }
    }

    /// Keeps the shadow layers matched to the host's current size.
    func update(frame: CGRect, cornerRadius: CGFloat) {
        // Implicit animations would make the shadows lag behind during layout.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: frame.size),
                                cornerRadius: cornerRadius).cgPath
        for layer in [darkLayer, lightLayer] {
            layer.frame = frame
            layer.cornerRadius = cornerRadius
            layer.shadowPath = path
        }
        CATransaction.commit()
    }
}

/// A raised soft card, used as the background of table rows.
final class NeumorphicView: UIView {
    private let cardInsets: UIEdgeInsets
    private let cornerRadius: CGFloat
    private var shadow: SoftShadow?

    init(cardInsets: UIEdgeInsets, cornerRadius: CGFloat) {
        self.cardInsets = cardInsets
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        backgroundColor = .clear
        // SoftShadow needs the view's own layer, which only exists after super.init.
        shadow = SoftShadow(host: layer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadow?.update(frame: bounds.inset(by: cardInsets), cornerRadius: cornerRadius)
    }
}

/// A raised soft button. Set it as the custom class of a UIButton in the storyboard;
/// it keeps the storyboard's title and text color and adds the shadows.
final class NeumorphicButton: UIButton {
    private var shadow: SoftShadow?
    private let cornerRadius: CGFloat = 14

    override func awakeFromNib() {
        super.awakeFromNib()
        var config = UIButton.Configuration.plain()
        config.title = configuration?.title
        config.baseForegroundColor = configuration?.baseForegroundColor ?? Theme.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20,
                                                       bottom: 14, trailing: 20)
        configuration = config
        shadow = SoftShadow(host: layer, distance: 4, blur: 8)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shadow?.update(frame: bounds, cornerRadius: cornerRadius)
    }

    // Slight shrink while pressed gives the "pushed in" feedback.
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }
}
