import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var locationDescription: String?
    var defaultLocation: CLLocation? = CLLocation(latitude: 25.62, longitude: 85.14)

    private let manager: CLLocationManager
    private let geocoder = CLGeocoder()
    private var lastGeocodedLocation: CLLocation?
    private var lastGeocodeDate: Date?
    private let geocodeQueue = DispatchQueue(label: "LocationManager.Geocode")
    private let geocodeDistanceThreshold: CLLocationDistance = 200 // meters
    private let geocodeTimeThreshold: TimeInterval = 5 * 60

    override private init() {
        manager = CLLocationManager()
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        if let defaultLocation {
            lastLocation = defaultLocation
            resolvePlacemark(for: defaultLocation)
        }
    }

    func requestAccess() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else if let defaultLocation {
            lastLocation = defaultLocation
            resolvePlacemark(for: defaultLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        resolvePlacemark(for: location)
    }

    var resolvedLocation: CLLocation? {
        lastLocation ?? defaultLocation
    }

    private func resolvePlacemark(for location: CLLocation) {
        if shouldSkipGeocode(for: location) {
            return
        }

        lastGeocodedLocation = location
        lastGeocodeDate = Date()

        geocodeQueue.async { [weak self] in
            guard let self else { return }
            self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard error == nil else { return }
                guard let placemark = placemarks?.first else { return }
                let components = [
                    placemark.locality,
                    placemark.administrativeArea
                ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let description = components.isEmpty ? placemark.name : components.joined(separator: ", ")
                DispatchQueue.main.async {
                    self.locationDescription = description
                }
            }
        }
    }

    private func shouldSkipGeocode(for location: CLLocation) -> Bool {
        if let lastLocation = lastGeocodedLocation,
           location.distance(from: lastLocation) < geocodeDistanceThreshold,
           let lastDate = lastGeocodeDate,
           Date().timeIntervalSince(lastDate) < geocodeTimeThreshold {
            return true
        }
        if geocoder.isGeocoding {
            return true
        }
        return false
    }
}
