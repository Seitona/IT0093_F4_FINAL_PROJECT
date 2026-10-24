import UIKit

/// One cell of the notes grid: a square photo (or icon) with the note text below.
class NoteCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var noteLabel: UILabel!

    private var softShadow: SoftShadow?
    private let cornerRadius: CGFloat = Theme.cardCornerRadius

    // Called once when the cell is loaded from the storyboard: set up its look.
    override func awakeFromNib() {
        super.awakeFromNib()
        // The cell itself must NOT clip, or its soft shadows would be cut off.
        // Only the content view is rounded and clipped, so photos keep round corners.
        clipsToBounds = false
        backgroundColor = .clear
        contentView.backgroundColor = Theme.background
        contentView.layer.cornerRadius = cornerRadius
        contentView.clipsToBounds = true
        softShadow = SoftShadow(host: layer)
        photoImageView.clipsToBounds = true
        noteLabel.textColor = Theme.textPrimary
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        softShadow?.update(frame: bounds, cornerRadius: cornerRadius)
    }

    /// Fills the cell with one Note from the database.
    func configure(with note: Note) {
        noteLabel.text = note.text
        if let data = note.photoData, let image = UIImage(data: data) {
            photoImageView.image = image
            photoImageView.contentMode = .scaleAspectFill   // fill the square, crop extra
        } else {
            // No photo: show a text icon instead.
            photoImageView.image = UIImage(systemName: "text.alignleft")
            photoImageView.contentMode = .center
            photoImageView.tintColor = Theme.textSecondary
        }
    }

    // Cells are reused while scrolling, so clear the old picture first.
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
    }
}
