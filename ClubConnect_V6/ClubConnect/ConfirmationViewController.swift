import UIKit

final class ConfirmationViewController: UIViewController {

    var name: String = "Club Member"
    var wantsReminders: Bool = false
    var role: String = "Member"
    var club: Club?

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var clubDetailStackView: UIStackView!
    @IBOutlet weak var clubIconImageView: UIImageView!
    @IBOutlet weak var clubNameLabel: UILabel!
    @IBOutlet weak var clubCategoryLabel: UILabel!
    @IBOutlet weak var clubDescriptionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Confirmation"

        let reminderStatus = wantsReminders ? "ON" : "OFF"
        messageLabel.text = """
        Thanks, \(name)! You’ve signed up as a \(role).
        Meeting reminders: \(reminderStatus)
        """

        if let club {
            clubDetailStackView.isHidden = false
            clubNameLabel.text = club.name
            clubCategoryLabel.text = club.category?.uppercased()
            clubIconImageView.image = UIImage(systemName: club.iconName ?? "person.3.fill")
            clubDescriptionLabel.text = "\(club.name ?? "This club") is listed under the \(club.category ?? "Campus") category."
        } else {
            clubDetailStackView.isHidden = true
        }
    }
}
