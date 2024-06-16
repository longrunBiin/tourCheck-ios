import UIKit
import Firebase

class SavedSpotsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var savedSpotsTableView: UITableView!

    var savedSpots: [TouristSpot] = []
    var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        savedSpotsTableView.delegate = self
        savedSpotsTableView.dataSource = self
        
        startListeningForSavedSpots()
    }
    
    deinit {
        listener?.remove()
    }

    func startListeningForSavedSpots() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        
        let db = Firestore.firestore()
        listener = db.collection("users").document(email).collection("savedSpots").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching saved spots: \(error)")
                return
            }
            
            self.savedSpots = snapshot?.documents.compactMap { document -> TouristSpot? in
                let data = document.data()
                let title = data["title"] as? String ?? "No Title"
                let address = data["address"] as? String ?? "No Address"
                let detailedAddress = data["detailedAddress"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let mapx = data["mapx"] as? String ?? ""
                let mapy = data["mapy"] as? String ?? ""
                let contentid = data["contentid"] as? String ?? ""

                return TouristSpot(title: title, addr1: address, addr2: detailedAddress, firstimage: imageUrl, contentid: contentid, mapx: mapx, mapy: mapy)
            } ?? []
            
            self.savedSpotsTableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedSpots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedSpotCell", for: indexPath) as! SavedSpotTableViewCell
        let spot = savedSpots[indexPath.row]
        
        cell.titleLabel.text = spot.title
        cell.addressLabel.text = spot.addr1
        if let imageUrl = spot.firstimage, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    DispatchQueue.main.async {
                        cell.spotImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        } else {
            cell.spotImageView.image = UIImage(named: "placeholder")
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let spot = savedSpots[indexPath.row]
        performSegue(withIdentifier: "showTouristSpotDetail", sender: spot)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTouristSpotDetail" {
            if let detailVC = segue.destination as? TouristSpotDetailViewController, let spot = sender as? TouristSpot {
                detailVC.contentId = spot.contentid
                detailVC.isSaved = true
            }
        }
    }
}

class SavedSpotTableViewCell: UITableViewCell {
    @IBOutlet weak var spotImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
}
