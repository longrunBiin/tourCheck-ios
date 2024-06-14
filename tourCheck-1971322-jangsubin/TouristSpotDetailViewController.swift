import UIKit
import Firebase

class TouristSpotDetailViewController: UIViewController {
    var contentId: String?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var detailedAddressLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTouristSpotDetail()
        descriptionLabel.numberOfLines = 0
    }

    func configureView(with touristSpot: TouristSpotDetail) {
        titleLabel.text = touristSpot.title
        addressLabel.text = touristSpot.addr1
        detailedAddressLabel.text = touristSpot.addr2 ?? "상세 주소 없음"
        descriptionLabel.text = touristSpot.overview ?? "설명 없음"

        if let imageUrl = touristSpot.firstimage, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                }
            }.resume()
        }
    }

    func fetchTouristSpotDetail() {
        guard let contentId = contentId else { return }
        TourAPIManager.shared.fetchTouristSpotDetail(contentId: contentId) { spotDetail in
            guard let spotDetail = spotDetail else { return }
            DispatchQueue.main.async {
                self.configureView(with: spotDetail)
            }
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser else { return }
        guard let title = titleLabel.text, let address = addressLabel.text else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.).collection("savedSpots").addDocument(data: [
            "title": title,
            "address": address,
            "detailedAddress": detailedAddressLabel.text ?? "",
            "imageUrl": imageView.image?.accessibilityIdentifier ?? "",
            "description": descriptionLabel.text ?? ""
        ]) { error in
            if let error = error {
                print("Error saving tourist spot: \(error)")
            } else {
                print("Tourist spot saved successfully")
            }
        }
    }
}
