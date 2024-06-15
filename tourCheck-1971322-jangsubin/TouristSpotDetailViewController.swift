import UIKit
import Firebase
import FirebaseStorage

class TouristSpotDetailViewController: UIViewController {
    var contentId: String?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var detailedAddressLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!

    var isSaved: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTouristSpotDetail()
        descriptionLabel.numberOfLines = 0
        checkIfSaved()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }

    func configureView(with touristSpot: TouristSpotDetail) {
        titleLabel.text = touristSpot.title
//        addressLabel.text = touristSpot.addr1
        detailedAddressLabel.text = touristSpot.addr1
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

    func checkIfSaved() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        guard let contentId = contentId else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(email).collection("savedSpots").whereField("contentid", isEqualTo: contentId).getDocuments { snapshot, error in
            if let error = error {
                print("Error checking saved status: \(error)")
                return
            }
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self.isSaved = true
                DispatchQueue.main.async {
                    self.saveButton.setTitle("삭제", for: .normal)
                }
            } else {
                self.isSaved = false
                DispatchQueue.main.async {
                    self.saveButton.setTitle("저장", for: .normal)
                }
            }
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        if isSaved {
            removeSavedSpot()
        } else {
            saveSpot()
        }
    }

    func saveSpot() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        guard let title = titleLabel.text, let address = detailedAddressLabel.text else { return }
        
        let db = Firestore.firestore()
        
        // 이미지 업로드
        if let image = imageView.image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference().child("user_images").child("\(email)_\(UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error)")
                    return
                }
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error)")
                        return
                    }
                    guard let imageUrl = url?.absoluteString else { return }
                    
                    // Firestore에 데이터 저장
                    db.collection("users").document(email).collection("savedSpots").addDocument(data: [
                        "title": title,
                        "address": address,
                        "detailedAddress": self.detailedAddressLabel.text ?? "",
                        "imageUrl": imageUrl,
                        "description": self.descriptionLabel.text ?? "",
                        "mapx": "mapx_value",
                        "mapy": "mapy_value",
                        "contentid": self.contentId ?? ""
                    ]) { error in
                        if let error = error {
                            print("Error saving tourist spot: \(error)")
                        } else {
                            print("Tourist spot saved successfully")
                            self.isSaved = true
                            self.saveButton.setTitle("삭제", for: .normal)
                        }
                    }
                }
            }
        }
    }

    func removeSavedSpot() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        guard let contentId = contentId else { return }

        let db = Firestore.firestore()
        db.collection("users").document(email).collection("savedSpots").whereField("contentid", isEqualTo: contentId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching saved spot to delete: \(error)")
                return
            }
            snapshot?.documents.first?.reference.delete(completion: { error in
                if let error = error {
                    print("Error deleting saved spot: \(error)")
                } else {
                    print("Tourist spot deleted successfully")
                    self.isSaved = false
                    self.saveButton.setTitle("저장", for: .normal)
                }
            })
        }
    }
}
