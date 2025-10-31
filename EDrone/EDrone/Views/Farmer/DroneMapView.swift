import SwiftUI
import MapKit

struct DroneMapView: View {
    var drones: [Drone]

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.59, longitude: 78.96),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )

    var body: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            annotationItems: drones
        ) { drone in
            MapAnnotation(coordinate: drone.coordinate) {
                VStack {
                    Image(systemName: "airplane.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text(drone.name)
                        .font(.caption)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .onAppear {
            if let first = drones.first {
                region.center = first.coordinate
                region.span = MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
