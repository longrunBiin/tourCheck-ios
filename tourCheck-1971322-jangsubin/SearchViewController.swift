import UIKit
import Foundation

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var touristSpots: [TouristSpot] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return touristSpots.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TouristSpotCell", for: indexPath) as! TouristSpotTableViewCell
        let spot = touristSpots[indexPath.row]
        
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

    func fetchSpots(keyword: String) {
        TourAPIManager.shared.fetchTouristSpots(keyword: keyword) { spots in
            DispatchQueue.main.async {
                self.touristSpots = spots ?? []
                self.tableView.reloadData()
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let keyword = searchBar.text, !keyword.isEmpty {
            fetchSpots(keyword: keyword)
        }
        searchBar.resignFirstResponder()
    }
}

