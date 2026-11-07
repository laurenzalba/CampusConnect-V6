import UIKit
import PhotosUI
import MapKit
import CoreLocation

final class WelcomeViewController: UIViewController, PHPickerViewControllerDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var reminderSwitch: UISwitch!
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!

    private enum DefaultsKey {
        static let studentName = "studentName"
        static let notificationsEnabled = "notificationsEnabled"
        static let selectedRoleIndex = "selectedRoleIndex"
        static let hasSavedRegistration = "hasSavedRegistration"
    }

    private var profilePhotoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile.jpg")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Campus Club Connect"
        navigationItem.title = "Campus Club Connect"
        profileImageView.layer.cornerRadius = 41
        profileImageView.clipsToBounds = true
        restoreRegistration()
        loadSavedProfilePhoto()
    }

    @IBAction func choosePhotoTapped(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            if let error {
                print("Photo load failed: \(error.localizedDescription)")
                return
            }
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.profileImageView.image = image
                self.saveProfilePhoto(image)
            }
        }
    }

    private func saveProfilePhoto(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        do {
            try data.write(to: profilePhotoURL, options: .atomic)
        } catch {
            print("Photo save failed: \(error.localizedDescription)")
        }
    }

    private func loadSavedProfilePhoto() {
        if let image = UIImage(contentsOfFile: profilePhotoURL.path) {
            profileImageView.image = image
        }
    }

    @IBAction func joinButtonTapped(_ sender: UIButton) {
        saveRegistration()
        nameTextField.resignFirstResponder()
        performSegue(withIdentifier: "ShowConfirmationSegue", sender: sender)
    }

    @IBAction func browseClubsTapped(_ sender: UIButton) {
        saveRegistration()
        nameTextField.resignFirstResponder()
        performSegue(withIdentifier: "BrowseClubsSegue", sender: sender)
    }

    @IBAction func campusMapTapped(_ sender: UIButton) {
        nameTextField.resignFirstResponder()
        performSegue(withIdentifier: "ShowCampusMapSegue", sender: sender)
    }

    private func saveRegistration() {
        let defaults = UserDefaults.standard
        defaults.set(nameTextField.text ?? "", forKey: DefaultsKey.studentName)
        defaults.set(reminderSwitch.isOn, forKey: DefaultsKey.notificationsEnabled)
        defaults.set(roleSegmentedControl.selectedSegmentIndex, forKey: DefaultsKey.selectedRoleIndex)
        defaults.set(true, forKey: DefaultsKey.hasSavedRegistration)
    }

    private func restoreRegistration() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: DefaultsKey.hasSavedRegistration) else {
            nameTextField.text = ""
            reminderSwitch.isOn = false
            roleSegmentedControl.selectedSegmentIndex = 0
            return
        }
        nameTextField.text = defaults.string(forKey: DefaultsKey.studentName) ?? ""
        reminderSwitch.isOn = defaults.bool(forKey: DefaultsKey.notificationsEnabled)
        let savedIndex = defaults.integer(forKey: DefaultsKey.selectedRoleIndex)
        roleSegmentedControl.selectedSegmentIndex = (0..<roleSegmentedControl.numberOfSegments).contains(savedIndex) ? savedIndex : 0
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let enteredName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let safeName = enteredName.isEmpty ? "Club Member" : enteredName
        let roles = ["Member", "Officer"]
        let selectedIndex = roleSegmentedControl.selectedSegmentIndex
        let safeRole = roles.indices.contains(selectedIndex) ? roles[selectedIndex] : "Member"

        if segue.identifier == "ShowConfirmationSegue",
           let destination = segue.destination as? ConfirmationViewController {
            destination.name = safeName
            destination.wantsReminders = reminderSwitch.isOn
            destination.role = safeRole
        } else if segue.identifier == "BrowseClubsSegue",
                  let destination = segue.destination as? ClubListViewController {
            destination.studentName = safeName
            destination.wantsReminders = reminderSwitch.isOn
            destination.role = safeRole
        }
    }
}

final class CampusMapViewController: UIViewController, @preconcurrency CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!

    private let locationManager = CLLocationManager()
    // FEU Institute of Technology / P. Paredes area in Manila.
    private let campusCoordinate = CLLocationCoordinate2D(latitude: 14.6042, longitude: 120.9883)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Campus Map"
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        configureCampusMap()
        locationManager.requestWhenInUseAuthorization()
    }

    private func configureCampusMap() {
        let region = MKCoordinateRegion(
            center: campusCoordinate,
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )
        mapView.setRegion(region, animated: false)
        let annotation = MKPointAnnotation()
        annotation.coordinate = campusCoordinate
        annotation.title = "FEU Institute of Technology"
        mapView.addAnnotation(annotation)
    }

    // Core Location delivers delegate callbacks on the run loop of the thread
    // that created CLLocationManager. This manager is created on the main thread
    // in this view controller, so @preconcurrency safely bridges the older
    // Objective-C delegate protocol to Swift 6 actor isolation.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView.showsUserLocation = true
            manager.requestLocation()
        case .denied, .restricted:
            distanceLabel.text = "Location access is unavailable. Enable it in Settings to calculate your distance from campus."
        case .notDetermined:
            break
        @unknown default:
            distanceLabel.text = "Unable to determine location authorization status."
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        let campusLocation = CLLocation(latitude: campusCoordinate.latitude, longitude: campusCoordinate.longitude)
        let meters = currentLocation.distance(from: campusLocation)

        if meters >= 1000 {
            distanceLabel.text = String(format: "Distance from campus: %.2f km", meters / 1000)
        } else {
            distanceLabel.text = String(format: "Distance from campus: %.0f meters", meters)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        distanceLabel.text = "Could not read your current location. Try again in a moment."
        print("Location error: \(error.localizedDescription)")
    }
}
