import Foundation

// MARK: - Properties Database

private func p(_ id: String, _ name: String, _ cat: PropertyCategory,
               _ hood: String, _ city: String, _ country: String,
               _ price: Int, _ income: Int, _ prestige: Int,
               _ lng: Double, _ lat: Double, _ desc: String) -> Property {
    Property(id: id, name: name, category: cat,
             neighborhood: hood, city: city, country: country,
             price: price, incomePerDay: income, prestige: prestige,
             lat: lat, lng: lng, description: desc)
}

let allProperties: [Property] = [
    // ── Istanbul
    p("ist-001","Grand Bosphorus Hotel",  .hotel,      "Beşiktaş",   "Istanbul","TR", 2_400_000, 4_800, 5, 28.9930, 41.0427, "Iconic Bosphorus-view hotel. Top-tier income, 5-star prestige."),
    p("ist-002","Levent Tower A",         .office,     "Levent",     "Istanbul","TR", 1_800_000, 3_200, 5, 29.0118, 41.0800, "Premium office tower in Istanbul's financial district."),
    p("ist-003","Taksim Grand Mall",      .retail,     "Beyoğlu",    "Istanbul","TR",   980_000, 2_100, 4, 28.9784, 41.0369, "High-traffic retail space at Taksim Square."),
    p("ist-004","Çeşme Marina Villa",     .residential,"Beyoğlu",    "Istanbul","TR", 1_200_000, 1_400, 4, 28.9750, 41.0340, "Luxury apartment with sea views in Beyoğlu."),
    p("ist-005","Kadıköy Bazaar Unit",    .retail,     "Kadıköy",    "Istanbul","TR",   420_000,   880, 3, 29.0270, 40.9908, "Prime retail in Kadıköy's vibrant market street."),
    p("ist-006","Üsküdar Residence",      .residential,"Üsküdar",    "Istanbul","TR",   650_000,   760, 3, 29.0157, 41.0233, "Peaceful residential complex with Bosphorus view."),
    p("ist-007","Maslak Office Park",     .office,     "Maslak",     "Istanbul","TR", 2_100_000, 3_600, 5, 29.0152, 41.1020, "Modern campus-style office park. High demand."),
    p("ist-008","Bebek Café Strip",       .retail,     "Bebek",      "Istanbul","TR",   780_000, 1_600, 4, 28.9565, 41.0778, "Trendy café & retail units on Bebek coastline."),
    p("ist-009","Ataşehir Loft",          .residential,"Ataşehir",   "Istanbul","TR",   520_000,   640, 3, 29.1188, 40.9888, "Modern loft in new business district."),
    p("ist-010","Kapalıçarşı Kiosk",      .retail,     "Fatih",      "Istanbul","TR", 3_500_000, 7_200, 5, 28.9674, 41.0107, "Historic Grand Bazaar unit. Legendary prestige."),
    // ── Dubai
    p("dxb-001","Burj Khalifa Office",   .office,      "Downtown",   "Dubai",  "AE",18_000_000,32_000, 5, 55.2744, 25.1972, "World's tallest building. Ultimate status property."),
    p("dxb-002","Dubai Mall Boutique",   .retail,      "Downtown",   "Dubai",  "AE", 4_200_000, 8_800, 5, 55.2796, 25.1985, "Premium boutique in the world's largest mall."),
    p("dxb-003","JBR Beach Condo",       .residential, "JBR",        "Dubai",  "AE", 2_800_000, 3_200, 4, 55.1270, 25.0777, "Beachfront luxury condo, Jumeirah Beach."),
    p("dxb-004","DIFC Tower Suite",      .office,      "DIFC",       "Dubai",  "AE", 6_500_000,11_400, 5, 55.2808, 25.2090, "Financial district trophy office."),
    p("dxb-005","Palm Villa",            .residential, "Palm Jumeirah","Dubai","AE",12_000_000,14_800, 5, 55.1302, 25.1125, "Iconic Palm Island villa. One of a kind."),
    // ── New York
    p("nyc-001","5th Ave Penthouse",     .residential, "Midtown",    "New York","US",22_000_000,28_000, 5,-73.9762, 40.7614, "Central Park view penthouse on Fifth Avenue."),
    p("nyc-002","Times Square Billboard",.retail,      "Midtown",    "New York","US", 8_500_000,18_000, 5,-73.9855, 40.7580, "Times Square retail — highest foot traffic on Earth."),
    p("nyc-003","SoHo Loft",            .residential,  "SoHo",       "New York","US", 3_200_000, 4_800, 4,-74.0020, 40.7234, "Cast-iron loft in SoHo. Artist's dream."),
    p("nyc-004","Wall St Office",        .office,      "Financial District","New York","US", 9_200_000,16_400, 5,-74.0089, 40.7069, "Heart of global finance."),
    p("nyc-005","Brooklyn Heights Apt",  .residential, "Brooklyn Heights","New York","US",1_800_000, 2_400, 4,-73.9946, 40.6962, "Classic brownstone apartment, river views."),
    // ── London
    p("lon-001","Mayfair Mansion",       .residential, "Mayfair",    "London", "GB",28_000_000,32_000, 5,-0.1499, 51.5110, "Ultra-prime Mayfair address. Rarest asset."),
    p("lon-002","Canary Wharf Tower",    .office,      "Canary Wharf","London","GB",11_000_000,19_200, 5,-0.0193, 51.5050, "Global banking district prestige office."),
    p("lon-003","Oxford St Flagship",    .retail,      "Westminster","London", "GB", 6_800_000,14_400, 5,-0.1408, 51.5154, "Europe's busiest shopping street."),
    p("lon-004","Shoreditch Studio",     .residential, "Shoreditch", "London", "GB", 1_200_000, 1_800, 3,-0.0790, 51.5224, "Trendy East London creative district."),
    // ── Tokyo
    p("tyo-001","Shinjuku Skyscraper",   .office,      "Shinjuku",   "Tokyo",  "JP",14_000_000,24_000, 5,139.6917, 35.6895, "Iconic Shinjuku office tower."),
    p("tyo-002","Shibuya Crossing Shop", .retail,      "Shibuya",    "Tokyo",  "JP", 5_600_000,12_000, 5,139.7016, 35.6580, "World's busiest intersection retail."),
    p("tyo-003","Ginza Gallery",         .retail,      "Ginza",      "Tokyo",  "JP", 8_200_000,16_800, 5,139.7685, 35.6718, "Luxury retail in Tokyo's finest district."),
    p("tyo-004","Roppongi Hills Apt",    .residential, "Roppongi",   "Tokyo",  "JP", 3_800_000, 5_200, 4,139.7313, 35.6605, "Upscale Roppongi Hills residences."),
    // ── Paris
    p("par-001","Champs-Élysées Boutique",.retail,     "8e",         "Paris",  "FR",16_000_000,28_800, 5, 2.3016, 48.8698, "The world's most famous avenue."),
    p("par-002","Marais Haussmann Apt",  .residential, "3e",         "Paris",  "FR", 4_200_000, 5_600, 4, 2.3580, 48.8597, "Classic Marais district apartment."),
    p("par-003","La Défense Tower",      .office,      "La Défense", "Paris",  "FR", 9_800_000,17_200, 5, 2.2396, 48.8924, "Paris's primary business district."),
    // ── Baku
    p("bak-001","Flame Tower Suite",     .office,      "White City", "Baku",   "AZ", 3_200_000, 5_800, 5,49.8672, 40.3694, "Iconic Flame Tower landmark office."),
    p("bak-002","Old City Boutique",     .retail,      "İçərişəhər", "Baku",   "AZ",   480_000,   920, 4,49.8362, 40.3662, "UNESCO heritage site retail."),
    p("bak-003","Bulvar Residence",      .residential, "Neftçilər",  "Baku",   "AZ",   820_000, 1_040, 3,49.8482, 40.3715, "Boulevard waterfront apartment."),
]

