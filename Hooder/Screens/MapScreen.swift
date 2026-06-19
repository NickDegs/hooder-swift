import SwiftUI
import MapboxMaps

// MARK: - Notifications

extension Notification.Name {
    static let flyToCity        = Notification.Name("HooderFlyToCity")
    static let mapSelectHood    = Notification.Name("HooderMapSelectHood")
    static let mapSelectPlace   = Notification.Name("HooderMapSelectPlace")
}

// MARK: - MapboxView

struct MapboxView: UIViewRepresentable {
    let allHoods:    [HoodGroup]
    let highlightKey: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MapView {
        let camera = CameraOptions(
            center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
            zoom: 11, pitch: 52
        )
        let opts    = MapInitOptions(cameraOptions: camera, styleURI: .satelliteStreets)
        let mapView = MapView(frame: .zero, mapInitOptions: opts)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        var orn = mapView.ornaments.options
        orn.scaleBar.visibility = .hidden
        orn.compass.visibility  = .adaptive
        mapView.ornaments.options = orn

        context.coordinator.mapView   = mapView
        context.coordinator.parent    = self
        context.coordinator.allHoods  = allHoods

        let token = mapView.mapboxMap.onStyleLoaded.observeNext { _ in
            context.coordinator.addAnnotations()
        }
        context.coordinator.styleToken = token
        context.coordinator.setupObservers(mapView: mapView)

        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        context.coordinator.parent   = self
        context.coordinator.allHoods = allHoods
        context.coordinator.updateAnnotations()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, AnnotationInteractionDelegate {
        var parent:    MapboxView
        var allHoods:  [HoodGroup]
        weak var mapView: MapView?
        var styleToken:        AnyCancelable?
        var tapToken:          AnyCancelable?
        var moveToken:         AnyCancelable?
        var annotationManager: PointAnnotationManager?
        var cityObserver:      NSObjectProtocol?
        private var lastMoveTime: Date = .distantPast

        init(_ parent: MapboxView) {
            self.parent   = parent
            self.allHoods = parent.allHoods
        }

        deinit {
            if let obs = cityObserver { NotificationCenter.default.removeObserver(obs) }
        }

        func setupObservers(mapView: MapView) {
            // Fly-to-city notification
            cityObserver = NotificationCenter.default.addObserver(
                forName: .flyToCity, object: nil, queue: .main
            ) { [weak self] note in
                guard let city = note.userInfo?["city"] as? City,
                      let mv   = self?.mapView else { return }
                mv.camera.fly(to: CameraOptions(
                    center: CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng),
                    zoom: city.zoom, pitch: 52
                ), duration: 1.2)
            }

            // Map tap → find nearest hood + query POI features
            tapToken = mapView.gestures.onMapTap.observe { [weak self] gesture in
                self?.handleMapTap(gesture: gesture, mapView: mapView)
            }

            // NOT: Kamera hareketinde panel AÇMA YOK (PWA gibi). Panel yalnız pin'e
            // dokununca açılır (didDetectTappedAnnotations) — pan'de spam açılmaz.
        }

        private func handleMapTap(gesture: MapContentGestureContext, mapView: MapView) {
            let point   = gesture.point
            let coord   = gesture.coordinate
            let layers  = ["poi-label", "road-label", "natural-label", "place-label", "building", "transit-label"]
            let options = RenderedQueryOptions(layerIds: layers, filter: nil)

            mapView.mapboxMap.queryRenderedFeatures(with: point, options: options) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let features):
                    let priority = ["poi-label","road-label","natural-label","place-label","building","transit-label"]
                    var best: QueriedRenderedFeature?
                    for layerId in priority {
                        best = features.first {
                            $0.layers.contains(where: { $0 == layerId || $0.hasPrefix(layerId) })
                        }
                        if best != nil { break }
                    }
                    if best == nil { best = features.first }

                    let props   = best?.queriedFeature.feature.properties
                    let name    = ((props?["name_en"] ?? nil)?.rawValue as? String)
                        ?? ((props?["name"] ?? nil)?.rawValue as? String)
                        ?? ""
                    let address = ((props?["address"] ?? nil)?.rawValue as? String) ?? ""
                    let layerId = best?.layers.first ?? "land"
                    let typeStr = layerId
                        .replacingOccurrences(of: "-label",  with: "")
                        .replacingOccurrences(of: "-symbol", with: "")

                    let claimInfo = PlaceClaimInfo(
                        name: name, address: address, placeType: typeStr,
                        lat: coord.latitude, lng: coord.longitude
                    )
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .mapSelectPlace, object: nil,
                            userInfo: ["info": claimInfo]
                        )
                    }

                case .failure:
                    let claimInfo = PlaceClaimInfo(
                        name: "", address: "", placeType: "land",
                        lat: coord.latitude, lng: coord.longitude
                    )
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .mapSelectPlace, object: nil,
                            userInfo: ["info": claimInfo]
                        )
                    }
                }

                // Also zoom in
                let zoom = mapView.mapboxMap.cameraState.zoom
                let nextZoom = min(zoom + 2.5, 17.0)
                mapView.camera.fly(to: CameraOptions(
                    center: coord, zoom: nextZoom, pitch: min(62, 48 + nextZoom)
                ), duration: 0.9)
            }
        }

        private func handleCameraMove(mapView: MapView) {
            let now = Date()
            guard now.timeIntervalSince(lastMoveTime) >= 0.12 else { return }
            lastMoveTime = now
            let zoom   = mapView.mapboxMap.cameraState.zoom
            guard zoom >= 8 else { return }
            let center = mapView.mapboxMap.cameraState.center
            guard let hood = nearestHood(allHoods, lat: center.latitude, lng: center.longitude) else { return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .mapSelectHood, object: nil, userInfo: ["hood": hood]
                )
            }
        }

        func addAnnotations() {
            guard let mv = mapView else { return }
            let mgr = mv.annotations.makePointAnnotationManager()
            mgr.delegate = self
            annotationManager = mgr
            updateAnnotations()
        }

        func updateAnnotations() {
            guard let mgr = annotationManager else { return }
            let owned = (try? JSONDecoder().decode([String].self,
                from: UserDefaults.standard.data(forKey: "owned_ids") ?? Data())) ?? []
            let ownedSet = Set(owned)
            mgr.annotations = allProperties.map { prop in
                var ann = PointAnnotation(coordinate: prop.coordinate)
                ann.image    = PointAnnotation.Image(image: pinImage(hex: prop.accentHex, owned: ownedSet.contains(prop.id)), name: "\(prop.id)_\(ownedSet.contains(prop.id))")
                ann.iconSize = 1.3
                ann.userInfo = ["id": prop.id]
                return ann
            }
        }

        func annotationManager(_ manager: AnnotationManager,
                               didDetectTappedAnnotations annotations: [Annotation]) {
            guard let ann  = annotations.first as? PointAnnotation,
                  let id   = ann.userInfo?["id"] as? String,
                  let prop = allProperties.first(where: { $0.id == id }),
                  let mv   = mapView else { return }

            // Find hood for this property
            let hood = allHoods.first { $0.key == "\(prop.city)::\(prop.neighborhood)" }
            DispatchQueue.main.async {
                if let h = hood {
                    NotificationCenter.default.post(name: .mapSelectHood, object: nil, userInfo: ["hood": h])
                }
            }
            mv.camera.fly(to: CameraOptions(center: prop.coordinate, zoom: 15, pitch: 55), duration: 0.9)
        }

        private func pinImage(hex: String, owned: Bool) -> UIImage {
            let color  = UIColor(Color(hex: hex))
            let side: CGFloat = 22
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
            return renderer.image { ctx in
                let cg = ctx.cgContext
                cg.setFillColor(owned ? UIColor(Color(hex: "#30d158")).cgColor : color.cgColor)
                cg.fillEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
                cg.setFillColor(UIColor.white.cgColor)
                let inner: CGFloat = owned ? 6 : 8
                let off = (side - inner) / 2
                cg.fillEllipse(in: CGRect(x: off, y: off, width: inner, height: inner))
            }
        }
    }
}

