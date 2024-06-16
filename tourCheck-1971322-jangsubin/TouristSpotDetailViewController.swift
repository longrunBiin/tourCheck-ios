import UIKit
import Firebase
import FirebaseStorage

class TouristSpotDetailViewController: UIViewController {
    var contentId: String?
    var isSaved: Bool = false
    var spot: TouristSpot?

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var detailedAddressLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!


    override func viewDidLoad() {
            super.viewDidLoad()
            if let spot = spot {
                configureView(with: spot)
            } else {
                fetchTouristSpotDetail()
            }
            descriptionLabel.numberOfLines = 0
            setupSaveButton()
        }

    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }

    func configureView(with touristSpot: TouristSpot) {
            titleLabel.text = touristSpot.title
//            addressLabel.text = touristSpot.addr1
            detailedAddressLabel.text = touristSpot.addr1 ?? "상세 주소 없음"
            descriptionLabel.text = touristSpot.contentid ?? "설명 없음"

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
    func setupSaveButton() {
           if isSaved {
               saveButton.setTitle("삭제", for: .normal)
           } else {
               checkIfSaved()
           }
       }

       @IBAction func saveButtonTapped(_ sender: UIButton) {
           if isSaved {
               removeSavedSpot()
           } else {
               saveSpot()
           }
       }

    func fetchTouristSpotDetail() {
            guard let contentId = contentId else { return }
            TourAPIManager.shared.fetchTouristSpotDetail(contentId: contentId) { spotDetail in
                guard let spotDetail = spotDetail else { return }
                let touristSpot = TouristSpot(
                    title: spotDetail.title,
                    addr1: spotDetail.addr1,
                    addr2: spotDetail.addr2,
                    firstimage: spotDetail.firstimage,
                    contentid: spotDetail.overview ?? "",
                    mapx: spotDetail.mapx ?? "",
                    mapy: spotDetail.mapy ?? ""
                )
                DispatchQueue.main.async {
                    self.configureView(with: touristSpot)
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
                            "mapx": self.spot?.mapx ?? "",
                            "mapy": self.spot?.mapy ?? "",
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