let allCities: [City] = [
    City(id: "istanbul", name: "Istanbul",  country: "TR", flag: "🇹🇷", lat: 41.0082, lng: 28.9784, zoom: 13),
    City(id: "dubai",    name: "Dubai",     country: "AE", flag: "🇦🇪", lat: 25.2048, lng: 55.2708, zoom: 13),
    City(id: "newyork",  name: "New York",  country: "US", flag: "🇺🇸", lat: 40.7128, lng:-74.0060, zoom: 13),
    City(id: "london",   name: "London",    country: "GB", flag: "🇬🇧", lat: 51.5074, lng: -0.1276, zoom: 13),
    City(id: "tokyo",    name: "Tokyo",     country: "JP", flag: "🇯🇵", lat: 35.6895, lng:139.6917, zoom: 13),
    City(id: "paris",    name: "Paris",     country: "FR", flag: "🇫🇷", lat: 48.8566, lng:  2.3522, zoom: 13),
    City(id: "baku",     name: "Baku",      country: "AZ", flag: "🇦🇿", lat: 40.4093, lng: 49.8671, zoom: 14),
]

let countryFlag: [String: String] = [
    "TR":"🇹🇷","AE":"🇦🇪","US":"🇺🇸","GB":"🇬🇧","JP":"🇯🇵","FR":"🇫🇷","AZ":"🇦🇿",
]
