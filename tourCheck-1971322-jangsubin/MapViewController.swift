import UIKit
import NMapsMap
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, NMFMapViewTouchDelegate {

    var locationManager = CLLocationManager()
    var naverMapView: NMFNaverMapView!
    var naverMap: NMFMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        naverMapView = NMFNaverMapView(frame: view.frame)
        naverMapView.showLocationButton = true
    
        view.addSubview(naverMapView)


        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        // NMFMapView 객체 가져오기 및 터치 델리게이트 설정
        naverMap = naverMapView.mapView
        naverMap.touchDelegate = self
        
    }

    // 위치 업데이트 시 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("현재 위치: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // 현 위치로 카메라 이동
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude))
        cameraUpdate.animation = .easeIn
        naverMap.moveCamera(cameraUpdate)

        // 위치 업데이트 멈춤 (한번만 이동하도록)
        locationManager.stopUpdatingLocation()
        
    }

    // 위치 접근 권한 상태가 변경될 때 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            // 권한이 거부된 경우 처리
            print("위치 서비스 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.")
        default:
            break
        }
    }

    // 위치 업데이트 실패 시 호출되는 메서드
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }

    // 지도 터치 이벤트 처리
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        print("Map tapped at: \(latlng.lat), \(latlng.lng)")

        // 마커 생성 및 지도에 추가
        let marker = NMFMarker(position: latlng)
        marker.mapView = mapView
    }
}
