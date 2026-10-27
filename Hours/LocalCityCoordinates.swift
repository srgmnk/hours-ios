/// Reviewed WGS84 city reference points, frozen on 2026-10-26.
/// Keys are the unchanged Resources/cities.json catalog IDs, not saved City.id values.
/// Use exact dictionary lookup only; an unknown catalog ID has no coordinate.
///
/// 150 entries retain GeoNames populated-place coordinates without adjustment.
/// Attribution: © GeoNames, https://www.geonames.org/, CC BY 4.0:
/// https://creativecommons.org/licenses/by/4.0/
/// Dataset: https://download.geonames.org/export/dump/cities15000.zip (2026-10-26).
/// Per-entry GeoNames IDs resolve at https://www.geonames.org/<ID>/.
/// Country and administrative region were reviewed, not inferred from time zones.
///
/// All 152 city identities/countries were cross-checked against Natural Earth:
/// https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-populated-places/
/// https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_10m_populated_places_simple.geojson
/// Natural Earth is public domain; its city points are not survey monuments.
///
/// Two reviewed source choices avoid using broad metropolitan anchors:
/// Dubai: UNGEGN city 1893, coordinates attributed to NGA GNS (not GeoNames 292223).
/// https://ungegn.un.org/dashboard/cities/details?id=1893
/// Muscat: Natural Earth ne_id 1159150717 latitude/longitude attributes,
/// the historic capital-city point (rather than its cartographic geometry)
/// (not GeoNames 287286, which represents the wider metropolitan area).
/// Frankfurt means Frankfurt am Main, Hesse, as confirmed by the product owner.
/// Source precision does not imply surveyed accuracy or municipal boundaries.
nonisolated enum LocalCityCoordinates {
    struct Coordinate: Equatable, Sendable {
        let latitude: Double
        let longitude: Double
    }

    static let byCatalogID: [String: Coordinate] = [
        "bangkok-th": .init(latitude: 13.75398, longitude: 100.50144), // Bangkok, TH/Bangkok; GeoNames 1609350
        "chiang-mai-th": .init(latitude: 18.79038, longitude: 98.98468), // Chiang Mai, TH/Chiang Mai; GeoNames 1153671
        "tokyo-jp": .init(latitude: 35.6895, longitude: 139.69171), // Tokyo, JP/Tokyo; GeoNames 1850147
        "osaka-jp": .init(latitude: 34.69379, longitude: 135.50107), // Osaka, JP/Osaka; GeoNames 1853909
        "seoul-kr": .init(latitude: 37.566, longitude: 126.9784), // Seoul, KR/Seoul; GeoNames 1835848
        "busan-kr": .init(latitude: 35.10168, longitude: 129.03004), // Busan, KR/Busan; GeoNames 1838524
        "beijing-cn": .init(latitude: 39.9075, longitude: 116.39723), // Beijing, CN/Beijing; GeoNames 1816670
        "shanghai-cn": .init(latitude: 31.22222, longitude: 121.45806), // Shanghai, CN/Shanghai; GeoNames 1796236
        "shenzhen-cn": .init(latitude: 22.54554, longitude: 114.0683), // Shenzhen, CN/Guangdong; GeoNames 1795565
        "guangzhou-cn": .init(latitude: 23.11667, longitude: 113.25), // Guangzhou, CN/Guangdong; GeoNames 1809858
        "hong-kong-hk": .init(latitude: 22.27832, longitude: 114.17469), // Hong Kong, HK; GeoNames 1819729
        "taipei-tw": .init(latitude: 25.05306, longitude: 121.52639), // Taipei, TW; GeoNames 1668341
        "singapore-sg": .init(latitude: 1.28967, longitude: 103.85007), // Singapore, SG; GeoNames 1880252
        "kuala-lumpur-my": .init(latitude: 3.1412, longitude: 101.68653), // Kuala Lumpur, MY/Kuala Lumpur; GeoNames 1735161
        "jakarta-id": .init(latitude: -6.21462, longitude: 106.84513), // Jakarta, ID/Jakarta; GeoNames 1642911
        "surabaya-id": .init(latitude: -7.24917, longitude: 112.75083), // Surabaya, ID/East Java; GeoNames 1625822
        "manila-ph": .init(latitude: 14.6042, longitude: 120.9822), // Manila, PH/National Capital Region; GeoNames 1701668
        "cebu-ph": .init(latitude: 10.31672, longitude: 123.89071), // Cebu City, PH/Central Visayas; GeoNames 1717512
        "hanoi-vn": .init(latitude: 21.0245, longitude: 105.84117), // Hanoi, VN/Hanoi; GeoNames 1581130
        "ho-chi-minh-vn": .init(latitude: 10.82302, longitude: 106.62965), // Ho Chi Minh City, VN/Ho Chi Minh City (HCMC); GeoNames 1566083
        "phnom-penh-kh": .init(latitude: 11.56245, longitude: 104.91601), // Phnom Penh, KH/Phnom Penh; GeoNames 1821306
        "vientiane-la": .init(latitude: 17.96667, longitude: 102.6), // Vientiane, LA/Vientiane Prefecture; GeoNames 1651944
        "yangon-mm": .init(latitude: 16.80528, longitude: 96.15611), // Yangon, MM/Yangon; GeoNames 1298824
        "delhi-in": .init(latitude: 28.65195, longitude: 77.23149), // Delhi, IN/Delhi; GeoNames 1273294
        "mumbai-in": .init(latitude: 19.07283, longitude: 72.88261), // Mumbai, IN/Maharashtra; GeoNames 1275339
        "kolkata-in": .init(latitude: 22.56263, longitude: 88.36304), // Kolkata, IN/West Bengal; GeoNames 1275004
        "bengaluru-in": .init(latitude: 12.97194, longitude: 77.59369), // Bengaluru, IN/Karnataka; GeoNames 1277333
        "chennai-in": .init(latitude: 13.08784, longitude: 80.27847), // Chennai, IN/Tamil Nadu; GeoNames 1264527
        "hyderabad-in": .init(latitude: 17.38405, longitude: 78.45636), // Hyderabad, IN/Telangana; GeoNames 1269843
        "karachi-pk": .init(latitude: 24.8608, longitude: 67.0104), // Karachi, PK/Sindh; GeoNames 1174872
        "lahore-pk": .init(latitude: 31.558, longitude: 74.35071), // Lahore, PK/Punjab; GeoNames 1172451
        "dhaka-bd": .init(latitude: 23.7104, longitude: 90.40744), // Dhaka, BD/Dhaka Division; GeoNames 1185241
        "kathmandu-np": .init(latitude: 27.70169, longitude: 85.3206), // Kathmandu, NP/Bagmati Province; GeoNames 1283240
        "colombo-lk": .init(latitude: 6.93548, longitude: 79.84868), // Colombo, LK/Western Province; GeoNames 1248991
        "dubai-ae": .init(latitude: 25.252222, longitude: 55.28), // Dubai, AE; UNGEGN 1893 / NGA GNS
        "abu-dhabi-ae": .init(latitude: 24.45118, longitude: 54.39696), // Abu Dhabi, AE/Abu Dhabi; GeoNames 292968
        "doha-qa": .init(latitude: 25.28545, longitude: 51.53096), // Doha, QA/Baladiyat ad Dawhah; GeoNames 290030
        "riyadh-sa": .init(latitude: 24.68773, longitude: 46.72185), // Riyadh, SA/Riyadh Region; GeoNames 108410
        "jeddah-sa": .init(latitude: 21.49012, longitude: 39.18624), // Jeddah, SA/Mecca Region; GeoNames 105343
        "muscat-om": .init(latitude: 23.613325, longitude: 58.593312), // Muscat, OM; Natural Earth ne_id 1159150717 (historic city)
        "tehran-ir": .init(latitude: 35.69439, longitude: 51.42151), // Tehran, IR/Tehran; GeoNames 112931
        "baghdad-iq": .init(latitude: 33.34058, longitude: 44.40088), // Baghdad, IQ/Baghdad; GeoNames 98182
        "jerusalem-il": .init(latitude: 31.76904, longitude: 35.21633), // Jerusalem, IL/Jerusalem; GeoNames 281184
        "tel-aviv-il": .init(latitude: 32.08088, longitude: 34.78057), // Tel Aviv, IL/Tel Aviv; GeoNames 293397
        "amman-jo": .init(latitude: 31.95522, longitude: 35.94503), // Amman, JO/Amman; GeoNames 250441
        "beirut-lb": .init(latitude: 33.89332, longitude: 35.50157), // Beirut, LB/Beirut; GeoNames 276781
        "istanbul-tr": .init(latitude: 41.01384, longitude: 28.94966), // Istanbul, TR/Istanbul; GeoNames 745044
        "ankara-tr": .init(latitude: 39.91987, longitude: 32.85427), // Ankara, TR/Ankara; GeoNames 323786
        "tbilisi-ge": .init(latitude: 41.69143, longitude: 44.83412), // Tbilisi, GE/Tbilisi; GeoNames 611717
        "yerevan-am": .init(latitude: 40.17765, longitude: 44.5126), // Yerevan, AM/Yerevan; GeoNames 616052
        "baku-az": .init(latitude: 40.37767, longitude: 49.89201), // Baku, AZ/Baki; GeoNames 587084
        "almaty-kz": .init(latitude: 43.25249, longitude: 76.9115), // Almaty, KZ/Almaty; GeoNames 1526384
        "astana-kz": .init(latitude: 51.1801, longitude: 71.44598), // Astana, KZ/Astana; GeoNames 1526273
        "tashkent-uz": .init(latitude: 41.26465, longitude: 69.21627), // Tashkent, UZ/Tashkent; GeoNames 1512569
        "bishkek-kg": .init(latitude: 42.87, longitude: 74.59), // Bishkek, KG/Bishkek; GeoNames 1528675
        "yekaterinburg-ru": .init(latitude: 56.85733, longitude: 60.61529), // Yekaterinburg, RU/Sverdlovsk Oblast; GeoNames 1486209
        "perm-ru": .init(latitude: 58.01046, longitude: 56.25017), // Perm, RU/Perm Krai; GeoNames 511196
        "novosibirsk-ru": .init(latitude: 55.02259, longitude: 82.93175), // Novosibirsk, RU/Novosibirsk Oblast; GeoNames 1496747
        "vladivostok-ru": .init(latitude: 43.10562, longitude: 131.87353), // Vladivostok, RU/Primorye; GeoNames 2013348
        "moscow-ru": .init(latitude: 55.75204, longitude: 37.61781), // Moscow, RU/Moscow; GeoNames 524901
        "saint-petersburg-ru": .init(latitude: 59.93863, longitude: 30.31413), // Saint Petersburg, RU/St. Petersburg; GeoNames 498817
        "london-gb": .init(latitude: 51.50853, longitude: -0.12574), // London, GB/England; GeoNames 2643743
        "manchester-gb": .init(latitude: 53.48095, longitude: -2.23743), // Manchester, GB/England; GeoNames 2643123
        "edinburgh-gb": .init(latitude: 55.95206, longitude: -3.19648), // Edinburgh, GB/Scotland; GeoNames 2650225
        "dublin-ie": .init(latitude: 53.33306, longitude: -6.24889), // Dublin, IE/Leinster; GeoNames 2964574
        "paris-fr": .init(latitude: 48.85341, longitude: 2.3488), // Paris, FR/Île-de-France; GeoNames 2988507
        "lyon-fr": .init(latitude: 45.74906, longitude: 4.84789), // Lyon, FR/Auvergne-Rhône-Alpes; GeoNames 2996944
        "marseille-fr": .init(latitude: 43.29695, longitude: 5.38107), // Marseille, FR/Provence-Alpes-Côte d'Azur; GeoNames 2995469
        "berlin-de": .init(latitude: 52.52437, longitude: 13.41053), // Berlin, DE/State of Berlin; GeoNames 2950159
        "munich-de": .init(latitude: 48.13743, longitude: 11.57549), // Munich, DE/Bavaria; GeoNames 2867714
        "hamburg-de": .init(latitude: 53.55073, longitude: 9.99302), // Hamburg, DE/Hamburg; GeoNames 2911298
        "frankfurt-de": .init(latitude: 50.11552, longitude: 8.68417), // Frankfurt am Main, DE/Hesse; GeoNames 2925533
        "amsterdam-nl": .init(latitude: 52.37403, longitude: 4.88969), // Amsterdam, NL/North Holland; GeoNames 2759794
        "brussels-be": .init(latitude: 50.85045, longitude: 4.34878), // Brussels, BE/Brussels Capital; GeoNames 2800866
        "madrid-es": .init(latitude: 40.4165, longitude: -3.70256), // Madrid, ES/Madrid; GeoNames 3117735
        "barcelona-es": .init(latitude: 41.38879, longitude: 2.15899), // Barcelona, ES/Catalonia; GeoNames 3128760
        "lisbon-pt": .init(latitude: 38.72509, longitude: -9.1498), // Lisbon, PT/Lisbon; GeoNames 2267057
        "porto-pt": .init(latitude: 41.1485, longitude: -8.61097), // Porto, PT/Porto; GeoNames 2735943
        "rome-it": .init(latitude: 41.89193, longitude: 12.51133), // Rome, IT/Lazio; GeoNames 3169070
        "milan-it": .init(latitude: 45.46427, longitude: 9.18951), // Milan, IT/Lombardy; GeoNames 3173435
        "naples-it": .init(latitude: 40.85216, longitude: 14.26811), // Naples, IT/Campania; GeoNames 3172394
        "zurich-ch": .init(latitude: 47.36667, longitude: 8.55), // Zürich, CH/Zurich; GeoNames 2657896
        "geneva-ch": .init(latitude: 46.20222, longitude: 6.14569), // Geneva, CH/Geneva; GeoNames 2660646
        "vienna-at": .init(latitude: 48.20849, longitude: 16.37208), // Vienna, AT/Vienna; GeoNames 2761369
        "prague-cz": .init(latitude: 50.08804, longitude: 14.42076), // Prague, CZ/Prague; GeoNames 3067696
        "warsaw-pl": .init(latitude: 52.22977, longitude: 21.01178), // Warsaw, PL/Mazovia; GeoNames 756135
        "krakow-pl": .init(latitude: 50.06143, longitude: 19.93658), // Kraków, PL/Lesser Poland; GeoNames 3094802
        "budapest-hu": .init(latitude: 47.49835, longitude: 19.04045), // Budapest, HU/Budapest; GeoNames 3054643
        "bucharest-ro": .init(latitude: 44.43225, longitude: 26.10626), // Bucharest, RO/Bucharest; GeoNames 683506
        "sofia-bg": .init(latitude: 42.69751, longitude: 23.32415), // Sofia, BG/Sofia-Capital; GeoNames 727011
        "athens-gr": .init(latitude: 37.98376, longitude: 23.72784), // Athens, GR/Attica; GeoNames 264371
        "kyiv-ua": .init(latitude: 50.45466, longitude: 30.5238), // Kyiv, UA/Kyiv City; GeoNames 703448
        "helsinki-fi": .init(latitude: 60.16952, longitude: 24.93545), // Helsinki, FI/Uusimaa; GeoNames 658225
        "stockholm-se": .init(latitude: 59.32938, longitude: 18.06871), // Stockholm, SE/Stockholm; GeoNames 2673730
        "oslo-no": .init(latitude: 59.91273, longitude: 10.74609), // Oslo, NO/Oslo; GeoNames 3143244
        "copenhagen-dk": .init(latitude: 55.67594, longitude: 12.56553), // Copenhagen, DK/Capital Region; GeoNames 2618425
        "reykjavik-is": .init(latitude: 64.13548, longitude: -21.89541), // Reykjavík, IS/Capital Region; GeoNames 3413829
        "cairo-eg": .init(latitude: 30.06263, longitude: 31.24967), // Cairo, EG/Cairo; GeoNames 360630
        "casablanca-ma": .init(latitude: 33.58831, longitude: -7.61138), // Casablanca, MA/Casablanca-Settat; GeoNames 2553604
        "algiers-dz": .init(latitude: 36.73225, longitude: 3.08746), // Algiers, DZ/Algiers; GeoNames 2507480
        "tunis-tn": .init(latitude: 36.81897, longitude: 10.16579), // Tunis, TN/Tunis Governorate; GeoNames 2464470
        "lagos-ng": .init(latitude: 6.45407, longitude: 3.39467), // Lagos, NG/Lagos; GeoNames 2332459
        "accra-gh": .init(latitude: 5.55602, longitude: -0.1969), // Accra, GH/Greater Accra; GeoNames 2306104
        "nairobi-ke": .init(latitude: -1.28333, longitude: 36.81667), // Nairobi, KE/Nairobi County; GeoNames 184745
        "addis-ababa-et": .init(latitude: 9.02497, longitude: 38.74689), // Addis Ababa, ET/Addis Ababa; GeoNames 344979
        "johannesburg-za": .init(latitude: -26.20227, longitude: 28.04363), // Johannesburg, ZA/Gauteng; GeoNames 993800
        "cape-town-za": .init(latitude: -33.92584, longitude: 18.42322), // Cape Town, ZA/Western Cape; GeoNames 3369157
        "new-york-us": .init(latitude: 40.71427, longitude: -74.00597), // New York City, US/New York; GeoNames 5128581
        "boston-us": .init(latitude: 42.35843, longitude: -71.05977), // Boston, US/Massachusetts; GeoNames 4930956
        "miami-us": .init(latitude: 25.77427, longitude: -80.19366), // Miami, US/Florida; GeoNames 4164138
        "atlanta-us": .init(latitude: 33.749, longitude: -84.38798), // Atlanta, US/Georgia; GeoNames 4180439
        "washington-us": .init(latitude: 38.89511, longitude: -77.03637), // Washington, US/District of Columbia; GeoNames 4140963
        "chicago-us": .init(latitude: 41.85003, longitude: -87.65005), // Chicago, US/Illinois; GeoNames 4887398
        "houston-us": .init(latitude: 29.76328, longitude: -95.36327), // Houston, US/Texas; GeoNames 4699066
        "dallas-us": .init(latitude: 32.78306, longitude: -96.80667), // Dallas, US/Texas; GeoNames 4684888
        "denver-us": .init(latitude: 39.73915, longitude: -104.9847), // Denver, US/Colorado; GeoNames 5419384
        "phoenix-us": .init(latitude: 33.44838, longitude: -112.07404), // Phoenix, US/Arizona; GeoNames 5308655
        "los-angeles-us": .init(latitude: 34.05223, longitude: -118.24368), // Los Angeles, US/California; GeoNames 5368361
        "san-francisco-us": .init(latitude: 37.77493, longitude: -122.41942), // San Francisco, US/California; GeoNames 5391959
        "seattle-us": .init(latitude: 47.60621, longitude: -122.33207), // Seattle, US/Washington; GeoNames 5809844
        "san-diego-us": .init(latitude: 32.71571, longitude: -117.16472), // San Diego, US/California; GeoNames 5391811
        "toronto-ca": .init(latitude: 43.70643, longitude: -79.39864), // Toronto, CA/Ontario; GeoNames 6167865
        "montreal-ca": .init(latitude: 45.50884, longitude: -73.58781), // Montréal, CA/Quebec; GeoNames 6077243
        "ottawa-ca": .init(latitude: 45.41117, longitude: -75.69812), // Ottawa, CA/Ontario; GeoNames 6094817
        "vancouver-ca": .init(latitude: 49.24966, longitude: -123.11934), // Vancouver, CA/British Columbia; GeoNames 6173331
        "calgary-ca": .init(latitude: 51.05011, longitude: -114.08529), // Calgary, CA/Alberta; GeoNames 5913490
        "mexico-city-mx": .init(latitude: 19.42847, longitude: -99.12766), // Mexico City, MX/Mexico City; GeoNames 3530597
        "guadalajara-mx": .init(latitude: 20.67738, longitude: -103.34749), // Guadalajara, MX/Jalisco; GeoNames 4005539
        "monterrey-mx": .init(latitude: 25.68435, longitude: -100.31721), // Monterrey, MX/Nuevo León; GeoNames 3995465
        "sao-paulo-br": .init(latitude: -23.5475, longitude: -46.63611), // São Paulo, BR/São Paulo; GeoNames 3448439
        "rio-br": .init(latitude: -22.90642, longitude: -43.18223), // Rio de Janeiro, BR/Rio de Janeiro; GeoNames 3451190
        "brasilia-br": .init(latitude: -15.77972, longitude: -47.92972), // Brasília, BR/Federal District; GeoNames 3469058
        "buenos-aires-ar": .init(latitude: -34.61315, longitude: -58.37723), // Buenos Aires, AR/Buenos Aires F.D.; GeoNames 3435910
        "cordoba-ar": .init(latitude: -31.40648, longitude: -64.18853), // Córdoba, AR/Cordoba; GeoNames 3860259
        "santiago-cl": .init(latitude: -33.45694, longitude: -70.64827), // Santiago, CL/Santiago Metropolitan; GeoNames 3871336
        "lima-pe": .init(latitude: -12.04318, longitude: -77.02824), // Lima, PE/Lima Province; GeoNames 3936456
        "bogota-co": .init(latitude: 4.60971, longitude: -74.08175), // Bogotá, CO/Bogota D.C.; GeoNames 3688689
        "medellin-co": .init(latitude: 6.245, longitude: -75.57151), // Medellín, CO/Antioquia; GeoNames 3674962
        "quito-ec": .init(latitude: -0.22985, longitude: -78.52495), // Quito, EC/Pichincha; GeoNames 3652462
        "guayaquil-ec": .init(latitude: -2.19616, longitude: -79.88621), // Guayaquil, EC/Guayas; GeoNames 3657509
        "caracas-ve": .init(latitude: 10.48801, longitude: -66.87919), // Caracas, VE/Distrito Federal; GeoNames 3646738
        "montevideo-uy": .init(latitude: -34.90328, longitude: -56.18816), // Montevideo, UY/Montevideo Department; GeoNames 3441575
        "asuncion-py": .init(latitude: -25.28646, longitude: -57.647), // Asunción, PY/Asuncion; GeoNames 3439389
        "sydney-au": .init(latitude: -33.86785, longitude: 151.20732), // Sydney, AU/New South Wales; GeoNames 2147714
        "melbourne-au": .init(latitude: -37.814, longitude: 144.96332), // Melbourne, AU/Victoria; GeoNames 2158177
        "brisbane-au": .init(latitude: -27.46794, longitude: 153.02809), // Brisbane, AU/Queensland; GeoNames 2174003
        "perth-au": .init(latitude: -31.95224, longitude: 115.8614), // Perth, AU/Western Australia; GeoNames 2063523
        "adelaide-au": .init(latitude: -34.92866, longitude: 138.59863), // Adelaide, AU/South Australia; GeoNames 2078025
        "auckland-nz": .init(latitude: -36.84853, longitude: 174.76349), // Auckland, NZ/Auckland; GeoNames 2193733
        "wellington-nz": .init(latitude: -41.28664, longitude: 174.77557), // Wellington, NZ/Wellington Region; GeoNames 2179537
        "christchurch-nz": .init(latitude: -43.53333, longitude: 172.63333), // Christchurch, NZ/Canterbury; GeoNames 2192362
        "suva-fj": .init(latitude: -18.13683, longitude: 178.42531), // Suva, FJ/Central; GeoNames 2198148
    ]
}
