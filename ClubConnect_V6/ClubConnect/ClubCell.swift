import UIKit

final class ClubCell: UITableViewCell {

    @IBOutlet weak var clubIconImageView: UIImageView!
    @IBOutlet weak var clubNameLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!

    func configure(with club: Club) {
        clubNameLabel.text = club.name
        categoryLabel.text = club.category
        clubIconImageView.image = UIImage(systemName: club.iconName ?? "person.3.fill")
    }
}