// MARK: - Property Detail Panel (inline property quick-view)

struct PropertyDetailPanel: View {
    let property: Property
    var onClose:  () -> Void
    var onBuy:    () -> Void
    @EnvironmentObject var game: GameStore

    var accent:    Color { Color(hex: property.accentHex) }
    var owned:     Bool  { game.isOwned(property.id) }
    var canAfford: Bool  { game.cash >= property.price }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.white.opacity(0.25))
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
                            .font(.system(size: 24)).foregroundStyle(C.textMuted)
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
                    Label("Portföyünüzde", systemImage: "checkmark.seal.fill")
                        .font(.bodyBold).foregroundStyle(C.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.md)
                        .background(C.green.opacity(0.12), in: RoundedRectangle(cornerRadius: R.md))
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
                        .liquidGlassFill()
                        .clipShape(RoundedRectangle(cornerRadius: R.lg))
                    }
                    .disabled(!canAfford)
                }
            }
            .padding(.horizontal, Sp.lg)
            .padding(.bottom, Sp.lg)
        }
        .liquidGlassFill()
        .overlay { RoundedRectangle(cornerRadius: R.xl).stroke(C.specular, lineWidth: 0.5) }
        .clipShape(RoundedRectangle(cornerRadius: R.xl))
        .padding(.horizontal, Sp.md)
        .shadow(color: .black.opacity(0.45), radius: 24, y: -4)
    }
}
