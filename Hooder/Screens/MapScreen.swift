import SwiftUI
import MapboxMaps

// MARK: - MapboxView (UIViewRepresentable)

struct MapboxView: UIViewRepresentable {
    let properties: [Property]
    @Binding var selectedProperty: Property?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MapView {
        let camera = CameraOptions(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            zoom:   12,
            pitch:  50
        )
        let opts = MapInitOptions(cameraOptions: camera, styleURI: .satelliteStreets)
        let mapView = MapView(frame: .zero, mapInitOptions: opts)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        var ornOpts = mapView.ornaments.options
        ornOpts.scaleBar.visibility = .hidden
        ornOpts.compass.visibility  = .adaptive
        mapView.ornaments.options   = ornOpts

        context.coordinator.mapView = mapView

        let token = mapView.mapboxMap.onStyleLoaded.observeNext { [weak coordinator = context.coordinator] _ in
            coordinator?.addAnnotations()
        }
        context.coordinator.styleToken = token
        context.coordinator.setupCityObserver()

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {}

    // MARK: - Coordinator

    final class Coordinator: NSObject, AnnotationInteractionDelegate {
        var parent: MapboxView
        weak var mapView: MapView?
        var styleToken: AnyCancelable?
        var annotationManager: PointAnnotationManager?
        var cityObserver: NSObjectProtocol?

        init(_ parent: MapboxView) { self.parent = parent }

        deinit { cityObserver.map { NotificationCenter.default.removeObserver($0) } }

        func setupCityObserver() {
            cityObserver = NotificationCenter.default.addObserver(
                forName: .flyToCity, object: nil, queue: .main
            ) { [weak self] note in
                guard let city = note.userInfo?["city"] as? City,
                      let mv = self?.mapView else { return }
                mv.camera.fly(to: CameraOptions(
                    center: CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng),
                    zoom: city.zoom, pitch: 50
                ), duration: 1.2)
            }
        }

        func addAnnotations() {
            guard let mv = mapView else { return }
            let mgr = mv.annotations.makePointAnnotationManager()
            mgr.delegate = self
            mgr.annotations = parent.properties.map { prop in
                var ann = PointAnnotation(coordinate: prop.coordinate)
                ann.image   = PointAnnotation.Image(image: pinImage(hex: prop.accentHex), name: prop.id)
                ann.iconSize = 1.4
                ann.userInfo = ["id": prop.id]
                return ann
            }
            annotationManager = mgr
        }

        func annotationManager(_ manager: AnnotationManager,
                               didDetectTappedAnnotations annotations: [Annotation]) {
            guard let ann  = annotations.first as? PointAnnotation,
                  let id   = ann.userInfo?["id"] as? String,
                  let prop = parent.properties.first(where: { $0.id == id }) else { return }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.parent.selectedProperty = prop
                }
                self.mapView?.camera.fly(to: CameraOptions(
                    center: prop.coordinate, zoom: 15, pitch: 50
                ), duration: 0.8)
            }
        }

        private func pinImage(hex: String) -> UIImage {
            let color  = UIColor(Color(hex: hex))
            let side: CGFloat = 24
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
            return renderer.image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(color.cgColor)
                cg.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
                cg.setFillColor(UIColor.white.cgColor)
                let inner: CGFloat = 8
                let off = (side - inner) / 2
                cg.fillEllipse(in: CGRect(x: off, y: off, width: inner, height: inner))
            }
        }
    }
}

// MARK: - Property Detail Panel

struct PropertyDetailPanel: View {
    let property: Property
    var onClose: () -> Void
    var onBuy:   () -> Void
    @EnvironmentObject var game: GameStore

    var accent: Color   { Color(hex: property.accentHex) }
    var owned: Bool     { game.isOwned(property.id) }
    var canAfford: Bool { game.cash >= property.price }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 4)
                .padding(.top, Sp.md)

            VStack(alignment: .leading, spacing: Sp.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(property.category.emoji)
                            Text(property.category.label.uppercased())
                                .font(.label_).foregroundStyle(accent)
                        }
                        Text(property.name).font(.h3).foregroundStyle(C.text)
                        Text("\(property.neighborhood) · \(property.city)")
                            .font(.caption_).foregroundStyle(C.textSub)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(C.textMuted)
                    }
                }

                Text(property.description)
                    .font(.body_).foregroundStyle(C.textSub).lineLimit(3)

                HStack(spacing: Sp.sm) {
                    StatBadge(label: "Fiyat",   value: formatPrice(property.price),                    accent: C.text)
                    StatBadge(label: "Günlük",  value: formatIncome(property.incomePerDay),             accent: C.green)
                    StatBadge(label: "ROI/Yıl", value: String(format: "%.1f%%", property.roiPercent),  accent: C.gold)
                    StatBadge(label: "Prestij", value: String(repeating: "★", count: property.prestige), accent: C.purple)
                }

                if owned {
                    Label("Bu mülk portföyünüzde", systemImage: "checkmark.seal.fill")
                        .font(.bodyBold).foregroundStyle(C.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.md)
                        .background(C.green.opacity(0.12), in: RoundedRectangle(cornerRadius: R.md, style: .continuous))
                } else {
                    Button(action: onBuy) {
                        HStack {
                            Image(systemName: canAfford ? "cart.fill" : "lock.fill")
                            Text(canAfford ? "Satın Al — \(formatPrice(property.price))" : "Yetersiz Bakiye")
                                .font(.btnLg)
                        }
                        .foregroundStyle(canAfford ? .black : C.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.lg)
                        .background(canAfford ? C.primary : Color.clear)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: R.lg, style: .continuous))
                    }
                    .disabled(!canAfford)
                }
            }
            .padding(.horizontal, Sp.lg)
            .padding(.bottom, Sp.lg)
        }
        .background(.ultraThinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: R.xl, style: .continuous)
                .stroke(C.specular, lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: R.xl, style: .continuous))
        .padding(.horizontal, Sp.md)
        .shadow(color: .black.opacity(0.45), radius: 24, y: -4)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let flyToCity = Notification.Name("HooderFlyToCity")
}
