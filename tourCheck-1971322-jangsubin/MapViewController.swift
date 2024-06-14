import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate {

    var locationManager = CLLocationManager()
    var naverMapView: NMFNaverMapView!
    var naverMap: NMFMapView!
    var currentLocation: CLLocation?
    var markers: [NMFMarker] = []
    var touristSpots: [TouristSpot] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        naverMapView = NMFNaverMapView(frame: view.frame)
        naverMapView.showLocationButton = true
        view.addSubview(naverMapView)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        naverMap = naverMapView.mapView
        naverMap.touchDelegate = self
        naverMap.addCameraDelegate(delegate: self)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        print("현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude))
        cameraUpdate.animation = .easeIn
        naverMap.moveCamera(cameraUpdate)

        locationManager.stopUpdatingLocation()

        fetchTouristSpotsAndAddMarkers()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("위치 서비스 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    func fetchTouristSpotsAndAddMarkers() {
        guard let location = currentLocation else { return }

        TourAPIManager.shared.fetchTouristSpotsNearby(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { spots in
            guard let spots = spots else { return }
            DispatchQueue.main.async {
                self.clearMarkers()
                self.touristSpots = spots
                self.addMarkers(for: spots)
            }
        }
    }

    func clearMarkers() {
        markers.forEach { $0.mapView = nil }
        markers.removeAll()
    }

    func addMarkers(for spots: [TouristSpot]) {
        spots.forEach { spot in
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: Double(spot.mapy) ?? 0.0, lng: Double(spot.mapx) ?? 0.0)
            marker.captionText = spot.title
            marker.iconTintColor = UIColor.purple // 마커 색상 변경
            marker.mapView = self.naverMap
            marker.touchHandler = { (overlay) -> Bool in
                self.showDetailForSpot(spot)
                return true
            }
            markers.append(marker)
        }
    }

    func showDetailForSpot(_ spot: TouristSpot) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "TouristSpotDetailViewController") as? TouristSpotDetailViewController {
            detailVC.contentId = spot.contentid
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // 카메라 이동 이벤트 처리
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let center = mapView.cameraPosition.target
        fetchTouristSpotsAndAddMarkersAt(latitude: center.lat, longitude: center.lng)
    }

    func fetchTouristSpotsAndAddMarkersAt(latitude: Double, longitude: Double) {
        TourAPIManager.shared.fetchTouristSpotsNearby(latitude: latitude, longitude: longitude) { spots in
            guard let spots = spots else { return }
            DispatchQueue.main.async {
                self.clearMarkers()
                self.touristSpots = spots
                self.addMarkers(for: spots)
            }
        }
    }
}
