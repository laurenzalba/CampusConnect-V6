import UIKit
import CoreData

struct ClubDTO: Codable {
    let name: String
    let category: String
    let iconName: String
}

enum ClubServiceError: LocalizedError {
    case invalidURL
    case badResponse
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The club JSON URL is invalid."
        case .badResponse: return "The server returned an unsuccessful response."
        }
    }
}

final class ClubService {
    // Working public JSON with name/category/iconName fields. For submission, replace this
    // with the raw URL of the included clubs.json file after publishing it in YOUR GitHub Gist.
    static let remoteURLString = "https://gist.githubusercontent.com/Drtecsurge/1d589894c0927ef233eacc256e40d112/raw/5b182a840975cfc29088b47e6441a9aed36e2965/Fusion-genres.json"

    func fetchClubs(completion: @escaping (Result<[ClubDTO], Error>) -> Void) {
        guard let url = URL(string: Self.remoteURLString) else {
            completion(.failure(ClubServiceError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data else {
                completion(.failure(ClubServiceError.badResponse))
                return
            }

            do {
                let decoded = try JSONDecoder().decode([ClubDTO].self, from: data)
                completion(.success(decoded))
            } catch {
                print("JSON decode failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

final class ClubListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var studentName: String = "Club Member"
    var wantsReminders: Bool = false
    var role: String = "Member"

    private var clubs: [Club] = []
    private var selectedClub: Club?
    private let clubService = ClubService()

    private var context: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        return appDelegate.persistentContainer.viewContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Campus Clubs"
        tableView.dataSource = self
        tableView.delegate = self
        fetchLocalClubs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncRemoteClubs()
    }

    @IBAction func refreshTapped(_ sender: UIBarButtonItem) {
        syncRemoteClubs()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { clubs.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ClubCell", for: indexPath)
        guard let clubCell = cell as? ClubCell else { return cell }
        clubCell.configure(with: clubs[indexPath.row])
        return clubCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedClub = clubs[indexPath.row]
        performSegue(withIdentifier: "ShowClubDetailSegue", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowClubDetailSegue",
              let destination = segue.destination as? ConfirmationViewController else { return }
        destination.name = studentName
        destination.wantsReminders = wantsReminders
        destination.role = role
        destination.club = selectedClub
    }

    @IBAction func addClubTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add Local Club", message: "MP2 feature retained. A later remote refresh replaces local records with the published JSON.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Club name"; $0.autocapitalizationType = .words }
        alert.addTextField { $0.placeholder = "Category"; $0.autocapitalizationType = .words }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let name = alert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let category = alert?.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty, !category.isEmpty else { return }
            let club = Club(context: self.context)
            club.name = name
            club.category = category
            club.iconName = "person.3.fill"
            do { try self.context.save(); self.fetchLocalClubs() }
            catch { self.context.rollback(); print("Local insert failed: \(error.localizedDescription)") }
        })
        present(alert, animated: true)
    }

    private func syncRemoteClubs() {
        navigationItem.prompt = "Syncing remote JSON…"
        clubService.fetchClubs { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let dtos):
                    self.replaceCoreData(with: dtos)
                    self.navigationItem.prompt = "Synced \(dtos.count) records from remote JSON"
                case .failure(let error):
                    self.navigationItem.prompt = "Offline: showing saved Core Data"
                    print("Remote sync failed: \(error.localizedDescription)")
                    self.fetchLocalClubs()
                }
            }
        }
    }

    private func replaceCoreData(with dtos: [ClubDTO]) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Club")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
            context.reset()
            for dto in dtos {
                let club = Club(context: context)
                club.name = dto.name
                club.category = dto.category
                club.iconName = dto.iconName
            }
            try context.save()
            fetchLocalClubs()
        } catch {
            context.rollback()
            navigationItem.prompt = "Sync save failed; showing prior data"
            print("Core Data sync failed: \(error.localizedDescription)")
        }
    }

    private func fetchLocalClubs() {
        let request = Club.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            clubs = try context.fetch(request)
            tableView.reloadData()
        } catch {
            clubs = []
            tableView.reloadData()
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
}
