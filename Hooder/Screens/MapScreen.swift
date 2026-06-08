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

        // Hide ornaments (attribution must stay per ToS — keep it)
        var ornOpts = mapView.ornaments.options
        ornOpts.scaleBar.visibility = .hidden
        ornOpts.compass.visibility  = .adaptive
        mapView.ornaments.options   = ornOpts

        context.coordinator.mapView = mapView

        // Add annotations once style is loaded
        let token = mapView.mapboxMap.onStyleLoaded.observeNext { [weak coordinator = context.coordinator] _ in
            coordinator?.addAnnotations()
        }
        context.coordinator.styleToken = token

        // City fly notification
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
                let cam = CameraOptions(
                    center: CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng),
                    zoom: city.zoom,
                    pitch: 50
                )
                mv.camera.fly(to: cam, duration: 1.2)
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
                withAnimation { self.parent.selectedProperty = prop }
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

// MARK: - MapScreen

struct MapScreen: View {
    @EnvironmentObject var game: GameStore

    @State private var selectedProperty: Property?
    @State private var selectedCity: City? = allCities.first
    @State private var showCityPicker   = false
    @State private var showBuyConfirm   = false
    @State private var pendingBuy: Property?
    @State private var toastMsg: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            MapboxView(properties: allProperties, selectedProperty: $selectedProperty)
                .ignoresSafeArea()

            // Top HUD
            VStack(spacing: 0) {
                HStack {
                    cashBadge
                    Spacer()
                    cityPickerButton
                }
                .padding(.horizontal, Sp.lg)
                .padding(.top, Sp.lg)

                if showCityPicker {
                    cityChips
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()
            }

            // Property detail sheet
            if let prop = selectedProperty {
                PropertyDetailPanel(
                    property: prop,
                    onClose: { withAnimation { selectedProperty = nil } },
                    onBuy: {
                        pendingBuy = prop
                        showBuyConfirm = true
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedProperty?.id)
            }

            // Toast
            if let msg = toastMsg {
                Text(msg)
                    .font(.bodyBold)
                    .foregroundColor(C.text)
                    .padding(.horizontal, Sp.lg)
                    .padding(.vertical, Sp.md)
                    .background(C.bgCard)
                    .clipShape(Capsule())
                    .padding(.bottom, 120)
                    .transition(.opacity)
            }
        }
        .confirmationDialog(
            pendingBuy.map { "Satın al: \($0.name)" } ?? "",
            isPresented: $showBuyConfirm,
            titleVisibility: .visible
        ) {
            if let prop = pendingBuy {
                Button("Satın Al — \(formatPrice(prop.price))") { doBuy(prop) }
                Button("İptal", role: .cancel) {}
            }
        } message: {
            if let prop = pendingBuy {
                Text("Mevcut bakiye: \(formatPrice(game.cash))")
            }
        }
    }

    // MARK: Subviews

    private var cashBadge: some View {
        HStack(spacing: Sp.xs) {
            Image(systemName: "dollarsign.circle.fill").foregroundColor(C.gold)
            Text(formatPrice(game.cash)).font(.bodyBold).foregroundColor(C.text)
        }
        .padding(.horizontal, Sp.md)
        .padding(.vertical, Sp.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var cityPickerButton: some View {
        Button { withAnimation { showCityPicker.toggle() } } label: {
            HStack(spacing: Sp.xs) {
                Text(selectedCity?.flag ?? "🌍")
                Text(selectedCity?.name ?? "Şehir").font(.bodyBold).foregroundColor(C.text)
                Image(systemName: "chevron.down").font(.caption_).foregroundColor(C.textSub)
            }
            .padding(.horizontal, Sp.md)
            .padding(.vertical, Sp.sm)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }

    private var cityChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Sp.sm) {
                ForEach(allCities) { city in
                    Button {
                        selectedCity = city
                        withAnimation { showCityPicker = false }
                        NotificationCenter.default.post(
                            name: .flyToCity, object: nil, userInfo: ["city": city]
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Text(city.flag)
                            Text(city.name)
                                .font(.bodyBold)
                                .foregroundColor(selectedCity?.id == city.id ? C.primary : C.text)
                        }
                        .padding(.horizontal, Sp.md)
                        .padding(.vertical, Sp.sm)
                        .background(
                            selectedCity?.id == city.id
                                ? C.primary.opacity(0.2)
                                : Color(hex: "#0c1220").opacity(0.9)
                        )
                        .overlay(
                            Capsule().stroke(
                                selectedCity?.id == city.id ? C.primary : C.border, lineWidth: 1
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, Sp.lg)
            .padding(.vertical, Sp.sm)
        }
    }

    // MARK: Helpers

    private func doBuy(_ prop: Property) {
        let ok = game.buy(prop)
        showToast(ok ? "\(prop.name) satın alındı!" : "Yetersiz bakiye!")
        if ok { withAnimation { selectedProperty = nil } }
    }

    private func showToast(_ msg: String) {
        withAnimation { toastMsg = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMsg = nil }
        }
    }
}

// MARK: - Property Detail Panel

struct PropertyDetailPanel: View {
    let property: Property
    var onClose: () -> Void
    var onBuy: () -> Void
    @EnvironmentObject var game: GameStore

    var accent: Color  { Color(hex: property.accentHex) }
    var owned: Bool    { game.isOwned(property.id) }
    var canAfford: Bool { game.cash >= property.price }

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(C.border).frame(width: 36, height: 4).padding(.top, Sp.md)

            VStack(alignment: .leading, spacing: Sp.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text(property.category.emoji)
                            Text(property.category.label.uppercased())
                                .font(.label_).foregroundColor(accent)
                        }
                        Text(property.name).font(.h3).foregroundColor(C.text)
                        Text("\(property.neighborhood) · \(property.city)")
                            .font(.caption_).foregroundColor(C.textSub)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22)).foregroundColor(C.textMuted)
                    }
                }

                Text(property.description)
                    .font(.body_).foregroundColor(C.textSub).lineLimit(3)

                HStack(spacing: Sp.sm) {
                    StatBadge(label: "Fiyat",    value: formatPrice(property.price),                   accent: C.text)
                    StatBadge(label: "Günlük",   value: formatIncome(property.incomePerDay),            accent: C.green)
                    StatBadge(label: "ROI/Yıl",  value: String(format: "%.1f%%", property.roiPercent), accent: C.gold)
                    StatBadge(label: "Prestij",  value: String(repeating: "★", count: property.prestige), accent: C.purple)
                }

                if owned {
                    Label("Bu mülk portföyünüzde", systemImage: "checkmark.seal.fill")
                        .font(.bodyBold).foregroundColor(C.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.md)
                        .background(C.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: R.md))
                } else {
                    Button(action: onBuy) {
                        HStack {
                            Image(systemName: canAfford ? "cart.fill" : "lock.fill")
                            Text(canAfford ? "Satın Al — \(formatPrice(property.price))" : "Yetersiz Bakiye")
                                .font(.btnLg)
                        }
                        .foregroundColor(canAfford ? .black : C.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Sp.lg)
                        .background(canAfford ? C.primary : C.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: R.lg))
                    }
                    .disabled(!canAfford)
                }
            }
            .padding(.horizontal, Sp.lg)
            .padding(.bottom, Sp.lg)
        }
        .background(C.bgSheet)
        .clipShape(RoundedRectangle(cornerRadius: R.xl))
        .padding(.horizontal, Sp.md)
        .padding(.bottom, 90)
        .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let flyToCity = Notification.Name("HooderFlyToCity")
}
