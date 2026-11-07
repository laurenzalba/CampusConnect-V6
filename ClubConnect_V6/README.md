# ClubConnect — Machine Problem 3 (Xcode 26.1.1)

This project extends the MP2 ClubConnect UIKit/Storyboard application for IT0093 Machine Problem 3.

## Implemented requirements

### Part A — Networking with URLSession
- `ClubService.fetchClubs` builds a URL and uses `URLSession.shared.dataTask`.
- Errors are checked before response processing.
- Only HTTP 2xx responses continue to JSON decoding.
- The request calls `task.resume()`.
- `ClubListViewController` syncs in `viewWillAppear` and also has a Refresh button.

### Part B — Codable + Core Data sync
- `ClubDTO: Codable` mirrors `name`, `category`, and `iconName`.
- `JSONDecoder().decode([ClubDTO].self, from:)` is wrapped in `do/catch`.
- Successful results return to the main thread.
- Existing Core Data `Club` records are deleted, remote records are inserted, the context is saved, and the table reloads.
- If networking fails, the app keeps showing the last locally saved Core Data collection.

### Part C — Profile photo + FileManager
- The welcome screen contains a profile image view and Choose Photo button.
- `PHPickerViewController` uses `selectionLimit = 1` and `.images`.
- The selected `UIImage` is loaded through `NSItemProvider.loadObject`.
- JPEG data is saved as `profile.jpg` in the app Documents directory.
- `viewDidLoad()` restores the saved image using `UIImage(contentsOfFile:)`.

### Part D — Location Services + MapKit
- Info.plist contains `NSLocationWhenInUseUsageDescription`.
- Campus Map is reachable from the welcome screen.
- `CLLocationManager` requests When-In-Use authorization and a one-time location.
- The map centers on the fixed campus coordinate and shows an `MKPointAnnotation`.
- The distance label uses `CLLocation.distance(from:)` and displays meters or kilometers.
- Denied/restricted/error states show a readable message rather than crashing.

## Important: JSON URL ownership requirement
The assignment requires **the URL of a JSON file you publish/control**. The app currently contains a working public test raw-Gist URL so the networking path can be exercised immediately.

Before submission:
1. Open the included `clubs.json` file.
2. Create your own GitHub Gist (or another instructor-approved static JSON host).
3. Paste `clubs.json` into it and obtain its **Raw** URL.
4. In `ClubConnect/ClubListViewController.swift`, replace `ClubService.remoteURLString` with your own raw URL.
5. Run the app again and take the required network-sync screenshot.

## Testing checklist in Xcode 26.1.1
1. Open `ClubConnect.xcodeproj`.
2. Select an iPhone simulator and Run.
3. Browse Clubs and confirm the network-sync prompt changes to `Synced ... records from remote JSON`.
4. Tap a row and confirm the detail screen opens.
5. Return to Welcome, tap Choose Photo, select an image, then force-quit/relaunch and confirm the photo remains.
6. Open Campus Map, allow location, and confirm the campus pin plus a distance value appear.
7. If Simulator location is unavailable, use **Features > Location** in Simulator and choose a test location.

## Submission helpers
- `clubs.json` — publish this yourself and replace the test URL.
- `Reflection_MP3.txt` — editable 3–5 sentence draft.
- `Screenshots/README.txt` — required screenshot checklist.
- `.git` — contains MP1/MP2 history plus MP3 Part A–D commits.

The actual Simulator screenshots must be captured on your Mac because they depend on Xcode, Photos, networking, and Simulator location services.
