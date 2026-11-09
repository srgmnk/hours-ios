// Integrated Stage A registry. Original provenance comments below describe the preserved 152-entry baseline; additions have separately pinned GeoNames provenance.
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

        // Stage A proposed additions: GeoNames pinned 2026-11-08; CC BY 4.0.
        "geonames-1797945": .init(latitude: 23.7, longitude: 113.03333), // CN/Guangdong; GeoNames 1797945
        "geonames-1271308": .init(latitude: 28.66535, longitude: 77.43915), // IN/Uttar Pradesh; GeoNames 1271308
        "geonames-499099": .init(latitude: 53.20767, longitude: 50.13553), // RU/Samara Oblast; GeoNames 499099
        "geonames-4409896": .init(latitude: 37.21533, longitude: -93.29824), // US/Missouri; GeoNames 4409896
        "geonames-2653941": .init(latitude: 52.2, longitude: 0.11667), // GB/England; GeoNames 2653941
        "geonames-4250542": .init(latitude: 39.80172, longitude: -89.64371), // US/Illinois; GeoNames 4250542
        "geonames-4931972": .init(latitude: 42.3751, longitude: -71.10561), // US/Massachusetts; GeoNames 4931972
        "geonames-2314302": .init(latitude: -4.32758, longitude: 15.31357), // CD/Kinshasa; GeoNames 2314302
        "geonames-1138958": .init(latitude: 34.52813, longitude: 69.17233), // AF/Kabul; GeoNames 1138958
        "geonames-2460596": .init(latitude: 12.60915, longitude: -7.97522), // ML/Bamako; GeoNames 2460596
        "geonames-1871859": .init(latitude: 39.03385, longitude: 125.75432), // KP/Pyongyang; GeoNames 1871859
        "geonames-2240449": .init(latitude: -8.83682, longitude: 13.23432), // AO/Luanda; GeoNames 2240449
        "geonames-2352778": .init(latitude: 9.05785, longitude: 7.49508), // NG/FCT; GeoNames 2352778
        "geonames-2253354": .init(latitude: 14.6937, longitude: -17.44406), // SN/Dakar; GeoNames 2253354
        "geonames-53654": .init(latitude: 2.03711, longitude: 45.34375), // SO/Banaadir; GeoNames 53654
        "geonames-2357048": .init(latitude: 12.36566, longitude: -1.53388), // BF/Centre; GeoNames 2357048
        "geonames-909137": .init(latitude: -15.40669, longitude: 28.28713), // ZM/Lusaka Province; GeoNames 909137
        "geonames-3492908": .init(latitude: 18.47186, longitude: -69.89232), // DO/Nacional; GeoNames 3492908
        "geonames-2365267": .init(latitude: 6.12874, longitude: 1.22154), // TG/Maritime; GeoNames 2365267
        "geonames-3553478": .init(latitude: 23.13302, longitude: -82.38304), // CU/Havana; GeoNames 3553478
        "geonames-964137": .init(latitude: -25.74486, longitude: 28.18783), // ZA/Gauteng; GeoNames 964137
        "geonames-2260535": .init(latitude: -4.26613, longitude: 15.28318), // CG/Brazzaville; GeoNames 2260535
        "geonames-379252": .init(latitude: 15.55177, longitude: 32.53241), // SD/Khartoum; GeoNames 379252
        "geonames-71137": .init(latitude: 15.35452, longitude: 44.20646), // YE/Amanat Alasimah; GeoNames 71137
        "geonames-2422465": .init(latitude: 9.53795, longitude: -13.67729), // GN/Conakry; GeoNames 2422465
        "geonames-625144": .init(latitude: 53.90019, longitude: 27.56653), // BY/Minsk City; GeoNames 625144
        "geonames-232422": .init(latitude: 0.31628, longitude: 32.58219), // UG/Central Region; GeoNames 232422
        "geonames-2538475": .init(latitude: 34.01325, longitude: -6.83255), // MA/Rabat-Salé-Kénitra; GeoNames 2538475
        "geonames-170654": .init(latitude: 33.5102, longitude: 36.29128), // SY/Damascus Governorate; GeoNames 170654
        "geonames-890299": .init(latitude: -17.82772, longitude: 31.05337), // ZW/Harare; GeoNames 890299
        "geonames-2274895": .init(latitude: 6.30054, longitude: -10.7969), // LR/Montserrado County; GeoNames 2274895
        "geonames-2427123": .init(latitude: 12.10672, longitude: 15.0444), // TD/N’Djaména; GeoNames 2427123
        "geonames-1070940": .init(latitude: -18.91368, longitude: 47.53613), // MG/Analamanga; GeoNames 1070940
        "geonames-2440485": .init(latitude: 13.51366, longitude: 2.1098), // NE/Niamey; GeoNames 2440485
        "geonames-2210247": .init(latitude: 32.88743, longitude: 13.18733), // LY/Tripoli; GeoNames 2210247
        "geonames-2220957": .init(latitude: 3.86667, longitude: 11.51667), // CM/Centre; GeoNames 2220957
        "geonames-792680": .init(latitude: 44.80401, longitude: 20.46513), // RS/Central Serbia; GeoNames 792680
        "geonames-1040652": .init(latitude: -25.96553, longitude: 32.58322), // MZ/Maputo City; GeoNames 1040652
        "geonames-3718426": .init(latitude: 18.54349, longitude: -72.33881), // HT/Ouest; GeoNames 3718426
        "geonames-2377450": .init(latitude: 18.08581, longitude: -15.9785), // MR/no admin1 supplied; GeoNames 2377450
        "geonames-202061": .init(latitude: -1.94995, longitude: 30.05885), // RW/Kigali; GeoNames 202061
        "geonames-927967": .init(latitude: -13.96692, longitude: 33.78725), // MW/Central Region; GeoNames 927967
        "geonames-162183": .init(latitude: 37.95, longitude: 58.38333), // TM/Ashgabat; GeoNames 162183
        "geonames-3598132": .init(latitude: 14.64072, longitude: -90.51327), // GT/Guatemala; GeoNames 3598132
        "geonames-3617763": .init(latitude: 12.13282, longitude: -86.2504), // NI/Managua Department; GeoNames 3617763
        "geonames-3489854": .init(latitude: 17.99702, longitude: -76.79358), // JM/Kingston; GeoNames 3489854
        "geonames-6611854": .init(latitude: 19.745, longitude: 96.12972), // MM/Nay Pyi Taw; GeoNames 6611854
        "geonames-3600949": .init(latitude: 14.0818, longitude: -87.20681), // HN/Francisco Morazán Department; GeoNames 3600949
        "geonames-2399697": .init(latitude: 0.39241, longitude: 9.45356), // GA/Estuaire; GeoNames 2399697
        "geonames-2028462": .init(latitude: 47.90771, longitude: 106.88324), // MN/Ulaanbaatar; GeoNames 2028462
        "geonames-2389853": .init(latitude: 4.36122, longitude: 18.55496), // CF/Bangui; GeoNames 2389853
        "geonames-2409306": .init(latitude: 8.48714, longitude: -13.2356), // SL/Western Area; GeoNames 2409306
        "geonames-160196": .init(latitude: -6.17221, longitude: 35.73947), // TZ/Dodoma; GeoNames 160196
        "geonames-456172": .init(latitude: 56.946, longitude: 24.10589), // LV/Riga; GeoNames 456172
        "geonames-3191281": .init(latitude: 43.84864, longitude: 18.35644), // BA/Federation of B&H; GeoNames 3191281
        "geonames-1221874": .init(latitude: 38.53575, longitude: 68.77905), // TJ/Dushanbe; GeoNames 1221874
        "geonames-3186886": .init(latitude: 45.81444, longitude: 15.97798), // HR/Zagreb; GeoNames 3186886
        "geonames-1821274": .init(latitude: 22.20056, longitude: 113.54611), // MO/no admin1 supplied; GeoNames 1821274
        "geonames-618426": .init(latitude: 47.00902, longitude: 28.85938), // MD/Chișinău Municipality; GeoNames 618426
        "geonames-223817": .init(latitude: 11.58901, longitude: 43.14503), // DJ/Djibouti; GeoNames 223817
        "geonames-1176615": .init(latitude: 33.72148, longitude: 73.04329), // PK/Islamabad; GeoNames 1176615
        "geonames-343300": .init(latitude: 15.33805, longitude: 38.93184), // ER/Maekel; GeoNames 343300
        "geonames-786714": .init(latitude: 42.67272, longitude: 21.16688), // XK/Pristina; GeoNames 786714
        "geonames-593116": .init(latitude: 54.68916, longitude: 25.2798), // LT/Vilnius; GeoNames 593116
        "geonames-3583361": .init(latitude: 13.68935, longitude: -89.18718), // SV/San Salvador Department; GeoNames 3583361
        "geonames-785842": .init(latitude: 41.99646, longitude: 21.43141), // MK/Grad Skopje; GeoNames 785842
        "geonames-373303": .init(latitude: 4.85165, longitude: 31.58247), // SS/Central Equatoria; GeoNames 373303
        "geonames-2374775": .init(latitude: 11.86357, longitude: -15.59767), // GW/Bissau; GeoNames 2374775
        "geonames-3060972": .init(latitude: 48.14816, longitude: 17.10674), // SK/Bratislava Region; GeoNames 3060972
        "geonames-3183875": .init(latitude: 41.32744, longitude: 19.81866), // AL/Tirana; GeoNames 3183875
        "geonames-4568127": .init(latitude: 18.46633, longitude: -66.10572), // PR/San Juan; GeoNames 4568127
        "geonames-3703443": .init(latitude: 8.9936, longitude: -79.51973), // PA/Panamá; GeoNames 3703443
        "geonames-588409": .init(latitude: 59.43696, longitude: 24.75353), // EE/Harjumaa; GeoNames 588409
        "geonames-3352136": .init(latitude: -22.55941, longitude: 17.08323), // NA/Khomas Region; GeoNames 3352136
        "geonames-2172517": .init(latitude: -35.28346, longitude: 149.12807), // AU/Australian Capital Territory; GeoNames 2172517
        "geonames-932505": .init(latitude: -29.31667, longitude: 27.48333), // LS/Maseru District; GeoNames 932505
        "geonames-3621849": .init(latitude: 9.93388, longitude: -84.08489), // CR/San José; GeoNames 3621849
        "geonames-2088122": .init(latitude: -9.47723, longitude: 147.15089), // PG/National Capital; GeoNames 2088122
        "geonames-2279755": .init(latitude: 6.82055, longitude: -5.27674), // CI/Lacs District; GeoNames 2279755
        "geonames-3196359": .init(latitude: 46.05108, longitude: 14.50513), // SI/Ljubljana; GeoNames 3196359
        "geonames-2392087": .init(latitude: 6.49646, longitude: 2.60359), // BJ/Ouémé; GeoNames 2392087
        "geonames-933773": .init(latitude: -24.65451, longitude: 25.90859), // BW/Gaborone; GeoNames 933773
        "geonames-3193044": .init(latitude: 42.44124, longitude: 19.26309), // ME/Podgorica; GeoNames 3193044
        "geonames-3378644": .init(latitude: 6.80448, longitude: -58.15527), // GY/Demerara-Mahaica; GeoNames 3378644
        "geonames-3571824": .init(latitude: 25.05823, longitude: -77.34306), // BS/New Providence; GeoNames 3571824
        "geonames-3903987": .init(latitude: -19.03332, longitude: -65.26274), // BO/Chuquisaca Department; GeoNames 3903987
        "geonames-3383330": .init(latitude: 5.86638, longitude: -55.16682), // SR/Paramaribo District; GeoNames 3383330
        "geonames-146268": .init(latitude: 35.17284, longitude: 33.35397), // CY/Nicosia; GeoNames 146268
        "geonames-934154": .init(latitude: -20.16194, longitude: 57.49889), // MU/Port Louis; GeoNames 934154
        "geonames-935264": .init(latitude: -20.88231, longitude: 55.4504), // RE/Reunion; GeoNames 935264
        "geonames-1645457": .init(latitude: -8.55861, longitude: 125.57361), // TL/Dili Municipality; GeoNames 1645457
        "geonames-290340": .init(latitude: 26.22787, longitude: 50.58565), // BH/Manama; GeoNames 290340
        "geonames-3374333": .init(latitude: 14.93152, longitude: -23.51254), // CV/Praia; GeoNames 3374333
        "geonames-3513090": .init(latitude: 12.12246, longitude: -68.88641), // CW/no admin1 supplied; GeoNames 3513090
        "geonames-2661552": .init(latitude: 46.94809, longitude: 7.44744), // CH/Bern; GeoNames 2661552
        "geonames-1282027": .init(latitude: 4.17521, longitude: 73.50916), // MV/Kaafu Atoll; GeoNames 1282027
        "geonames-1252416": .init(latitude: 27.46609, longitude: 89.64191), // BT/Thimphu District; GeoNames 1252416
        "geonames-3374036": .init(latitude: 13.10732, longitude: -59.62021), // BB/Saint Michael; GeoNames 3374036
        "geonames-2139521": .init(latitude: -22.27407, longitude: 166.44884), // NC/South Province; GeoNames 2139521
        "geonames-3570675": .init(latitude: 14.60365, longitude: -61.07418), // MQ/Martinique; GeoNames 3570675
        "geonames-2960316": .init(latitude: 49.60982, longitude: 6.13268), // LU/Luxembourg; GeoNames 2960316
        "geonames-934985": .init(latitude: -26.31667, longitude: 31.13333), // SZ/Hhohho Region; GeoNames 934985
        "geonames-921772": .init(latitude: -11.70216, longitude: 43.25506), // KM/Grande Comore; GeoNames 921772
        "geonames-426272": .init(latitude: -3.42708, longitude: 29.92463), // BI/Gitega; GeoNames 426272
        "geonames-1820906": .init(latitude: 4.89035, longitude: 114.94006), // BN/Brunei-Muara District; GeoNames 1820906
        "geonames-3382160": .init(latitude: 4.9381, longitude: -52.33455), // GF/Guyane; GeoNames 3382160
        "geonames-285787": .init(latitude: 29.367, longitude: 47.97429), // KW/Al Asimah; GeoNames 285787
        "geonames-2108502": .init(latitude: -9.43333, longitude: 159.95), // SB/Honiara; GeoNames 2108502
        "geonames-921815": .init(latitude: -12.78234, longitude: 45.22878), // YT/Mamoudzou; GeoNames 921815
        "geonames-2410763": .init(latitude: 0.33756, longitude: 6.7299), // ST/São Tomé Island; GeoNames 2410763
        "geonames-3576022": .init(latitude: 17.12096, longitude: -61.84329), // AG/Saint John Parish; GeoNames 3576022
        "geonames-3573890": .init(latitude: 10.66668, longitude: -61.51889), // TT/Port of Spain; GeoNames 3573890
        "geonames-7828758": .init(latitude: 15.21233, longitude: 145.7545), // MP/Saipan; GeoNames 7828758
        "geonames-4035413": .init(latitude: -13.83333, longitude: -171.76666), // WS/Tuamasaga; GeoNames 4035413
        "geonames-2110257": .init(latitude: 1.3278, longitude: 172.97696), // KI/Gilbert Islands; GeoNames 2110257
        "geonames-2413876": .init(latitude: 13.45274, longitude: -16.57803), // GM/Banjul; GeoNames 2413876
        "geonames-2135171": .init(latitude: -17.73648, longitude: 168.31366), // VU/Shefa; GeoNames 2135171
        "geonames-2993458": .init(latitude: 43.73718, longitude: 7.42145), // MC/Municipality of Monaco; GeoNames 2993458
        "geonames-3577154": .init(latitude: 12.52398, longitude: -70.02703), // AW/no admin1 supplied; GeoNames 3577154
        "geonames-3580661": .init(latitude: 19.2866, longitude: -81.37436), // KY/George Town; GeoNames 3580661
        "geonames-3042091": .init(latitude: 49.18804, longitude: -2.10491), // JE/St Helier; GeoNames 3042091
        "geonames-2411585": .init(latitude: 36.14474, longitude: -5.35257), // GI/no admin1 supplied; GeoNames 2411585
        "geonames-4033936": .init(latitude: -17.5347, longitude: -149.56843), // PF/Îles du Vent; GeoNames 4033936
        "geonames-3042237": .init(latitude: 54.15, longitude: -4.48333), // IM/Douglas; GeoNames 3042237
        "geonames-2113779": .init(latitude: 7.08971, longitude: 171.38027), // MH/Majuro Atoll; GeoNames 2113779
        "geonames-3577887": .init(latitude: 13.15527, longitude: -61.22742), // VC/Saint George Parish; GeoNames 3577887
        "geonames-241131": .init(latitude: -4.62001, longitude: 55.45501), // SC/La Rivière Anglaise; GeoNames 241131
        "geonames-4032402": .init(latitude: -21.13683, longitude: -175.20114), // TO/Tongatapu; GeoNames 4032402
        "geonames-3041563": .init(latitude: 42.50779, longitude: 1.52109), // AD/Andorra la Vella; GeoNames 3041563
        "geonames-3576812": .init(latitude: 13.9957, longitude: -61.00614), // LC/Castries; GeoNames 3576812
        "geonames-4795467": .init(latitude: 18.3419, longitude: -64.9307), // VI/Saint Thomas Island; GeoNames 4795467
        "geonames-3575635": .init(latitude: 15.30174, longitude: -61.38808), // DM/Saint George Parish; GeoNames 3575635
        "geonames-3042287": .init(latitude: 49.45981, longitude: -2.53527), // GG/St Peter Port; GeoNames 3042287
        "geonames-3421319": .init(latitude: 64.18347, longitude: -51.72157), // GL/Sermersooq; GeoNames 3421319
        "geonames-3582672": .init(latitude: 17.25376, longitude: -88.76401), // BZ/Cayo District; GeoNames 3582672
        "geonames-4035715": .init(latitude: -21.2075, longitude: -159.77546), // CK/Rarotonga; GeoNames 4035715
        "geonames-2611396": .init(latitude: 62.00973, longitude: -6.77164), // FO/Streymoy; GeoNames 2611396
        "geonames-3575551": .init(latitude: 17.2955, longitude: -62.72499), // KN/Saint George Basseterre; GeoNames 3575551
        "geonames-5881576": .init(latitude: -14.27806, longitude: -170.7025), // AS/Eastern District; GeoNames 5881576
        "geonames-3579732": .init(latitude: 15.99714, longitude: -61.73214), // GP/Guadeloupe; GeoNames 3579732
        "geonames-3041732": .init(latitude: 60.09726, longitude: 19.93481), // AX/Mariehamn; GeoNames 3041732
        "geonames-3513563": .init(latitude: 12.15, longitude: -68.26667), // BQ/Bonaire; GeoNames 3513563
        "geonames-3577430": .init(latitude: 18.42693, longitude: -64.62079), // VG/no admin1 supplied; GeoNames 3577430
        "geonames-3579925": .init(latitude: 12.05288, longitude: -61.75226), // GD/Saint George Parish; GeoNames 3579925
        "geonames-2081986": .init(latitude: 6.92477, longitude: 158.16109), // FM/Pohnpei State; GeoNames 2081986
        "geonames-2562305": .init(latitude: 35.89968, longitude: 14.5148), // MT/Valletta; GeoNames 2562305
        "geonames-2110394": .init(latitude: -8.52425, longitude: 179.19417), // TV/Funafuti; GeoNames 2110394
        "geonames-3424934": .init(latitude: 46.77914, longitude: -56.1773), // PM/Saint-Pierre; GeoNames 3424934
        "geonames-3579132": .init(latitude: 17.89618, longitude: -62.84978), // BL/no admin1 supplied; GeoNames 3579132
        "geonames-3578851": .init(latitude: 18.06819, longitude: -63.08302), // MF/no admin1 supplied; GeoNames 3578851
        "geonames-3042030": .init(latitude: 47.14151, longitude: 9.52154), // LI/Vaduz; GeoNames 3042030
        "geonames-3168070": .init(latitude: 43.93667, longitude: 12.44639), // SM/San Marino; GeoNames 3168070
        "geonames-3576994": .init(latitude: 21.46122, longitude: -71.14188), // TC/no admin1 supplied; GeoNames 3576994
        "geonames-2729907": .init(latitude: 78.22334, longitude: 15.64689), // SJ/Svalbard; GeoNames 2729907
        "geonames-3426691": .init(latitude: -51.69382, longitude: -57.85701), // FK/no admin1 supplied; GeoNames 3426691
        "geonames-3573374": .init(latitude: 18.21704, longitude: -63.05783), // AI/The Valley; GeoNames 3573374
        "geonames-12226438": .init(latitude: 1.5925, longitude: 10.82361), // GQ/Djibloho; GeoNames 12226438
        "geonames-3513392": .init(latitude: 18.026, longitude: -63.04582), // SX/no admin1 supplied; GeoNames 3513392
        "geonames-2078127": .init(latitude: -10.42172, longitude: 105.67912), // CX/no admin1 supplied; GeoNames 2078127
        "geonames-4034821": .init(latitude: -13.28163, longitude: -176.17453), // WF/Uvea; GeoNames 4034821
        "geonames-7626461": .init(latitude: -0.55085, longitude: 166.9252), // NR/Yaren District; GeoNames 7626461
        "geonames-4044012": .init(latitude: 13.47567, longitude: 144.74886), // GU/Hagatna; GeoNames 4044012
        "geonames-3573197": .init(latitude: 32.2949, longitude: -64.78303), // BM/Hamilton city; GeoNames 3573197
        "geonames-2161314": .init(latitude: -29.05459, longitude: 167.96628), // NF/no admin1 supplied; GeoNames 2161314
        "geonames-6691831": .init(latitude: 41.90268, longitude: 12.45414), // VA/no admin1 supplied; GeoNames 6691831
        "geonames-3370903": .init(latitude: -15.92488, longitude: -5.71816), // SH/Saint Helena; GeoNames 3370903
        "geonames-4036284": .init(latitude: -19.05294, longitude: -169.91957), // NU/no admin1 supplied; GeoNames 4036284
        "geonames-7304591": .init(latitude: -12.15681, longitude: 96.82251), // CC/no admin1 supplied; GeoNames 7304591
        "geonames-4030723": .init(latitude: -25.06597, longitude: -130.10147), // PN/no admin1 supplied; GeoNames 4030723
        "geonames-1546102": .init(latitude: -49.34916, longitude: 70.21937), // TF/Kerguelen; GeoNames 1546102
        "geonames-3426466": .init(latitude: -54.28111, longitude: -36.5092), // GS/no admin1 supplied; GeoNames 3426466
        "geonames-3578069": .init(latitude: 16.70555, longitude: -62.21292), // MS/Saint Anthony; GeoNames 3578069
        "geonames-8063361": .init(latitude: 7.50077, longitude: 134.6238), // PW/Melekeok; GeoNames 8063361
        "geonames-1815286": .init(latitude: 30.66667, longitude: 104.06667), // CN/Sichuan; GeoNames 1815286
        "geonames-1886760": .init(latitude: 31.30408, longitude: 120.59538), // CN/Jiangsu; GeoNames 1886760
        "geonames-1804651": .init(latitude: 25.03889, longitude: 102.71833), // CN/Yunnan; GeoNames 1804651
        "geonames-1790645": .init(latitude: 24.47979, longitude: 118.08187), // CN/Fujian; GeoNames 1790645
        "geonames-1205733": .init(latitude: 22.3384, longitude: 91.83168), // BD/Chittagong; GeoNames 1205733
        "geonames-1269515": .init(latitude: 26.91962, longitude: 75.78781), // IN/Rajasthan; GeoNames 1269515
        "geonames-2298890": .init(latitude: 6.68848, longitude: -1.62443), // GH/Ashanti; GeoNames 2298890
        "geonames-1650357": .init(latitude: -6.92222, longitude: 107.60694), // ID/West Java; GeoNames 1650357
        "geonames-2324774": .init(latitude: 4.77742, longitude: 7.0134), // NG/Rivers State; GeoNames 2324774
        "geonames-1715348": .init(latitude: 7.07306, longitude: 125.61278), // PH/Davao Region; GeoNames 1715348
        "geonames-292672": .init(latitude: 25.3342, longitude: 55.41221), // AE/Sharjah; GeoNames 292672
        "geonames-1809498": .init(latitude: 25.28022, longitude: 110.29639), // CN/Guangxi; GeoNames 1809498
        "geonames-1622786": .init(latitude: -5.14861, longitude: 119.43194), // ID/South Sulawesi; GeoNames 1622786
        "geonames-1857910": .init(latitude: 35.02107, longitude: 135.75385), // JP/Kyoto; GeoNames 1857910
        "geonames-1279259": .init(latitude: 27.18333, longitude: 78.01667), // IN/Uttar Pradesh; GeoNames 1279259
        "geonames-1580240": .init(latitude: 16.4619, longitude: 107.59546), // VN/Thừa Thiên Huế Province; GeoNames 1580240
        "geonames-323777": .init(latitude: 36.90812, longitude: 30.69556), // TR/Antalya; GeoNames 323777
        "geonames-109223": .init(latitude: 24.46861, longitude: 39.61417), // SA/Medina Region; GeoNames 109223
        "geonames-1583992": .init(latitude: 16.06778, longitude: 108.22083), // VN/Da Nang City; GeoNames 1583992
        "geonames-110336": .init(latitude: 26.43442, longitude: 50.10326), // SA/Eastern Province; GeoNames 110336
        "geonames-551487": .init(latitude: 55.78874, longitude: 49.12214), // RU/Tatarstan Republic; GeoNames 551487
        "geonames-186301": .init(latitude: -4.05466, longitude: 39.66359), // KE/Mombasa County; GeoNames 186301
        "geonames-1311874": .init(latitude: 21.97473, longitude: 96.08359), // MM/Mandalay Region; GeoNames 1311874
        "geonames-3523349": .init(latitude: 20.967, longitude: -89.62318), // MX/Yucatán; GeoNames 3523349
        "geonames-3947322": .init(latitude: -16.39899, longitude: -71.53747), // PE/Arequipa; GeoNames 3947322
        "geonames-2548885": .init(latitude: 34.03313, longitude: -5.00028), // MA/Fes-Meknes; GeoNames 2548885
        "geonames-1253405": .init(latitude: 25.31668, longitude: 83.01041), // IN/Uttar Pradesh; GeoNames 1253405
        "geonames-1278710": .init(latitude: 31.62234, longitude: 74.87534), // IN/Punjab; GeoNames 1278710
        "geonames-1268865": .init(latitude: 26.26841, longitude: 73.00594), // IN/Rajasthan; GeoNames 1268865
        "geonames-964420": .init(latitude: -33.96109, longitude: 25.61494), // ZA/Eastern Cape; GeoNames 964420
        "geonames-2530335": .init(latitude: 35.76727, longitude: -5.79975), // MA/Tanger-Tetouan-Al Hoceima; GeoNames 2530335
        "geonames-1796556": .init(latitude: 18.25435, longitude: 109.50947), // CN/Hainan; GeoNames 1796556
        "geonames-2542997": .init(latitude: 31.63416, longitude: -7.99994), // MA/Marrakesh-Safi; GeoNames 2542997
        "geonames-3687238": .init(latitude: 10.39817, longitude: -75.49328), // CO/Bolívar; GeoNames 3687238
        "geonames-3531673": .init(latitude: 21.17429, longitude: -86.84656), // MX/Quintana Roo; GeoNames 3531673
        "geonames-1280737": .init(latitude: 29.65, longitude: 91.1), // CN/Tibet; GeoNames 1280737
        "geonames-292913": .init(latitude: 24.19167, longitude: 55.76056), // AE/Abu Dhabi; GeoNames 292913
        "geonames-148730": .init(latitude: -6.16394, longitude: 39.19793), // TZ/Zanzibar Urban/West; GeoNames 148730
        "geonames-2561668": .init(latitude: 30.42018, longitude: -9.59815), // MA/Souss-Massa; GeoNames 2561668
        "geonames-1645528": .init(latitude: -8.65, longitude: 115.21667), // ID/Bali; GeoNames 1645528
        "geonames-1259425": .init(latitude: 11.93381, longitude: 79.82979), // IN/Puducherry; GeoNames 1259425
        "geonames-2523920": .init(latitude: 38.1166, longitude: 13.3636), // IT/Sicily; GeoNames 2523920
        "geonames-3658666": .init(latitude: -2.8953, longitude: -78.9963), // EC/Azuay; GeoNames 3658666
        "geonames-1273874": .init(latitude: 9.93988, longitude: 76.26022), // IN/Kerala; GeoNames 1273874
        "geonames-2023469": .init(latitude: 52.29566, longitude: 104.29076), // RU/Irkutsk Oblast; GeoNames 2023469
        "geonames-161325": .init(latitude: -3.36667, longitude: 36.68333), // TZ/Arusha; GeoNames 161325
        "geonames-2711537": .init(latitude: 57.70716, longitude: 11.96679), // SE/Västra Götaland; GeoNames 2711537
        "geonames-1282898": .init(latitude: 28.26689, longitude: 83.96851), // NP/Gandaki Pradesh; GeoNames 1282898
        "geonames-1216265": .init(latitude: 39.65456, longitude: 66.96445), // UZ/Samarqand Region; GeoNames 1216265
        "geonames-2514256": .init(latitude: 36.72016, longitude: -4.42034), // ES/Andalusia; GeoNames 2514256
        "geonames-1572151": .init(latitude: 12.24507, longitude: 109.19432), // VN/Khanh Hoa; GeoNames 1572151
        "geonames-1734759": .init(latitude: 2.196, longitude: 102.2405), // MY/Melaka; GeoNames 1734759
        "geonames-3536729": .init(latitude: 20.02287, longitude: -75.82171), // CU/Santiago de Cuba Province; GeoNames 3536729
        "geonames-6325494": .init(latitude: 46.81228, longitude: -71.21454), // CA/Quebec; GeoNames 6325494
        "geonames-2803138": .init(latitude: 51.22047, longitude: 4.40026), // BE/Flanders; GeoNames 2803138
        "geonames-2972315": .init(latitude: 43.60426, longitude: 1.44367), // FR/Occitanie; GeoNames 2972315
        "geonames-3463237": .init(latitude: -27.59667, longitude: -48.54917), // BR/Santa Catarina; GeoNames 3463237
        "geonames-2155472": .init(latitude: -32.92953, longitude: 151.7801), // AU/New South Wales; GeoNames 2155472
        "geonames-1733432": .init(latitude: 5.9749, longitude: 116.0724), // MY/Sabah; GeoNames 1733432
        "geonames-1846266": .init(latitude: 33.50972, longitude: 126.52194), // KR/Jeju-do; GeoNames 1846266
        "geonames-3099434": .init(latitude: 54.35227, longitude: 18.64912), // PL/Pomerania; GeoNames 3099434
        "geonames-554234": .init(latitude: 54.70639, longitude: 20.51102), // RU/Kaliningrad Oblast; GeoNames 554234
        "geonames-1711005": .init(latitude: 10.69694, longitude: 122.56444), // PH/Western Visayas; GeoNames 1711005
        "geonames-6324729": .init(latitude: 44.64269, longitude: -63.57688), // CA/Nova Scotia; GeoNames 6324729
        "geonames-1860243": .init(latitude: 36.6, longitude: 136.61667), // JP/Ishikawa; GeoNames 1860243
        "geonames-336014": .init(latitude: 12.6, longitude: 37.46667), // ET/Amhara; GeoNames 336014
        "geonames-1636544": .init(latitude: 1.48218, longitude: 124.84892), // ID/North Sulawesi; GeoNames 1636544
        "geonames-1253986": .init(latitude: 24.58584, longitude: 73.71346), // IN/Rajasthan; GeoNames 1253986
        "geonames-1635882": .init(latitude: -8.58333, longitude: 116.11667), // ID/West Nusa Tenggara; GeoNames 1635882
        "geonames-2512989": .init(latitude: 39.56939, longitude: 2.65024), // ES/Balearic Islands; GeoNames 2512989
        "geonames-3941584": .init(latitude: -13.53188, longitude: -71.96701), // PE/Cuzco Department; GeoNames 3941584
        "geonames-360502": .init(latitude: 25.69893, longitude: 32.6421), // EG/Luxor; GeoNames 360502
        "geonames-1856177": .init(latitude: 32.75, longitude: 129.88333), // JP/Nagasaki; GeoNames 1856177
        "geonames-3078610": .init(latitude: 49.19522, longitude: 16.60796), // CZ/South Moravian; GeoNames 3078610
        "geonames-1735634": .init(latitude: 1.55, longitude: 110.33333), // MY/Sarawak; GeoNames 1735634
        "geonames-3181928": .init(latitude: 44.49381, longitude: 11.33875), // IT/Emilia-Romagna; GeoNames 3181928
        "geonames-359792": .init(latitude: 24.09082, longitude: 32.89942), // EG/Aswan; GeoNames 359792
        "geonames-3696183": .init(latitude: -3.74814, longitude: -73.2529), // PE/Loreto; GeoNames 3696183
        "geonames-1621177": .init(latitude: -7.80139, longitude: 110.36472), // ID/Yogyakarta; GeoNames 1621177
        "geonames-1855612": .init(latitude: 34.68505, longitude: 135.80485), // JP/Nara; GeoNames 1855612
        "geonames-3176959": .init(latitude: 43.77925, longitude: 11.24626), // IT/Tuscany; GeoNames 3176959
        "geonames-2692969": .init(latitude: 55.60587, longitude: 13.00073), // SE/Skåne; GeoNames 2692969
        "geonames-5856195": .init(latitude: 21.30694, longitude: -157.85833), // US/Hawaii; GeoNames 5856195
        "geonames-2521978": .init(latitude: 38.34517, longitude: -0.48149), // ES/Valencia; GeoNames 2521978
        "geonames-3128026": .init(latitude: 43.26271, longitude: -2.92528), // ES/Basque Country; GeoNames 3128026
        "geonames-2990440": .init(latitude: 43.70313, longitude: 7.26608), // FR/Provence-Alpes-Côte d'Azur; GeoNames 2990440
        "geonames-491422": .init(latitude: 43.59699, longitude: 39.72477), // RU/Krasnodar Krai; GeoNames 491422
        "geonames-1856035": .init(latitude: 26.213, longitude: 127.67851), // JP/Okinawa; GeoNames 1856035
        "geonames-2525068": .init(latitude: 37.49223, longitude: 15.07041), // IT/Sicily; GeoNames 2525068
        "geonames-3463030": .init(latitude: -25.54778, longitude: -54.58806), // BR/Paraná; GeoNames 3463030
        "geonames-524305": .init(latitude: 68.96778, longitude: 33.09922), // RU/Murmansk; GeoNames 524305
        "geonames-3161732": .init(latitude: 60.39299, longitude: 5.32415), // NO/Vestland; GeoNames 3161732
        "geonames-6174041": .init(latitude: 48.4359, longitude: -123.35155), // CA/British Columbia; GeoNames 6174041
        "geonames-5879400": .init(latitude: 61.21806, longitude: -149.90028), // US/Alaska; GeoNames 5879400
        "geonames-681290": .init(latitude: 46.76667, longitude: 23.6), // RO/Cluj County; GeoNames 681290
        "geonames-2624652": .init(latitude: 56.15674, longitude: 10.21076), // DK/Central Jutland; GeoNames 2624652
        "geonames-2654710": .init(latitude: 50.82838, longitude: -0.13947), // GB/England; GeoNames 2654710
        "geonames-1217662": .init(latitude: 39.77026, longitude: 64.43069), // UZ/Bukhara; GeoNames 1217662
        "geonames-2130188": .init(latitude: 41.77583, longitude: 140.73667), // JP/Hokkaido; GeoNames 2130188
        "geonames-2973783": .init(latitude: 48.58392, longitude: 7.74553), // FR/Grand Est; GeoNames 2973783
        "geonames-1728930": .init(latitude: 16.41639, longitude: 120.59306), // PH/Cordillera; GeoNames 1728930
        "geonames-3031582": .init(latitude: 44.84124, longitude: -0.58046), // FR/New Aquitaine; GeoNames 3031582
        "geonames-2797656": .init(latitude: 51.05, longitude: 3.71667), // BE/Flanders; GeoNames 2797656
        "geonames-634963": .init(latitude: 61.49911, longitude: 23.78712), // FI/Pirkanmaa; GeoNames 634963
        "geonames-3164527": .init(latitude: 45.43854, longitude: 10.9938), // IT/Veneto; GeoNames 3164527
        "geonames-1584071": .init(latitude: 11.94646, longitude: 108.44193), // VN/Lam Dong; GeoNames 1584071
        "geonames-3522507": .init(latitude: 17.06025, longitude: -96.72544), // MX/Oaxaca; GeoNames 3522507
        "geonames-2163355": .init(latitude: -42.87936, longitude: 147.32941), // AU/Tasmania; GeoNames 2163355
        "geonames-2246452": .init(latitude: 16.01793, longitude: -16.48962), // SN/Saint-Louis; GeoNames 2246452
        "geonames-3874960": .init(latitude: -41.4693, longitude: -72.94237), // CL/Los Lagos Region; GeoNames 3874960
        "geonames-1841603": .init(latitude: 35.84278, longitude: 129.21167), // KR/Gyeongsangbuk-do; GeoNames 1841603
        "geonames-738648": .init(latitude: 41.005, longitude: 39.72694), // TR/Trabzon; GeoNames 738648
        "geonames-2998324": .init(latitude: 50.63391, longitude: 3.05512), // FR/Hauts-de-France; GeoNames 2998324
        "geonames-1814093": .init(latitude: 25.58474, longitude: 100.21229), // CN/Yunnan; GeoNames 1814093
        "geonames-2517117": .init(latitude: 37.18817, longitude: -3.60667), // ES/Andalusia; GeoNames 2517117
        "geonames-3991328": .init(latitude: 20.617, longitude: -105.23018), // MX/Jalisco; GeoNames 3991328
        "geonames-2965140": .init(latitude: 51.89797, longitude: -8.47061), // IE/Munster; GeoNames 2965140
        "geonames-1692685": .init(latitude: 9.73917, longitude: 118.73528), // PH/Mimaropa; GeoNames 1692685
        "geonames-2464915": .init(latitude: 35.82539, longitude: 10.63699), // TN/Sousse Governorate; GeoNames 2464915
        "geonames-643492": .init(latitude: 65.01236, longitude: 25.46816), // FI/North Ostrobothnia; GeoNames 643492
        "geonames-1813253": .init(latitude: 26.86879, longitude: 100.22072), // CN/Yunnan; GeoNames 1813253
        "geonames-361291": .init(latitude: 27.25738, longitude: 33.81291), // EG/Red Sea; GeoNames 361291
        "geonames-633679": .init(latitude: 60.45148, longitude: 22.26869), // FI/Southwest Finland; GeoNames 633679
        "geonames-2146142": .init(latitude: -19.26639, longitude: 146.80569), // AU/Queensland; GeoNames 2146142
        "geonames-2657832": .init(latitude: 57.14369, longitude: -2.09814), // GB/Scotland; GeoNames 2657832
        "geonames-1638868": .init(latitude: -8.4964, longitude: 119.8877), // ID/East Nusa Tenggara; GeoNames 1638868
        "geonames-1002145": .init(latitude: -33.963, longitude: 22.46173), // ZA/Western Cape; GeoNames 1002145
        "geonames-615532": .init(latitude: 41.64077, longitude: 41.6306), // GE/Adjara; GeoNames 615532
        "geonames-3110044": .init(latitude: 43.31283, longitude: -1.97499), // ES/Basque Country; GeoNames 3110044
        "geonames-2615876": .init(latitude: 55.39594, longitude: 10.38831), // DK/South Denmark; GeoNames 2615876
        "geonames-910111": .init(latitude: -17.84194, longitude: 25.85425), // ZM/Southern Province; GeoNames 910111
        "geonames-3985344": .init(latitude: 20.91528, longitude: -100.74389), // MX/Guanajuato; GeoNames 3985344
        "geonames-1860672": .init(latitude: 35.31085, longitude: 139.54698), // JP/Kanagawa; GeoNames 1860672
        "geonames-286621": .init(latitude: 17.01505, longitude: 54.09237), // OM/Dhofar; GeoNames 286621
        "geonames-2640729": .init(latitude: 51.75222, longitude: -1.25596), // GB/England; GeoNames 2640729
        "geonames-3014728": .init(latitude: 45.17869, longitude: 5.71479), // FR/Auvergne-Rhône-Alpes; GeoNames 3014728
        "geonames-1735106": .init(latitude: 5.41123, longitude: 100.33543), // MY/Penang; GeoNames 1735106
        "geonames-2766824": .init(latitude: 47.79941, longitude: 13.04399), // AT/Salzburg; GeoNames 2766824
        "geonames-2633352": .init(latitude: 53.95763, longitude: -1.08271), // GB/England; GeoNames 2633352
        "geonames-2172797": .init(latitude: -16.92366, longitude: 145.76613), // AU/Queensland; GeoNames 2172797
        "geonames-3137115": .init(latitude: 58.97005, longitude: 5.73332), // NO/Rogaland; GeoNames 3137115
        "geonames-3521342": .init(latitude: 20.6274, longitude: -87.07987), // MX/Quintana Roo; GeoNames 3521342
        "geonames-3190261": .init(latitude: 43.50891, longitude: 16.43915), // HR/Split-Dalmatia; GeoNames 3190261
        "geonames-4221552": .init(latitude: 32.08354, longitude: -81.09983), // US/Georgia; GeoNames 4221552
        "geonames-610612": .init(latitude: 43.66105, longitude: 51.17392), // KZ/Mangystau; GeoNames 610612
        "geonames-3038354": .init(latitude: 43.5283, longitude: 5.44973), // FR/Provence-Alpes-Côte d'Azur; GeoNames 3038354
        "geonames-3493175": .init(latitude: 19.79344, longitude: -70.6884), // DO/Puerto Plata; GeoNames 3493175
        "geonames-5990579": .init(latitude: 49.88307, longitude: -119.48568), // CA/British Columbia; GeoNames 5990579
        "geonames-2073124": .init(latitude: -12.46113, longitude: 130.84185), // AU/Northern Territory; GeoNames 2073124
        "geonames-1822214": .init(latitude: 13.36179, longitude: 103.86056), // KH/Siem Reap; GeoNames 1822214
        "geonames-2659994": .init(latitude: 46.516, longitude: 6.63282), // CH/Vaud; GeoNames 2659994
        "geonames-261745": .init(latitude: 35.32787, longitude: 25.14341), // GR/Crete; GeoNames 261745
        "geonames-2191562": .init(latitude: -45.87416, longitude: 170.50361), // NZ/Otago; GeoNames 2191562
        "geonames-4574324": .init(latitude: 32.77632, longitude: -79.93275), // US/South Carolina; GeoNames 4574324
        "geonames-2775220": .init(latitude: 47.26266, longitude: 11.39454), // AT/Tyrol; GeoNames 2775220
        "geonames-1153269": .init(latitude: 12.57065, longitude: 99.95876), // TH/Prachuap Khiri Khan; GeoNames 1153269
        "geonames-3182164": .init(latitude: 45.69601, longitude: 9.66721), // IT/Lombardy; GeoNames 3182164
        "geonames-2800931": .init(latitude: 51.20892, longitude: 3.22424), // BE/Flanders; GeoNames 2800931
        "geonames-3874787": .init(latitude: -53.16282, longitude: -70.90922), // CL/Region of Magallanes; GeoNames 3874787
        "geonames-1614295": .init(latitude: 12.93333, longitude: 100.88333), // TH/Chon Buri; GeoNames 1614295
        "geonames-3844421": .init(latitude: -32.88946, longitude: -68.84582), // AR/Mendoza; GeoNames 3844421
        "geonames-1241622": .init(latitude: 7.2906, longitude: 80.6336), // LK/Central Province; GeoNames 1241622
        "geonames-3170647": .init(latitude: 43.70853, longitude: 10.4036), // IT/Tuscany; GeoNames 3170647
        "geonames-5574991": .init(latitude: 40.01499, longitude: -105.27055), // US/Colorado; GeoNames 5574991
        "geonames-2267827": .init(latitude: 32.66568, longitude: -16.92547), // PT/Madeira; GeoNames 2267827
        "geonames-233508": .init(latitude: 0.05621, longitude: 32.47949), // UG/Central Region; GeoNames 233508
        "geonames-2656173": .init(latitude: 51.3751, longitude: -2.36172), // GB/England; GeoNames 2656173
        "geonames-3109642": .init(latitude: 42.88052, longitude: -8.54569), // ES/Galicia; GeoNames 3109642
        "geonames-1674504": .init(latitude: 23.97694, longitude: 121.60444), // TW/Taiwan; GeoNames 1674504
        "geonames-3361025": .init(latitude: -33.93462, longitude: 18.86676), // ZA/Western Cape; GeoNames 3361025
        "geonames-7647007": .init(latitude: -41.14557, longitude: -71.30822), // AR/Rio Negro; GeoNames 7647007
        "geonames-250774": .init(latitude: 29.52667, longitude: 35.00778), // JO/Aqaba; GeoNames 250774
        "geonames-1246294": .init(latitude: 6.0461, longitude: 80.2103), // LK/Southern Province; GeoNames 1246294
        "geonames-5392952": .init(latitude: 34.42083, longitude: -119.69819), // US/California; GeoNames 5392952
        "geonames-2160517": .init(latitude: -41.43876, longitude: 147.13467), // AU/Tasmania; GeoNames 2160517
        "geonames-3035681": .init(latitude: 43.94834, longitude: 4.80892), // FR/Provence-Alpes-Côte d'Azur; GeoNames 3035681
        "geonames-1850892": .init(latitude: 36.13333, longitude: 137.25), // JP/Gifu; GeoNames 1850892
        "geonames-5490263": .init(latitude: 35.68698, longitude: -105.9378), // US/New Mexico; GeoNames 5490263
        "geonames-2964180": .init(latitude: 53.27245, longitude: -9.05095), // IE/Connacht; GeoNames 2964180
        "geonames-933366": .init(latitude: -19.98333, longitude: 23.41667), // BW/North-West; GeoNames 933366
        "geonames-1528121": .init(latitude: 42.49047, longitude: 78.39197), // KG/Issyk-Kul; GeoNames 1528121
        "geonames-3711668": .init(latitude: 8.42729, longitude: -82.43085), // PA/Chiriquí Province; GeoNames 3711668
        "geonames-3489460": .init(latitude: 18.47116, longitude: -77.91883), // JM/Saint James Parish; GeoNames 3489460
        "geonames-2659811": .init(latitude: 47.05048, longitude: 8.30635), // CH/Lucerne; GeoNames 2659811
        "geonames-3174953": .init(latitude: 40.35481, longitude: 18.17244), // IT/Apulia; GeoNames 3174953
        "geonames-5376095": .init(latitude: 38.29714, longitude: -122.28553), // US/California; GeoNames 5376095
        "geonames-1151254": .init(latitude: 7.89059, longitude: 98.3981), // TH/Phuket; GeoNames 1151254
        "geonames-1153669": .init(latitude: 19.90858, longitude: 99.8325), // TH/Chiang Rai; GeoNames 1153669
        "geonames-3455671": .init(latitude: -20.39484, longitude: -43.50517), // BR/Minas Gerais; GeoNames 3455671
        "geonames-1622846": .init(latitude: -8.5098, longitude: 115.2654), // ID/Bali; GeoNames 1622846
        "geonames-3028808": .init(latitude: 43.55135, longitude: 7.01275), // FR/Provence-Alpes-Côte d'Azur; GeoNames 3028808
        "geonames-3359638": .init(latitude: -22.9575, longitude: 14.50528), // NA/Erongo Region; GeoNames 3359638
        "geonames-1260607": .init(latitude: 15.49574, longitude: 73.82624), // IN/Goa; GeoNames 1260607
        "geonames-2268339": .init(latitude: 37.01869, longitude: -7.92716), // PT/Faro; GeoNames 2268339
        "geonames-1269507": .init(latitude: 26.91763, longitude: 70.90387), // IN/Rajasthan; GeoNames 1269507
        "geonames-2186313": .init(latitude: -39.4926, longitude: 176.91233), // NZ/Hawke's Bay Region; GeoNames 2186313
        "geonames-1258128": .init(latitude: 30.10778, longitude: 78.29255), // IN/Uttarakhand; GeoNames 1258128
        "geonames-6241325": .init(latitude: -38.13874, longitude: 176.24516), // NZ/Bay of Plenty; GeoNames 6241325
        "geonames-2659836": .init(latitude: 46.01008, longitude: 8.96004), // CH/Ticino; GeoNames 2659836
        "geonames-314967": .init(latitude: 36.64038, longitude: 29.12758), // TR/Muğla; GeoNames 314967
        "geonames-2189529": .init(latitude: -46.4, longitude: 168.35), // NZ/Southland; GeoNames 2189529
        "geonames-3833367": .init(latitude: -54.81084, longitude: -68.31591), // AR/Tierra del Fuego; GeoNames 3833367
        "geonames-400666": .init(latitude: 36.43556, longitude: 28.22199), // GR/South Aegean; GeoNames 400666
        "geonames-2653877": .init(latitude: 51.27904, longitude: 1.07992), // GB/England; GeoNames 2653877
        "geonames-1655559": .init(latitude: 19.8933, longitude: 102.1525), // LA/Luang Prabang Province; GeoNames 1655559
        "geonames-2186280": .init(latitude: -41.27078, longitude: 173.28404), // NZ/Nelson Region; GeoNames 2186280
        "geonames-260114": .init(latitude: 35.51124, longitude: 24.02921), // GR/Crete; GeoNames 260114
        "geonames-3166548": .init(latitude: 43.31822, longitude: 11.33064), // IT/Tuscany; GeoNames 3166548
        "geonames-3352844": .init(latitude: -22.67842, longitude: 14.52663), // NA/Erongo Region; GeoNames 3352844
        "geonames-3164603": .init(latitude: 45.43713, longitude: 12.33265), // IT/Veneto; GeoNames 3164603
        "geonames-1607532": .init(latitude: 14.35167, longitude: 100.57739), // TH/Phra Nakhon Si Ayutthaya; GeoNames 1607532
        "geonames-1154689": .init(latitude: 9.53567, longitude: 99.93567), // TH/Surat Thani; GeoNames 1154689
        "geonames-3037543": .init(latitude: 45.90878, longitude: 6.12565), // FR/Auvergne-Rhône-Alpes; GeoNames 3037543
        "geonames-2646088": .init(latitude: 57.47908, longitude: -4.22398), // GB/Scotland; GeoNames 2646088
        "geonames-5380668": .init(latitude: 33.8303, longitude: -116.54529), // US/California; GeoNames 5380668
        "geonames-3599699": .init(latitude: 14.55636, longitude: -90.7332), // GT/Sacatepéquez; GeoNames 3599699
        "geonames-3623076": .init(latitude: 10.63517, longitude: -85.43779), // CR/Guanacaste Province; GeoNames 3623076
        "geonames-5855927": .init(latitude: 19.72991, longitude: -155.09073), // US/Hawaii; GeoNames 5855927
        "geonames-2202064": .init(latitude: -17.80309, longitude: 177.41617), // FJ/Western; GeoNames 2202064
        "geonames-3133895": .init(latitude: 69.6489, longitude: 18.95508), // NO/Troms; GeoNames 3133895
        "geonames-320995": .init(latitude: 37.03833, longitude: 27.42917), // TR/Muğla; GeoNames 320995
        "geonames-1264976": .init(latitude: 34.16504, longitude: 77.58402), // IN/Ladakh; GeoNames 1264976
        "geonames-879431": .init(latitude: -17.93285, longitude: 25.83066), // ZW/Matabeleland North; GeoNames 879431
        "geonames-3032797": .init(latitude: 43.48055, longitude: -1.55684), // FR/New Aquitaine; GeoNames 3032797
        "geonames-1580541": .init(latitude: 15.87944, longitude: 108.335), // VN/Da Nang City; GeoNames 1580541
        "geonames-5861897": .init(latitude: 64.83778, longitude: -147.71639), // US/Alaska; GeoNames 5861897
        "geonames-5554072": .init(latitude: 58.30194, longitude: -134.41972), // US/Alaska; GeoNames 5554072
        "geonames-1152633": .init(latitude: 8.07257, longitude: 98.91052), // TH/Krabi; GeoNames 1152633
        "geonames-2636713": .init(latitude: 52.19166, longitude: -1.70734), // GB/England; GeoNames 2636713
        "geonames-5374361": .init(latitude: 36.60024, longitude: -121.89468), // US/California; GeoNames 5374361
        "geonames-6180550": .init(latitude: 60.71611, longitude: -135.05375), // CA/Yukon; GeoNames 6180550
        "geonames-3201047": .init(latitude: 42.64125, longitude: 18.10909), // HR/Dubrovnik-Neretva; GeoNames 3201047
        "geonames-2077895": .init(latitude: -23.69748, longitude: 133.88362), // AU/Northern Territory; GeoNames 2077895
        "geonames-4160812": .init(latitude: 24.55524, longitude: -81.78163), // US/Florida; GeoNames 4160812
        "geonames-3581194": .init(latitude: 17.1588, longitude: -89.0696), // BZ/Cayo District; GeoNames 3581194
        "geonames-6185377": .init(latitude: 62.45411, longitude: -114.37248), // CA/Northwest Territories; GeoNames 6185377
        "geonames-6941014": .init(latitude: 37.73952, longitude: -25.66874), // PT/Azores; GeoNames 6941014
        "geonames-2638864": .init(latitude: 56.33871, longitude: -2.79902), // GB/Scotland; GeoNames 2638864
        "geonames-3455036": .init(latitude: -23.21778, longitude: -44.71306), // BR/Rio de Janeiro; GeoNames 3455036
        "geonames-2075720": .init(latitude: -17.95538, longitude: 122.23922), // AU/Western Australia; GeoNames 2075720
        "geonames-2136150": .init(latitude: -15.51989, longitude: 167.16235), // VU/Sanma; GeoNames 2136150
        "geonames-3652764": .init(latitude: -0.74018, longitude: -90.3138), // EC/Galápagos; GeoNames 3652764
        "geonames-5847504": .init(latitude: 19.64016, longitude: -155.99912), // US/Hawaii; GeoNames 5847504
        "geonames-1252490": .init(latitude: 27.4305, longitude: 89.41334), // BT/Paro; GeoNames 1252490
        "geonames-2661039": .init(latitude: 46.80429, longitude: 9.83723), // CH/Grisons; GeoNames 2661039
        "geonames-5828648": .init(latitude: 43.47993, longitude: -110.76243), // US/Wyoming; GeoNames 5828648
        "geonames-6204696": .init(latitude: -45.03023, longitude: 168.66271), // NZ/Otago; GeoNames 6204696
        "geonames-3901903": .init(latitude: -20.45967, longitude: -66.82503), // BO/Potosí Department; GeoNames 3901903
        "geonames-5892532": .init(latitude: 51.17622, longitude: -115.56982), // CA/Alberta; GeoNames 5892532
        "geonames-5983720": .init(latitude: 63.74697, longitude: -68.51727), // CA/Nunavut; GeoNames 5983720
        "geonames-5412230": .init(latitude: 39.1911, longitude: -106.81754), // US/Colorado; GeoNames 5412230
        "geonames-2657928": .init(latitude: 46.01998, longitude: 7.74863), // CH/Valais; GeoNames 2657928
        "geonames-4043034": .init(latitude: 6.964, longitude: 158.2062), // FM/Pohnpei State; GeoNames 4043034
        "geonames-3197538": .init(latitude: 42.42067, longitude: 18.76825), // ME/Kotor; GeoNames 3197538
        "geonames-2660253": .init(latitude: 46.68387, longitude: 7.86638), // CH/Bern; GeoNames 2660253
        "geonames-3623716": .init(latitude: 10.47089, longitude: -84.64535), // CR/Alajuela Province; GeoNames 3623716
        "geonames-1151601": .init(latitude: 19.36168, longitude: 98.43973), // TH/Chiang Mai; GeoNames 1151601
        "geonames-1814906": .init(latitude: 29.56026, longitude: 106.55771), // CN/Chongqing; GeoNames 1814906
        "geonames-1792947": .init(latitude: 39.14222, longitude: 117.17667), // CN/Tianjin; GeoNames 1792947
        "geonames-1791247": .init(latitude: 30.58333, longitude: 114.26667), // CN/Hubei; GeoNames 1791247
        "geonames-1790630": .init(latitude: 34.25833, longitude: 108.92861), // CN/Shaanxi; GeoNames 1790630
        "geonames-1808926": .init(latitude: 30.29365, longitude: 120.16142), // CN/Zhejiang; GeoNames 1808926
        "geonames-2037013": .init(latitude: 45.75, longitude: 126.65), // CN/Heilongjiang; GeoNames 2037013
        "geonames-1812545": .init(latitude: 23.01797, longitude: 113.74866), // CN/Guangdong; GeoNames 1812545
        "geonames-1808722": .init(latitude: 31.86389, longitude: 117.28083), // CN/Anhui; GeoNames 1808722
        "geonames-1791681": .init(latitude: 36.71, longitude: 119.10194), // CN/Shandong; GeoNames 1791681
        "geonames-1799962": .init(latitude: 32.06167, longitude: 118.77778), // CN/Jiangsu; GeoNames 1799962
        "geonames-2034937": .init(latitude: 41.79222, longitude: 123.43278), // CN/Liaoning; GeoNames 2034937
        "geonames-1811103": .init(latitude: 23.02677, longitude: 113.13148), // CN/Guangdong; GeoNames 1811103
        "geonames-1805753": .init(latitude: 36.66833, longitude: 116.99722), // CN/Shandong; GeoNames 1805753
        "geonames-1814087": .init(latitude: 38.91222, longitude: 121.60222), // CN/Liaoning; GeoNames 1814087
        "geonames-1790842": .init(latitude: 37.9867, longitude: 106.201), // CN/Ningxia; GeoNames 1790842
        "geonames-1797929": .init(latitude: 36.06488, longitude: 120.38042), // CN/Shandong; GeoNames 1797929
        "geonames-1787093": .init(latitude: 37.47649, longitude: 121.44081), // CN/Shandong; GeoNames 1787093
        "geonames-1784658": .init(latitude: 34.75778, longitude: 113.64861), // CN/Henan; GeoNames 1784658
        "geonames-1279233": .init(latitude: 23.02579, longitude: 72.58727), // IN/Gujarat; GeoNames 1279233
        "geonames-2293538": .init(latitude: 5.35444, longitude: -4.00167), // CI/Abidjan Autonomous District; GeoNames 2293538
        "geonames-1799869": .init(latitude: 22.81667, longitude: 108.31667), // CN/Guangxi; GeoNames 1799869
        "geonames-1795270": .init(latitude: 38.04139, longitude: 114.47861), // CN/Hebei; GeoNames 1795270
        "geonames-2038180": .init(latitude: 43.88, longitude: 125.32278), // CN/Jilin; GeoNames 2038180
        "geonames-160263": .init(latitude: -6.82349, longitude: 39.26951), // TZ/Dar es Salaam Region; GeoNames 160263
        "geonames-1793511": .init(latitude: 37.86944, longitude: 112.56028), // CN/Shanxi; GeoNames 1793511
        "geonames-361058": .init(latitude: 31.20176, longitude: 29.91582), // EG/Alexandria; GeoNames 361058
        "geonames-2335204": .init(latitude: 12.00012, longitude: 8.51672), // NG/Kano State; GeoNames 2335204
        "geonames-1168197": .init(latitude: 34.008, longitude: 71.57849), // PK/Khyber Pakhtunkhwa; GeoNames 1168197
        "geonames-1785286": .init(latitude: 36.79056, longitude: 118.06333), // CN/Shandong; GeoNames 1785286
        "geonames-1255364": .init(latitude: 21.19594, longitude: 72.83023), // IN/Gujarat; GeoNames 1255364
        "geonames-1787227": .init(latitude: 32.39722, longitude: 119.43583), // CN/Jiangsu; GeoNames 1787227
        "geonames-1797873": .init(latitude: 33.58861, longitude: 119.01917), // CN/Jiangsu; GeoNames 1797873
        "geonames-1809461": .init(latitude: 26.58333, longitude: 106.71667), // CN/Guizhou; GeoNames 1809461
        "geonames-1790923": .init(latitude: 31.56887, longitude: 120.28857), // CN/Jiangsu; GeoNames 1790923
        "geonames-360995": .init(latitude: 30.00944, longitude: 31.20861), // EG/Giza; GeoNames 360995
        "geonames-1804430": .init(latitude: 36.05701, longitude: 103.83987), // CN/Gansu; GeoNames 1804430
        "geonames-1810821": .init(latitude: 26.06139, longitude: 119.30611), // CN/Fujian; GeoNames 1810821
        "geonames-1529102": .init(latitude: 43.80096, longitude: 87.60046), // CN/Xinjiang; GeoNames 1529102
        "geonames-12908892": .init(latitude: 25.06199, longitude: 121.45703), // TW/Taipei; GeoNames 12908892
        "geonames-1785453": .init(latitude: 34.86472, longitude: 117.55417), // CN/Shandong; GeoNames 1785453
        "geonames-6986104": .init(latitude: 22.52306, longitude: 113.37912), // CN/Guangdong; GeoNames 6986104
        "geonames-1795940": .init(latitude: 23.35489, longitude: 116.67876), // CN/Guangdong; GeoNames 1795940
        "geonames-1179400": .init(latitude: 31.41554, longitude: 73.08969), // PK/Punjab; GeoNames 1179400
        "geonames-1848354": .init(latitude: 35.43333, longitude: 139.65), // JP/Kanagawa; GeoNames 1848354
        "geonames-1799397": .init(latitude: 29.87819, longitude: 121.54945), // CN/Zhejiang; GeoNames 1799397
        "geonames-2339354": .init(latitude: 7.37756, longitude: 3.90591), // NG/Oyo State; GeoNames 2339354
        "geonames-1798425": .init(latitude: 29.45679, longitude: 119.88872), // CN/Zhejiang; GeoNames 1798425
        "geonames-1794903": .init(latitude: 32.6475, longitude: 110.77806), // CN/Hubei; GeoNames 1794903
        "geonames-2036892": .init(latitude: 40.81056, longitude: 111.65222), // CN/Inner Mongolia; GeoNames 2036892
        "geonames-1793346": .init(latitude: 39.64381, longitude: 118.18319), // CN/Hebei; GeoNames 1793346
        "geonames-1166993": .init(latitude: 33.59733, longitude: 73.0479), // PK/Punjab; GeoNames 1166993
        "geonames-13512505": .init(latitude: 37.5192, longitude: 111.14436), // CN/Shanxi; GeoNames 13512505
        "geonames-1007311": .init(latitude: -29.8579, longitude: 31.0292), // ZA/KwaZulu-Natal; GeoNames 1007311
        "geonames-2038632": .init(latitude: 41.12361, longitude: 122.99), // CN/Liaoning; GeoNames 2038632
        "geonames-1815456": .init(latitude: 31.77359, longitude: 119.95401), // CN/Jiangsu; GeoNames 1815456
        "geonames-1259229": .init(latitude: 18.51957, longitude: 73.85535), // IN/Maharashtra; GeoNames 1259229
        "geonames-2037799": .init(latitude: 40.09361, longitude: 113.29139), // CN/Shanxi; GeoNames 2037799
        "geonames-750269": .init(latitude: 40.19559, longitude: 29.06013), // TR/Bursa Province; GeoNames 750269
        "geonames-1815577": .init(latitude: 28.19874, longitude: 112.97087), // CN/Hunan; GeoNames 1815577
        "geonames-1692192": .init(latitude: 14.6488, longitude: 121.0509), // PH/National Capital Region; GeoNames 1692192
        "geonames-1807681": .init(latitude: 32.62639, longitude: 116.99694), // CN/Anhui; GeoNames 1807681
        "geonames-1843564": .init(latitude: 37.45646, longitude: 126.70515), // KR/Incheon; GeoNames 1843564
        "geonames-1809078": .init(latitude: 20.03421, longitude: 110.34651), // CN/Hainan; GeoNames 1809078
        "geonames-311046": .init(latitude: 38.41273, longitude: 27.13838), // TR/İzmir Province; GeoNames 311046
        "geonames-1806776": .init(latitude: 23.11147, longitude: 114.41523), // CN/Guangdong; GeoNames 1806776
        "geonames-1786657": .init(latitude: 38.46806, longitude: 106.27306), // CN/Ningxia; GeoNames 1786657
        "geonames-1668399": .init(latitude: 24.1469, longitude: 120.6839), // TW/Taiwan; GeoNames 1668399
        "geonames-1267995": .init(latitude: 26.46523, longitude: 80.34975), // IN/Uttar Pradesh; GeoNames 1267995
        "geonames-2038432": .init(latitude: 40.6516, longitude: 109.84389), // CN/Inner Mongolia; GeoNames 2038432
        "geonames-1803318": .init(latitude: 35.06306, longitude: 118.34278), // CN/Shandong; GeoNames 1803318
        "geonames-1816971": .init(latitude: 38.87288, longitude: 115.46246), // CN/Hebei; GeoNames 1816971
        "geonames-1673820": .init(latitude: 22.61626, longitude: 120.31333), // TW/Takao; GeoNames 1673820
        "geonames-5110302": .init(latitude: 40.6501, longitude: -73.94958), // US/New York; GeoNames 5110302
        "geonames-3470127": .init(latitude: -19.92083, longitude: -43.93778), // BR/Minas Gerais; GeoNames 3470127
        "geonames-11995100": .init(latitude: 31.8694, longitude: 106.74432), // CN/Sichuan; GeoNames 11995100
        "geonames-3450554": .init(latitude: -12.97563, longitude: -38.49096), // BR/Bahia; GeoNames 3450554
        "geonames-1200109": .init(latitude: 23.99844, longitude: 90.42234), // BD/Dhaka Division; GeoNames 1200109
        "geonames-1791388": .init(latitude: 27.99942, longitude: 120.66682), // CN/Zhejiang; GeoNames 1791388
        "geonames-1649378": .init(latitude: -6.2349, longitude: 106.9896), // ID/West Java; GeoNames 1649378
        "geonames-1581298": .init(latitude: 20.86481, longitude: 106.68345), // VN/Hai Phong; GeoNames 1581298
        "geonames-1785725": .init(latitude: 22.92787, longitude: 112.03809), // CN/Guangdong; GeoNames 1785725
        "geonames-1177662": .init(latitude: 32.15567, longitude: 74.18705), // PK/Punjab; GeoNames 1177662
        "geonames-1214520": .init(latitude: 3.58333, longitude: 98.66667), // ID/North Sumatra; GeoNames 1214520
        "geonames-1264733": .init(latitude: 26.83928, longitude: 80.92313), // IN/Uttar Pradesh; GeoNames 1264733
        "geonames-1788852": .init(latitude: 36.62554, longitude: 101.75739), // CN/Qinghai; GeoNames 1788852
        "geonames-1262180": .init(latitude: 21.14631, longitude: 79.08491), // IN/Maharashtra; GeoNames 1262180
        "geonames-3399415": .init(latitude: -3.71722, longitude: -38.54306), // BR/Ceará; GeoNames 3399415
        "geonames-3687925": .init(latitude: 3.43054, longitude: -76.5199), // CO/Valle del Cauca Department; GeoNames 3687925
        "geonames-1835329": .init(latitude: 35.87102, longitude: 128.60121), // KR/Daegu; GeoNames 1835329
        "geonames-1800163": .init(latitude: 28.68396, longitude: 115.85306), // CN/Jiangxi; GeoNames 1800163
        "geonames-1856057": .init(latitude: 35.18147, longitude: 136.90641), // JP/Aichi; GeoNames 1856057
        "geonames-5133273": .init(latitude: 40.68149, longitude: -73.83652), // US/New York; GeoNames 5133273
        "geonames-124665": .init(latitude: 36.29807, longitude: 59.60567), // IR/Razavi Khorasan; GeoNames 124665
        "geonames-1795855": .init(latitude: 30.00237, longitude: 120.57864), // CN/Zhejiang; GeoNames 1795855
        "geonames-1799722": .init(latitude: 32.03028, longitude: 120.87472), // CN/Jiangsu; GeoNames 1799722
        "geonames-314830": .init(latitude: 37.05944, longitude: 37.3825), // TR/Gaziantep; GeoNames 314830
        "geonames-922704": .init(latitude: -11.66089, longitude: 27.47938), // CD/Haut-Katanga; GeoNames 922704
        "geonames-3663517": .init(latitude: -3.10194, longitude: -60.025), // BR/Amazonas; GeoNames 3663517
        "geonames-1790437": .init(latitude: 22.27694, longitude: 113.56778), // CN/Guangdong; GeoNames 1790437
        "geonames-1169825": .init(latitude: 30.19679, longitude: 71.47824), // PK/Punjab; GeoNames 1169825
        "geonames-1645524": .init(latitude: -6.4, longitude: 106.81861), // ID/West Java; GeoNames 1645524
        "geonames-8347664": .init(latitude: 39.6086, longitude: 109.78157), // CN/Inner Mongolia; GeoNames 8347664
        "geonames-1273865": .init(latitude: 11.00555, longitude: 76.96612), // IN/Tamil Nadu; GeoNames 1273865
        "geonames-12359313": .init(latitude: 35.70976, longitude: 107.64455), // CN/Gansu; GeoNames 12359313
        "geonames-209228": .init(latitude: -6.13603, longitude: 23.58979), // CD/East Kasai; GeoNames 209228
        "geonames-170063": .init(latitude: 36.20124, longitude: 37.16117), // SY/Aleppo; GeoNames 170063
        "geonames-1785623": .init(latitude: 31.37762, longitude: 120.95431), // CN/Jiangsu; GeoNames 1785623
        "geonames-1783621": .init(latitude: 27.68667, longitude: 106.90722), // CN/Guizhou; GeoNames 1783621
        "geonames-3911925": .init(latitude: -16.5, longitude: -68.15), // BO/La Paz Department; GeoNames 3911925
        "geonames-10859300": .init(latitude: 34.59845, longitude: 119.21556), // CN/Jiangsu; GeoNames 10859300
        "geonames-1802940": .init(latitude: 23.31072, longitude: 116.16869), // CN/Guangdong; GeoNames 1802940
        "geonames-1269743": .init(latitude: 22.71792, longitude: 75.8333), // IN/Madhya Pradesh; GeoNames 1269743
        "geonames-1810638": .init(latitude: 25.84664, longitude: 114.9326), // CN/Jiangxi; GeoNames 1810638
        "geonames-2128295": .init(latitude: 43.06667, longitude: 141.35), // JP/Hokkaido; GeoNames 2128295
        "geonames-3464975": .init(latitude: -25.42778, longitude: -49.27306), // BR/Paraná; GeoNames 3464975
        "geonames-1625084": .init(latitude: -6.17806, longitude: 106.63), // ID/Banten; GeoNames 1625084
        "geonames-3981609": .init(latitude: 32.5027, longitude: -117.00371), // MX/Baja California; GeoNames 3981609
        "geonames-1176734": .init(latitude: 25.39689, longitude: 68.37718), // PK/Sindh; GeoNames 1176734
        "geonames-1797121": .init(latitude: 23.5418, longitude: 116.36581), // CN/Guangdong; GeoNames 1797121
        "geonames-2036502": .init(latitude: 43.84652, longitude: 126.5608), // CN/Jilin; GeoNames 2036502
        "geonames-2422488": .init(latitude: 9.535, longitude: -13.68778), // GN/Conakry; GeoNames 2422488
        "geonames-195272": .init(latitude: 0.28422, longitude: 34.75229), // KE/Kakamega County; GeoNames 195272
        "geonames-1796134": .init(latitude: 34.4143, longitude: 115.65613), // CN/Henan; GeoNames 1796134
        "geonames-1800146": .init(latitude: 30.79508, longitude: 106.08473), // CN/Sichuan; GeoNames 1800146
        "geonames-1668355": .init(latitude: 22.99259, longitude: 120.20507), // TW/Taiwan; GeoNames 1668355
        "geonames-2335727": .init(latitude: 10.52641, longitude: 7.43879), // NG/Kaduna State; GeoNames 2335727
        "geonames-365137": .init(latitude: 15.64453, longitude: 32.47773), // SD/Khartoum; GeoNames 365137
        "geonames-1254661": .init(latitude: 19.19704, longitude: 72.96355), // IN/Maharashtra; GeoNames 1254661
        "geonames-3526683": .init(latitude: 19.35529, longitude: -99.06224), // MX/Mexico City; GeoNames 3526683
        "geonames-316541": .init(latitude: 37.91363, longitude: 40.21721), // TR/Diyarbakır Province; GeoNames 316541
        "geonames-3904906": .init(latitude: -17.78629, longitude: -63.18117), // BO/Santa Cruz Department; GeoNames 3904906
        "geonames-1253573": .init(latitude: 22.29941, longitude: 73.20812), // IN/Gujarat; GeoNames 1253573
        "geonames-325363": .init(latitude: 36.98615, longitude: 35.32531), // TR/Adana; GeoNames 325363
        "geonames-1799629": .init(latitude: 33.00524, longitude: 112.54659), // CN/Henan; GeoNames 1799629
        "geonames-1633070": .init(latitude: -2.91673, longitude: 104.7458), // ID/South Sumatra; GeoNames 1633070
        "geonames-1275841": .init(latitude: 23.25469, longitude: 77.40289), // IN/Madhya Pradesh; GeoNames 1275841
        "geonames-1806299": .init(latitude: 22.58333, longitude: 113.08333), // CN/Guangdong; GeoNames 1806299
        "geonames-2347283": .init(latitude: 6.33815, longitude: 5.62575), // NG/Edo State; GeoNames 2347283
        "geonames-1815251": .init(latitude: 31.91102, longitude: 120.26302), // CN/Jiangsu; GeoNames 1815251
        "geonames-1810845": .init(latitude: 32.9, longitude: 115.81667), // CN/Anhui; GeoNames 1810845
        "geonames-11838258": .init(latitude: 40.74143, longitude: 107.38599), // CN/Inner Mongolia; GeoNames 11838258
        "geonames-1793036": .init(latitude: 35.08357, longitude: 117.19071), // CN/Shandong; GeoNames 1793036
        "geonames-3633009": .init(latitude: 10.64232, longitude: -71.61089), // VE/Zulia; GeoNames 3633009
        "geonames-1815395": .init(latitude: 23.65396, longitude: 116.62262), // CN/Guangdong; GeoNames 1815395
        "geonames-1793724": .init(latitude: 36.18528, longitude: 117.12), // CN/Shandong; GeoNames 1793724
        "geonames-1258393": .init(latitude: 17.73308, longitude: 83.31622), // IN/Andhra Pradesh; GeoNames 1258393
        "geonames-7626690": .init(latitude: 18.61867, longitude: 73.80375), // IN/Maharashtra; GeoNames 7626690
        "geonames-1720151": .init(latitude: 14.64953, longitude: 120.96788), // PH/National Capital Region; GeoNames 1720151
        "geonames-953781": .init(latitude: -26.26781, longitude: 27.85849), // ZA/Gauteng; GeoNames 953781
        "geonames-1627896": .init(latitude: -6.99306, longitude: 110.42083), // ID/Central Java; GeoNames 1627896
        "geonames-3521081": .init(latitude: 19.04778, longitude: -98.20723), // MX/Puebla; GeoNames 3521081
        "geonames-1260086": .init(latitude: 25.59408, longitude: 85.13563), // IN/Bihar; GeoNames 1260086
        "geonames-99072": .init(latitude: 36.335, longitude: 43.11889), // IQ/Nineveh; GeoNames 99072
        "geonames-12165956": .init(latitude: 11.73379, longitude: 78.95925), // IN/Tamil Nadu; GeoNames 12165956
        "geonames-7283386": .init(latitude: 31.64615, longitude: 120.74221), // CN/Jiangsu; GeoNames 7283386
        "geonames-3390760": .init(latitude: -8.05389, longitude: -34.88111), // BR/Pernambuco; GeoNames 3390760
        "geonames-1793743": .init(latitude: 33.63611, longitude: 116.97889), // CN/Anhui; GeoNames 1793743
        "geonames-3529612": .init(latitude: 19.60006, longitude: -99.04855), // MX/México; GeoNames 3529612
        "geonames-1802206": .init(latitude: 31.73561, longitude: 116.51688), // CN/Anhui; GeoNames 1802206
        "geonames-3625549": .init(latitude: 10.16153, longitude: -68.00044), // VE/Carabobo; GeoNames 3625549
        "geonames-1264728": .init(latitude: 30.91204, longitude: 75.85379), // IN/Punjab; GeoNames 1264728
        "geonames-1787746": .init(latitude: 33.3575, longitude: 120.1573), // CN/Jiangsu; GeoNames 1787746
        "geonames-95446": .init(latitude: 36.19117, longitude: 44.00943), // IQ/Erbil; GeoNames 95446
        "geonames-1863967": .init(latitude: 33.6, longitude: 130.41667), // JP/Fukuoka; GeoNames 1863967
        "geonames-1793505": .init(latitude: 32.49069, longitude: 119.90812), // CN/Jiangsu; GeoNames 1793505
        "geonames-2037860": .init(latitude: 46.58333, longitude: 125), // CN/Heilongjiang; GeoNames 2037860
        "geonames-212730": .init(latitude: 0.51528, longitude: 25.19099), // CD/Tshopo; GeoNames 212730
        "geonames-1791236": .init(latitude: 31.35259, longitude: 118.42947), // CN/Anhui; GeoNames 1791236
        "geonames-3991164": .init(latitude: 20.58806, longitude: -100.38806), // MX/Querétaro; GeoNames 3991164
        "geonames-1813325": .init(latitude: 31.2106, longitude: 107.46308), // CN/Sichuan; GeoNames 1813325
        "geonames-3998655": .init(latitude: 21.12183, longitude: -101.68253), // MX/Guanajuato; GeoNames 3998655
        "geonames-104515": .init(latitude: 21.42664, longitude: 39.82563), // SA/Mecca Region; GeoNames 104515
        "geonames-4560349": .init(latitude: 39.95238, longitude: -75.16362), // US/Pennsylvania; GeoNames 4560349
        "geonames-1167528": .init(latitude: 30.18414, longitude: 67.00141), // PK/Balochistan; GeoNames 1167528
        "geonames-1784853": .init(latitude: 23.04893, longitude: 112.46091), // CN/Guangdong; GeoNames 1784853
        "geonames-2326016": .init(latitude: 6.14978, longitude: 6.78569), // NG/Anambra; GeoNames 2326016
        "geonames-1800627": .init(latitude: 31.46784, longitude: 104.68168), // CN/Sichuan; GeoNames 1800627
        "geonames-418863": .init(latitude: 32.65246, longitude: 51.67462), // IR/Isfahan; GeoNames 418863
        "geonames-12358576": .init(latitude: 30.76451, longitude: 108.39586), // CN/Chongqing; GeoNames 12358576
        "geonames-1798449": .init(latitude: 25.43944, longitude: 119.01028), // CN/Fujian; GeoNames 1798449
        "geonames-1859642": .init(latitude: 35.52056, longitude: 139.71722), // JP/Kanagawa; GeoNames 1859642
        "geonames-3462377": .init(latitude: -16.67861, longitude: -49.25389), // BR/Goiás; GeoNames 3462377
        "geonames-4726206": .init(latitude: 29.42412, longitude: -98.49363), // US/Texas; GeoNames 4726206
        "geonames-1859171": .init(latitude: 34.6913, longitude: 135.183), // JP/Hyōgo; GeoNames 1859171
        "geonames-2036427": .init(latitude: 41.10778, longitude: 121.14167), // CN/Liaoning; GeoNames 2036427
        "geonames-4013708": .init(latitude: 31.72024, longitude: -106.46084), // MX/Chihuahua; GeoNames 4013708
        "geonames-1586203": .init(latitude: 10.03711, longitude: 105.78825), // VN/Can Tho City; GeoNames 1586203
        "geonames-1336135": .init(latitude: 22.80979, longitude: 89.56439), // BD/Khulna Division; GeoNames 1336135
        "geonames-3405870": .init(latitude: -1.45583, longitude: -48.50444), // BR/Pará; GeoNames 3405870
        "geonames-3452925": .init(latitude: -30.03283, longitude: -51.23019), // BR/Rio Grande do Sul; GeoNames 3452925
        "geonames-5125771": .init(latitude: 40.78343, longitude: -73.96625), // US/New York; GeoNames 5125771
        "geonames-1261731": .init(latitude: 19.99727, longitude: 73.79096), // IN/Maharashtra; GeoNames 1261731
        "geonames-8400694": .init(latitude: 28.66266, longitude: 121.43312), // CN/Zhejiang; GeoNames 8400694
        "geonames-1814870": .init(latitude: 29.31506, longitude: 120.07676), // CN/Zhejiang; GeoNames 1814870
        "geonames-3979770": .init(latitude: 20.72111, longitude: -103.38742), // MX/Jalisco; GeoNames 3979770
        "geonames-1797353": .init(latitude: 24.91389, longitude: 118.58583), // CN/Fujian; GeoNames 1797353
        "geonames-1264521": .init(latitude: 9.919, longitude: 78.11953), // IN/Tamil Nadu; GeoNames 1264521
        "geonames-1805528": .init(latitude: 29.10678, longitude: 119.64421), // CN/Zhejiang; GeoNames 1805528
        "geonames-1806602": .init(latitude: 30.1764, longitude: 121.2457), // CN/Zhejiang; GeoNames 1806602
        "geonames-1791121": .init(latitude: 29.03205, longitude: 111.69844), // CN/Hunan; GeoNames 1791121
        "geonames-308464": .init(latitude: 38.73222, longitude: 35.48528), // TR/Kayseri; GeoNames 308464
        "geonames-1804879": .init(latitude: 34.7986, longitude: 114.30742), // CN/Henan; GeoNames 1804879
        "geonames-128747": .init(latitude: 35.83266, longitude: 50.99155), // IR/Alborz Province; GeoNames 128747
        "geonames-1835235": .init(latitude: 36.35022, longitude: 127.3848), // KR/Daejeon; GeoNames 1835235
        "geonames-10942359": .init(latitude: 34.36775, longitude: 107.23705), // CN/Shaanxi; GeoNames 10942359
        "geonames-1793771": .init(latitude: 33.94917, longitude: 118.29583), // CN/Jiangsu; GeoNames 1793771
        "geonames-1803300": .init(latitude: 24.32405, longitude: 109.40698), // CN/Guangxi; GeoNames 1803300
        "geonames-1254361": .init(latitude: 8.72742, longitude: 77.6838), // IN/Tamil Nadu; GeoNames 1254361
        "geonames-306571": .init(latitude: 37.87135, longitude: 32.48464), // TR/Konya; GeoNames 306571
        "geonames-1787331": .init(latitude: 31.865, longitude: 120.53889), // CN/Jiangsu; GeoNames 1787331
        "geonames-8581443": .init(latitude: -6.28862, longitude: 106.71789), // ID/Banten; GeoNames 8581443
        "geonames-113646": .init(latitude: 38.08, longitude: 46.2919), // IR/East Azerbaijan; GeoNames 113646
        "geonames-706483": .init(latitude: 49.98177, longitude: 36.25475), // UA/Kharkiv; GeoNames 706483
        "geonames-1788534": .init(latitude: 32.12278, longitude: 114.06556), // CN/Henan; GeoNames 1788534
        "geonames-1797658": .init(latitude: 24.81978, longitude: 118.57415), // CN/Fujian; GeoNames 1797658
        "geonames-1271951": .init(latitude: 28.41124, longitude: 77.31316), // IN/Haryana; GeoNames 1271951
        "geonames-1816234": .init(latitude: 33.87722, longitude: 115.77028), // CN/Anhui; GeoNames 1816234
        "geonames-1797318": .init(latitude: 25.48333, longitude: 103.78333), // CN/Yunnan; GeoNames 1797318
        "geonames-1841811": .init(latitude: 35.15472, longitude: 126.91556), // KR/Gwangju; GeoNames 1841811
        "geonames-1784990": .init(latitude: 21.23391, longitude: 110.38749), // CN/Guangdong; GeoNames 1784990
        "geonames-2037355": .init(latitude: 41.88669, longitude: 123.94363), // CN/Liaoning; GeoNames 2037355
        "geonames-1258847": .init(latitude: 22.29161, longitude: 70.79322), // IN/Gujarat; GeoNames 1258847
        "geonames-1801792": .init(latitude: 34.67345, longitude: 112.43684), // CN/Henan; GeoNames 1801792
        "geonames-5110266": .init(latitude: 40.84985, longitude: -73.86641), // US/New York; GeoNames 5110266
        "geonames-1802875": .init(latitude: 28.15861, longitude: 113.62709), // CN/Hunan; GeoNames 1802875
        "geonames-1262111": .init(latitude: 28.60922, longitude: 76.97982), // IN/Delhi; GeoNames 1262111
        "geonames-1804120": .init(latitude: 21.64673, longitude: 110.28172), // CN/Guangdong; GeoNames 1804120
        "geonames-1808963": .init(latitude: 36.60999, longitude: 114.48764), // CN/Hebei; GeoNames 1808963
        "geonames-1183460": .init(latitude: 32.98527, longitude: 70.60403), // PK/Khyber Pakhtunkhwa; GeoNames 1183460
        "geonames-1786764": .init(latitude: 30.71444, longitude: 111.28472), // CN/Hubei; GeoNames 1786764
        "geonames-1808198": .init(latitude: 35.23929, longitude: 115.47358), // CN/Shandong; GeoNames 1808198
        "geonames-3461786": .init(latitude: -23.46278, longitude: -46.53333), // BR/São Paulo; GeoNames 3461786
        "geonames-2293521": .init(latitude: 5.41613, longitude: -4.0159), // CI/Abidjan Autonomous District; GeoNames 2293521
        "geonames-1269300": .init(latitude: 22.80278, longitude: 86.18545), // IN/Jharkhand; GeoNames 1269300
        "geonames-2232593": .init(latitude: 4.04827, longitude: 9.70428), // CM/Littoral; GeoNames 2232593
        "geonames-99532": .init(latitude: 30.50852, longitude: 47.7804), // IQ/Basra; GeoNames 99532
        "geonames-6940394": .init(latitude: 35.90807, longitude: 139.65657), // JP/Saitama; GeoNames 6940394
        "geonames-8533133": .init(latitude: 26.59444, longitude: 104.83333), // CN/Guizhou; GeoNames 8533133
        "geonames-1684308": .init(latitude: 14.5243, longitude: 121.0792), // PH/National Capital Region; GeoNames 1684308
        "geonames-1801180": .init(latitude: 21.66625, longitude: 110.91364), // CN/Guangdong; GeoNames 1801180
        "geonames-6295587": .init(latitude: 1.14937, longitude: 104.02491), // ID/Riau; GeoNames 6295587
        "geonames-1797551": .init(latitude: 21.98247, longitude: 108.65061), // CN/Guangxi; GeoNames 1797551
        "geonames-1801934": .init(latitude: 33.57424, longitude: 114.03261), // CN/Henan; GeoNames 1801934
        "geonames-1790587": .init(latitude: 32.0422, longitude: 112.14479), // CN/Hubei; GeoNames 1790587
        "geonames-1806408": .init(latitude: 21.85563, longitude: 111.96272), // CN/Guangdong; GeoNames 1806408
        "geonames-1786760": .init(latitude: 31.36059, longitude: 119.82016), // CN/Jiangsu; GeoNames 1786760
        "geonames-1259652": .init(latitude: 18.62292, longitude: 73.80696), // IN/Maharashtra; GeoNames 1259652
        "geonames-1723510": .init(latitude: 7.20417, longitude: 124.43972), // PH/Autonomous Region in Muslim Mindanao; GeoNames 1723510
        "geonames-1587923": .init(latitude: 10.94469, longitude: 106.82432), // VN/Dong Nai; GeoNames 1587923
        "geonames-214481": .init(latitude: -5.89624, longitude: 22.41659), // CD/Kasai-Central; GeoNames 214481
        "geonames-1788046": .init(latitude: 34.03189, longitude: 113.86299), // CN/Henan; GeoNames 1788046
        "geonames-1268295": .init(latitude: 19.2437, longitude: 73.13554), // IN/Maharashtra; GeoNames 1268295
        "geonames-1783745": .init(latitude: 29.34162, longitude: 104.77689), // CN/Sichuan; GeoNames 1783745
        "geonames-520555": .init(latitude: 56.32867, longitude: 44.00205), // RU/Nizhny Novgorod Oblast; GeoNames 520555
        "geonames-1642548": .init(latitude: -6.5924, longitude: 110.671), // ID/Central Java; GeoNames 1642548
        "geonames-10630003": .init(latitude: 34.20442, longitude: 117.28386), // CN/Jiangsu; GeoNames 10630003
        "geonames-1799491": .init(latitude: 29.58354, longitude: 105.06216), // CN/Sichuan; GeoNames 1799491
        "geonames-115019": .init(latitude: 29.61031, longitude: 52.53113), // IR/Fars; GeoNames 115019
        "geonames-1808316": .init(latitude: 28.56938, longitude: 112.34733), // CN/Hunan; GeoNames 1808316
        "geonames-1272423": .init(latitude: 19.21667, longitude: 73.08333), // IN/Maharashtra; GeoNames 1272423
        "geonames-1805518": .init(latitude: 35.405, longitude: 116.58139), // CN/Shandong; GeoNames 1805518
        "geonames-3648522": .init(latitude: 10.0647, longitude: -69.35703), // VE/Lara; GeoNames 3648522
        "geonames-349076": .init(latitude: 30.12511, longitude: 31.25053), // EG/Qalyubia; GeoNames 349076
        "geonames-1835553": .init(latitude: 37.27818, longitude: 127.03164), // KR/Gyeonggi-do; GeoNames 1835553
        "geonames-1803834": .init(latitude: 36.45064, longitude: 116.00247), // CN/Shandong; GeoNames 1803834
        "geonames-10942283": .init(latitude: 37.68403, longitude: 112.75471), // CN/Shanxi; GeoNames 10942283
        "geonames-3946083": .init(latitude: -12.05162, longitude: -77.13452), // PE/Callao; GeoNames 3946083
        "geonames-1263214": .init(latitude: 28.98002, longitude: 77.70636), // IN/Uttar Pradesh; GeoNames 1263214
        "geonames-1253133": .init(latitude: 19.45591, longitude: 72.81136), // IN/Maharashtra; GeoNames 1253133
        "geonames-1261162": .init(latitude: 19.23114, longitude: 82.54826), // IN/Odisha; GeoNames 1261162
        "geonames-94824": .init(latitude: 32.61603, longitude: 44.02488), // IQ/Karbala; GeoNames 94824
        "geonames-1808956": .init(latitude: 36.18389, longitude: 113.10528), // CN/Shanxi; GeoNames 1808956
        "geonames-1792892": .init(latitude: 34.57952, longitude: 105.74238), // CN/Gansu; GeoNames 1792892
        "geonames-7802746": .init(latitude: 33.3889, longitude: 44.4583), // IQ/Baghdad; GeoNames 7802746
        "geonames-1255634": .init(latitude: 34.08565, longitude: 74.80555), // IN/Jammu and Kashmir; GeoNames 1255634
        "geonames-3689147": .init(latitude: 10.96854, longitude: -74.78132), // CO/Atlántico; GeoNames 3689147
        "geonames-1508291": .init(latitude: 55.1611, longitude: 61.42877), // RU/Chelyabinsk; GeoNames 1508291
        "geonames-1862415": .init(latitude: 34.4, longitude: 132.45), // JP/Hiroshima; GeoNames 1862415
        "geonames-1518980": .init(latitude: 42.30988, longitude: 69.60042), // KZ/Shymkent; GeoNames 1518980
        "geonames-3492914": .init(latitude: 19.45036, longitude: -70.69085), // DO/Santiago Province; GeoNames 3492914
        "geonames-1791636": .init(latitude: 34.50355, longitude: 109.50891), // CN/Shaanxi; GeoNames 1791636
        "geonames-1039854": .init(latitude: -25.96222, longitude: 32.45889), // MZ/Maputo Province; GeoNames 1039854
        "geonames-1272979": .init(latitude: 23.79759, longitude: 86.42992), // IN/Jharkhand; GeoNames 1272979
        "geonames-3514674": .init(latitude: 19.49392, longitude: -99.11075), // MX/Mexico City; GeoNames 3514674
        "geonames-1805953": .init(latitude: 30.7522, longitude: 120.75), // CN/Zhejiang; GeoNames 1805953
        "geonames-1278149": .init(latitude: 19.87757, longitude: 75.34226), // IN/Maharashtra; GeoNames 1278149
        "geonames-1784285": .init(latitude: 37.51129, longitude: 105.19067), // CN/Ningxia; GeoNames 1784285
        "geonames-1496153": .init(latitude: 54.99244, longitude: 73.36859), // RU/Omsk Oblast; GeoNames 1496153
        "geonames-2246678": .init(latitude: 14.76457, longitude: -17.39071), // SN/Dakar; GeoNames 2246678
        "geonames-1631761": .init(latitude: 0.51667, longitude: 101.44167), // ID/Riau; GeoNames 1631761
        "geonames-10794003": .init(latitude: 41.121, longitude: 122.0739), // CN/Liaoning; GeoNames 10794003
        "geonames-1805179": .init(latitude: 29.70475, longitude: 116.00206), // CN/Jiangxi; GeoNames 1805179
        "geonames-2353151": .init(latitude: 5.10658, longitude: 7.36667), // NG/Abia State; GeoNames 2353151
        "geonames-2655603": .init(latitude: 52.48142, longitude: -1.89983), // GB/England; GeoNames 2655603
        "geonames-1785294": .init(latitude: 36.096, longitude: 114.38278), // CN/Henan; GeoNames 1785294
        "geonames-1253184": .init(latitude: 16.50745, longitude: 80.6466), // IN/Andhra Pradesh; GeoNames 1253184
        "geonames-1816373": .init(latitude: 27.30193, longitude: 105.28627), // CN/Guizhou; GeoNames 1816373
        "geonames-501175": .init(latitude: 47.21997, longitude: 39.70769), // RU/Rostov; GeoNames 501175
        "geonames-1783763": .init(latitude: 27.83333, longitude: 113.15), // CN/Hunan; GeoNames 1783763
        "geonames-1797063": .init(latitude: 27.77605, longitude: 120.65859), // CN/Zhejiang; GeoNames 1797063
        "geonames-1978681": .init(latitude: 7.16083, longitude: 124.475), // PH/Soccsksargen; GeoNames 1978681
        "geonames-2244322": .init(latitude: 14.86229, longitude: -15.87532), // SN/Diourbel Region; GeoNames 2244322
        "geonames-479561": .init(latitude: 54.74306, longitude: 55.96779), // RU/Bashkortostan Republic; GeoNames 479561
        "geonames-1258526": .init(latitude: 23.34316, longitude: 85.3094), // IN/Jharkhand; GeoNames 1258526
        "geonames-1783633": .init(latitude: 35.40056, longitude: 116.96556), // CN/Shandong; GeoNames 1783633
        "geonames-1787858": .init(latitude: 28.45179, longitude: 117.94287), // CN/Jiangxi; GeoNames 1787858
        "geonames-1807700": .init(latitude: 33.97444, longitude: 116.79167), // CN/Anhui; GeoNames 1807700
        "geonames-2331447": .init(latitude: 11.84692, longitude: 13.15712), // NG/Borno State; GeoNames 2331447
        "geonames-1800818": .init(latitude: 30.04392, longitude: 103.83696), // CN/Sichuan; GeoNames 1800818
        "geonames-152224": .init(latitude: -2.51667, longitude: 32.9), // TZ/Mwanza; GeoNames 152224
        "geonames-1833747": .init(latitude: 35.53917, longitude: 129.31239), // KR/Ulsan; GeoNames 1833747
        "geonames-2111149": .init(latitude: 38.26667, longitude: 140.86667), // JP/Miyagi; GeoNames 2111149
        "geonames-1502026": .init(latitude: 56.03742, longitude: 92.93136), // RU/Krasnoyarsk Krai; GeoNames 1502026
        "geonames-1810820": .init(latitude: 27.95999, longitude: 116.33333), // CN/Jiangxi; GeoNames 1810820
        "geonames-1624917": .init(latitude: -5.42917, longitude: 105.26111), // ID/Lampung; GeoNames 1624917
        "geonames-1809532": .init(latitude: 23.11603, longitude: 109.59472), // CN/Guangxi; GeoNames 1809532
        "geonames-1269633": .init(latitude: 23.16697, longitude: 79.95006), // IN/Madhya Pradesh; GeoNames 1269633
        "geonames-2337639": .init(latitude: 8.49664, longitude: 4.54214), // NG/Kwara State; GeoNames 2337639
        "geonames-415189": .init(latitude: 12.77957, longitude: 45.03852), // YE/Aden; GeoNames 415189
        "geonames-1648473": .init(latitude: -6.59444, longitude: 106.78917), // ID/West Java; GeoNames 1648473
        "geonames-3530589": .init(latitude: 19.40061, longitude: -99.01483), // MX/México; GeoNames 3530589
        "geonames-1808370": .init(latitude: 26.88946, longitude: 112.61888), // CN/Hunan; GeoNames 1808370
        "geonames-1278994": .init(latitude: 25.44478, longitude: 81.84322), // IN/Uttar Pradesh; GeoNames 1278994
        "geonames-3691175": .init(latitude: -8.11599, longitude: -79.02998), // PE/La Libertad; GeoNames 3691175
        "geonames-1253102": .init(latitude: 17.68009, longitude: 83.20161), // IN/Andhra Pradesh; GeoNames 1253102
        "geonames-1842485": .init(latitude: 37.65639, longitude: 126.835), // KR/Gyeonggi-do; GeoNames 1842485
        "geonames-1785781": .init(latitude: 22.6305, longitude: 110.14686), // CN/Guangxi; GeoNames 1785781
        "geonames-1270583": .init(latitude: 26.22983, longitude: 78.17337), // IN/Madhya Pradesh; GeoNames 1270583
        "geonames-1805540": .init(latitude: 30.35028, longitude: 112.19028), // CN/Hubei; GeoNames 1805540
        "geonames-472045": .init(latitude: 51.66833, longitude: 39.19204), // RU/Voronezh Oblast; GeoNames 472045
        "geonames-1788572": .init(latitude: 35.19033, longitude: 113.80151), // CN/Henan; GeoNames 1788572
        "geonames-1786746": .init(latitude: 27.83333, longitude: 114.4), // CN/Jiangxi; GeoNames 1786746
        "geonames-2322911": .init(latitude: 13.06269, longitude: 5.24322), // NG/Sokoto; GeoNames 2322911
        "geonames-2335953": .init(latitude: 9.92849, longitude: 8.89212), // NG/Plateau State; GeoNames 2335953
        "geonames-1790353": .init(latitude: 34.33778, longitude: 108.70261), // CN/Shaanxi; GeoNames 1790353
        "geonames-3996069": .init(latitude: 32.62781, longitude: -115.45446), // MX/Baja California; GeoNames 3996069
        "geonames-2255414": .init(latitude: -4.77609, longitude: 11.86352), // CG/Pointe-Noire; GeoNames 2255414
        "geonames-3395981": .init(latitude: -9.66583, longitude: -35.73528), // BR/Alagoas; GeoNames 3395981
        "geonames-3467865": .init(latitude: -22.90556, longitude: -47.06083), // BR/São Paulo; GeoNames 3467865
        "geonames-1185188": .init(latitude: 25.74664, longitude: 89.25166), // BD/Rangpur Division; GeoNames 1185188
        "geonames-94787": .init(latitude: 35.46806, longitude: 44.39222), // IQ/Kirkuk; GeoNames 94787
        "geonames-1795874": .init(latitude: 24.8, longitude: 113.58333), // CN/Guangdong; GeoNames 1795874
        "geonames-1270396": .init(latitude: 22.57688, longitude: 88.31857), // IN/West Bengal; GeoNames 1270396
        "geonames-1258980": .init(latitude: 21.23333, longitude: 81.63333), // IN/Chhattisgarh; GeoNames 1258980
        "geonames-1846326": .init(latitude: 35.22806, longitude: 128.68111), // KR/Gyeongsangnam-do; GeoNames 1846326
        "geonames-1802276": .init(latitude: 25.07485, longitude: 117.01775), // CN/Fujian; GeoNames 1802276
        "geonames-2886242": .init(latitude: 50.93333, longitude: 6.95), // DE/North Rhine-Westphalia; GeoNames 2886242
        "geonames-1254388": .init(latitude: 10.8155, longitude: 78.69651), // IN/Tamil Nadu; GeoNames 1254388
        "geonames-1786217": .init(latitude: 26.42389, longitude: 111.61306), // CN/Hunan; GeoNames 1786217
        "geonames-1679432": .init(latitude: 6.91028, longitude: 122.07389), // PH/Zamboanga Peninsula; GeoNames 1679432
        "geonames-1806535": .init(latitude: 30.8703, longitude: 120.0933), // CN/Zhejiang; GeoNames 1806535
        "geonames-1812057": .init(latitude: 22.37303, longitude: 110.94746), // CN/Guangdong; GeoNames 1812057
        "geonames-472757": .init(latitude: 48.71378, longitude: 44.4976), // RU/Volgograd Oblast; GeoNames 472757
        "geonames-379251": .init(latitude: 15.64925, longitude: 32.53458), // SD/Khartoum; GeoNames 379251
        "geonames-5946768": .init(latitude: 53.55014, longitude: -113.46871), // CA/Alberta; GeoNames 5946768
        "geonames-698740": .init(latitude: 46.48572, longitude: 30.74383), // UA/Odesa; GeoNames 698740
        "geonames-1803936": .init(latitude: 37.92672, longitude: 102.63202), // CN/Gansu; GeoNames 1803936
        "geonames-4160021": .init(latitude: 30.33218, longitude: -81.65565), // US/Florida; GeoNames 4160021
        "geonames-4691930": .init(latitude: 32.72541, longitude: -97.32085), // US/Texas; GeoNames 4691930
        "geonames-1786455": .init(latitude: 35.78472, longitude: 118.62806), // CN/Shandong; GeoNames 1786455
        "geonames-1808857": .init(latitude: 33.07507, longitude: 107.02214), // CN/Shaanxi; GeoNames 1808857
        "geonames-7576887": .init(latitude: 24.40357, longitude: 111.56675), // CN/Guangxi; GeoNames 7576887
        "geonames-1266049": .init(latitude: 25.18254, longitude: 75.83907), // IN/Rajasthan; GeoNames 1266049
        "geonames-7602670": .init(latitude: 35.99502, longitude: 119.40259), // CN/Shandong; GeoNames 7602670
        "geonames-1812101": .init(latitude: 37.46271, longitude: 118.49165), // CN/Shandong; GeoNames 1812101
        "geonames-1801640": .init(latitude: 28.8903, longitude: 105.42575), // CN/Sichuan; GeoNames 1801640
        "geonames-5392171": .init(latitude: 37.33939, longitude: -121.89496), // US/California; GeoNames 5392171
        "geonames-1256436": .init(latitude: 17.67152, longitude: 75.91044), // IN/Maharashtra; GeoNames 1256436
        "geonames-1800779": .init(latitude: 24.28859, longitude: 116.11768), // CN/Guangdong; GeoNames 1800779
        "geonames-1927639": .init(latitude: 29.37455, longitude: 113.09481), // CN/Hunan; GeoNames 1927639
        "geonames-1804591": .init(latitude: 36.19278, longitude: 117.65694), // CN/Shandong; GeoNames 1804591
        "geonames-747323": .init(latitude: 41.02697, longitude: 28.67732), // TR/Istanbul; GeoNames 747323
        "geonames-2317765": .init(latitude: 11.11128, longitude: 7.7227), // NG/Kaduna State; GeoNames 2317765
        "geonames-2113015": .init(latitude: 35.6, longitude: 140.11667), // JP/Chiba; GeoNames 2113015
        "geonames-1798827": .init(latitude: 33.73091, longitude: 113.31554), // CN/Henan; GeoNames 1798827
        "geonames-3645528": .init(latitude: 8.35122, longitude: -62.64102), // VE/Bolívar; GeoNames 3645528
        "geonames-1166000": .init(latitude: 32.08586, longitude: 72.67418), // PK/Punjab; GeoNames 1166000
        "geonames-4671654": .init(latitude: 30.26715, longitude: -97.74306), // US/Texas; GeoNames 4671654
        "geonames-1816440": .init(latitude: 32.94083, longitude: 117.36083), // CN/Anhui; GeoNames 1816440
        "geonames-2537763": .init(latitude: 34.0531, longitude: -6.79846), // MA/Rabat-Salé-Kénitra; GeoNames 2537763
        "geonames-1274746": .init(latitude: 30.73629, longitude: 76.7884), // IN/Chandigarh; GeoNames 1274746
        "geonames-709930": .init(latitude: 48.46664, longitude: 35.04066), // UA/Dnipropetrovsk; GeoNames 709930
        "geonames-1789176": .init(latitude: 36.24861, longitude: 116.76583), // CN/Shandong; GeoNames 1789176
        "geonames-1796823": .init(latitude: 39.98049, longitude: 117.06887), // CN/Hebei; GeoNames 1796823
        "geonames-1809412": .init(latitude: 28.88162, longitude: 120.03308), // CN/Zhejiang; GeoNames 1809412
        "geonames-1254348": .init(latitude: 11.11541, longitude: 77.35456), // IN/Tamil Nadu; GeoNames 1254348
        "geonames-1271476": .init(latitude: 26.1844, longitude: 91.7458), // IN/Assam; GeoNames 1271476
        "geonames-1790492": .init(latitude: 27.85, longitude: 112.9), // CN/Hunan; GeoNames 1790492
        "geonames-1803567": .init(latitude: 36.08889, longitude: 111.51889), // CN/Shanxi; GeoNames 1803567
        "geonames-1931681": .init(latitude: 22.2875, longitude: 114.14417), // HK/Central and Western; GeoNames 1931681
        "geonames-1784642": .init(latitude: 32.21086, longitude: 119.45508), // CN/Jiangsu; GeoNames 1784642
        "geonames-2343279": .init(latitude: 6.44132, longitude: 7.49883), // NG/Enugu State; GeoNames 2343279
        "geonames-3838583": .init(latitude: -32.94682, longitude: -60.63932), // AR/Santa Fe; GeoNames 3838583
        "geonames-101760": .init(latitude: 24.49258, longitude: 39.58572), // SA/Medina Region; GeoNames 101760
        "geonames-2036662": .init(latitude: 40.75243, longitude: 120.83552), // CN/Liaoning; GeoNames 2036662
        "geonames-1269920": .init(latitude: 15.34776, longitude: 75.13378), // IN/Karnataka; GeoNames 1269920
        "geonames-1633419": .init(latitude: -0.94924, longitude: 100.35427), // ID/West Sumatra; GeoNames 1633419
        "geonames-1859307": .init(latitude: 33.85181, longitude: 130.85034), // JP/Fukuoka; GeoNames 1859307
        "geonames-70225": .init(latitude: 13.57952, longitude: 44.02091), // YE/Ta‘izz; GeoNames 70225
        "geonames-1281673": .init(latitude: 25.11626, longitude: 99.16366), // CN/Yunnan; GeoNames 1281673
        "geonames-4014338": .init(latitude: 28.63528, longitude: -106.08889), // MX/Chihuahua; GeoNames 4014338
        "geonames-315202": .init(latitude: 39.77667, longitude: 30.52056), // TR/Eskişehir; GeoNames 315202
        "geonames-1262321": .init(latitude: 12.29791, longitude: 76.63925), // IN/Karnataka; GeoNames 1262321
        "geonames-2038087": .init(latitude: 40.9519, longitude: 117.95883), // CN/Hebei; GeoNames 2038087
        "geonames-1257629": .init(latitude: 11.65376, longitude: 78.15538), // IN/Tamil Nadu; GeoNames 1257629
        "geonames-3388368": .init(latitude: -2.52972, longitude: -44.30278), // BR/Maranhão; GeoNames 3388368
        "geonames-1897000": .init(latitude: 37.43861, longitude: 127.13778), // KR/Gyeonggi-do; GeoNames 1897000
        "geonames-1730501": .init(latitude: 14.62578, longitude: 121.12251), // PH/Calabarzon; GeoNames 1730501
        "geonames-4509177": .init(latitude: 39.96118, longitude: -82.99879), // US/Ohio; GeoNames 4509177
        "geonames-1164909": .init(latitude: 32.49268, longitude: 74.53134), // PK/Punjab; GeoNames 1164909
        "geonames-4460243": .init(latitude: 35.22709, longitude: -80.84313), // US/North Carolina; GeoNames 4460243
        "geonames-1804609": .init(latitude: 23.74743, longitude: 109.22222), // CN/Guangxi; GeoNames 1804609
        "geonames-2319133": .init(latitude: 5.51737, longitude: 5.75006), // NG/Delta; GeoNames 2319133
        "geonames-1790254": .init(latitude: 30.92689, longitude: 113.92221), // CN/Hubei; GeoNames 1790254
        "geonames-1800829": .init(latitude: 21.45713, longitude: 110.76591), // CN/Guangdong; GeoNames 1800829
        "geonames-3467747": .init(latitude: -20.44278, longitude: -54.64639), // BR/Mato Grosso do Sul; GeoNames 3467747
        "geonames-1783683": .init(latitude: 30.12108, longitude: 104.64811), // CN/Sichuan; GeoNames 1783683
        "geonames-2362344": .init(latitude: 11.18064, longitude: -4.29489), // BF/Hauts-Bassins; GeoNames 2362344
        "geonames-1183880": .init(latitude: 29.39779, longitude: 71.6752), // PK/Punjab; GeoNames 1183880
        "geonames-1797264": .init(latitude: 28.95944, longitude: 118.86861), // CN/Zhejiang; GeoNames 1797264
        "geonames-931755": .init(latitude: -15.78499, longitude: 35.00854), // MW/Southern Region; GeoNames 931755
        "geonames-709717": .init(latitude: 48.023, longitude: 37.80224), // UA/Donetsk; GeoNames 709717
        "geonames-100077": .init(latitude: 33.30563, longitude: 44.18477), // IQ/Baghdad; GeoNames 100077
        "geonames-119208": .init(latitude: 34.6401, longitude: 50.8764), // IR/Qom Province; GeoNames 119208
        "geonames-542420": .init(latitude: 45.04534, longitude: 38.98178), // RU/Krasnodar Krai; GeoNames 542420
        "geonames-3394023": .init(latitude: -5.795, longitude: -35.20944), // BR/Rio Grande do Norte; GeoNames 3394023
        "geonames-1798654": .init(latitude: 27.61672, longitude: 113.85353), // CN/Jiangxi; GeoNames 1798654
        "geonames-1636722": .init(latitude: -7.9797, longitude: 112.6304), // ID/East Java; GeoNames 1636722
        "geonames-4259418": .init(latitude: 39.76838, longitude: -86.15804), // US/Indiana; GeoNames 4259418
        "geonames-1270642": .init(latitude: 28.4601, longitude: 77.02635), // IN/Haryana; GeoNames 1270642
        "geonames-1275817": .init(latitude: 20.27241, longitude: 85.83385), // IN/Odisha; GeoNames 1275817
        "geonames-1886762": .init(latitude: 29.98869, longitude: 122.20488), // CN/Zhejiang; GeoNames 1886762
        "geonames-2035265": .init(latitude: 47.33922, longitude: 123.96154), // CN/Heilongjiang; GeoNames 2035265
        "geonames-8307074": .init(latitude: -8.86695, longitude: 13.3344), // AO/Luanda; GeoNames 8307074
        "geonames-98463": .init(latitude: 35.56496, longitude: 45.4329), // IQ/Sulaymaniyah; GeoNames 98463
        "geonames-1275901": .init(latitude: 19.30023, longitude: 73.05881), // IN/Maharashtra; GeoNames 1275901
        "geonames-954013": .init(latitude: -25.47288, longitude: 28.09919), // ZA/Gauteng; GeoNames 954013
        "geonames-1804586": .init(latitude: 36.97583, longitude: 120.71361), // CN/Shandong; GeoNames 1804586
        "geonames-1813206": .init(latitude: 30.08333, longitude: 114.95), // CN/Hubei; GeoNames 1813206
        "geonames-3386496": .init(latitude: -5.08917, longitude: -42.80194), // BR/Piauí; GeoNames 3386496
        "geonames-1789065": .init(latitude: 32.68, longitude: 109.01722), // CN/Shaanxi; GeoNames 1789065
        "geonames-1268782": .init(latitude: 31.32556, longitude: 75.57917), // IN/Punjab; GeoNames 1268782
        "geonames-2747891": .init(latitude: 51.9225, longitude: 4.47917), // NL/South Holland; GeoNames 2747891
        "geonames-1804540": .init(latitude: 39.52079, longitude: 116.71471), // CN/Hebei; GeoNames 1804540
        "geonames-3464374": .init(latitude: -22.78556, longitude: -43.31167), // BR/Rio de Janeiro; GeoNames 3464374
        "geonames-2236500": .init(latitude: -8.90553, longitude: 13.37499), // AO/Luanda; GeoNames 2236500
        "geonames-1805987": .init(latitude: 35.23925, longitude: 113.23914), // CN/Henan; GeoNames 1805987
        "geonames-1629001": .init(latitude: -0.49167, longitude: 117.14583), // ID/East Kalimantan; GeoNames 1629001
        "geonames-2038300": .init(latitude: 41.28861, longitude: 123.765), // CN/Liaoning; GeoNames 2038300
        "geonames-1799194": .init(latitude: 30.47413, longitude: 106.63696), // CN/Sichuan; GeoNames 1799194
        "geonames-1732752": .init(latitude: 1.4655, longitude: 103.7578), // MY/Johor; GeoNames 1732752
        "geonames-1184370": .init(latitude: 30.29058, longitude: 73.06574), // PK/Punjab; GeoNames 1184370
        "geonames-7290466": .init(latitude: 14.58691, longitude: 121.0614), // PH/National Capital Region; GeoNames 7290466
        "geonames-1845604": .init(latitude: 36.63722, longitude: 127.48972), // KR/North Chungcheong; GeoNames 1845604
        "geonames-12501153": .init(latitude: 9.96667, longitude: 76.26667), // IN/Kerala; GeoNames 12501153
        "geonames-1838716": .init(latitude: 37.49889, longitude: 126.78306), // KR/Gyeonggi-do; GeoNames 1838716
        "geonames-1566166": .init(latitude: 19.8, longitude: 105.76667), // VN/Thanh Hóa Province; GeoNames 1566166
        "geonames-3165524": .init(latitude: 45.07049, longitude: 7.68682), // IT/Piedmont; GeoNames 3165524
        "geonames-498677": .init(latitude: 51.54048, longitude: 45.9901), // RU/Saratov Oblast; GeoNames 498677
        "geonames-1791673": .init(latitude: 37.50914, longitude: 122.11356), // CN/Shandong; GeoNames 1791673
        "geonames-1821940": .init(latitude: 10.99081, longitude: 104.78498), // KH/Takeo; GeoNames 1821940
        "geonames-3456160": .init(latitude: -22.75917, longitude: -43.45111), // BR/Rio de Janeiro; GeoNames 3456160
        "geonames-3919968": .init(latitude: -17.38195, longitude: -66.15995), // BO/Cochabamba; GeoNames 3919968
        "geonames-144448": .init(latitude: 31.31901, longitude: 48.6842), // IR/Khuzestan; GeoNames 144448
        "geonames-3449344": .init(latitude: -23.69389, longitude: -46.565), // BR/São Paulo; GeoNames 3449344
        "geonames-1817720": .init(latitude: 30.01556, longitude: 120.87111), // CN/Zhejiang; GeoNames 1817720
        "geonames-1788508": .init(latitude: 27.80429, longitude: 114.93335), // CN/Jiangxi; GeoNames 1788508
        "geonames-965301": .init(latitude: -29.61679, longitude: 30.39278), // ZA/KwaZulu-Natal; GeoNames 965301
        "geonames-1786770": .init(latitude: 28.7593, longitude: 104.63994), // CN/Sichuan; GeoNames 1786770
        "geonames-3522790": .init(latitude: 19.47851, longitude: -99.23963), // MX/México; GeoNames 3522790
        "geonames-1771023": .init(latitude: 3.15, longitude: 101.53333), // MY/Selangor; GeoNames 1771023
        "geonames-2290956": .init(latitude: 7.69385, longitude: -5.03031), // CI/Vallée du Bandama District; GeoNames 2290956
        "geonames-1793703": .init(latitude: 31.44778, longitude: 121.09389), // CN/Jiangsu; GeoNames 1793703
        "geonames-1853195": .init(latitude: 34.58216, longitude: 135.46653), // JP/Osaka; GeoNames 1853195
        "geonames-2509954": .init(latitude: 39.47391, longitude: -0.37966), // ES/Valencia; GeoNames 2509954
        "geonames-1815059": .init(latitude: 25.8, longitude: 113.03333), // CN/Hunan; GeoNames 1815059
        "geonames-3397277": .init(latitude: -7.115, longitude: -34.86306), // BR/Paraíba; GeoNames 3397277
        "geonames-217831": .init(latitude: -2.49077, longitude: 28.84281), // CD/South Kivu; GeoNames 217831
        "geonames-2037886": .init(latitude: 40.12917, longitude: 124.39472), // CN/Liaoning; GeoNames 2037886
        "geonames-3648559": .init(latitude: 10.1384, longitude: -64.68769), // VE/Anzoátegui; GeoNames 3648559
        "geonames-4004898": .init(latitude: 29.08874, longitude: -110.96677), // MX/Sonora; GeoNames 4004898
        "geonames-1276014": .init(latitude: 19.30157, longitude: 72.85107), // IN/Maharashtra; GeoNames 1276014
        "geonames-4012176": .init(latitude: 24.80209, longitude: -107.39421), // MX/Sinaloa; GeoNames 4012176
        "geonames-1735158": .init(latitude: 3.10726, longitude: 101.60671), // MY/Selangor; GeoNames 1735158
        "geonames-1817993": .init(latitude: 30.51365, longitude: 117.04723), // CN/Anhui; GeoNames 1817993
        "geonames-2485926": .init(latitude: 35.69906, longitude: -0.63588), // DZ/Oran; GeoNames 2485926
        "geonames-3601782": .init(latitude: 15.50585, longitude: -88.02588), // HN/Cortés Department; GeoNames 3601782
        "geonames-1261809": .init(latitude: 28.85267, longitude: 77.09288), // IN/Delhi; GeoNames 1261809
        "geonames-1788927": .init(latitude: 37.06217, longitude: 114.49272), // CN/Hebei; GeoNames 1788927
        "geonames-1855431": .init(latitude: 37.92259, longitude: 139.04125), // JP/Niigata; GeoNames 1855431
        "geonames-250090": .init(latitude: 32.07275, longitude: 36.08796), // JO/Zarqa; GeoNames 250090
        "geonames-6955677": .init(latitude: 39.9179, longitude: 32.86268), // TR/Ankara; GeoNames 6955677
        "geonames-742394": .init(latitude: 40.99104, longitude: 28.77123), // TR/Istanbul; GeoNames 742394
        "geonames-1863289": .init(latitude: 34.7, longitude: 137.73333), // JP/Shizuoka; GeoNames 1863289
        "geonames-922773": .init(latitude: -10.71484, longitude: 25.46674), // CD/Lualaba; GeoNames 922773
        "geonames-1562798": .init(latitude: 18.67337, longitude: 105.69232), // VN/Nghệ An Province; GeoNames 1562798
        "geonames-1254163": .init(latitude: 8.4855, longitude: 76.94924), // IN/Kerala; GeoNames 1254163
        "geonames-1784841": .init(latitude: 27.31667, longitude: 103.71667), // CN/Yunnan; GeoNames 1784841
        "geonames-6929460": .init(latitude: 26.58509, longitude: 101.71276), // CN/Sichuan; GeoNames 6929460
        "geonames-1814757": .init(latitude: 32.32194, longitude: 118.29778), // CN/Anhui; GeoNames 1814757
        "geonames-358619": .init(latitude: 31.26531, longitude: 32.3019), // EG/Port Said; GeoNames 358619
        "geonames-3685533": .init(latitude: 7.90745, longitude: -72.5049), // CO/Norte de Santander Department; GeoNames 3685533
        "geonames-169577": .init(latitude: 34.72405, longitude: 36.72559), // SY/Homs; GeoNames 169577
        "geonames-1788081": .init(latitude: 30.9525, longitude: 118.75528), // CN/Anhui; GeoNames 1788081
        "geonames-74477": .init(latitude: 13.96667, longitude: 44.18333), // YE/Ibb Governorate; GeoNames 74477
        "geonames-1624647": .init(latitude: -7.3274, longitude: 108.2207), // ID/West Java; GeoNames 1624647
        "geonames-1033356": .init(latitude: -15.11646, longitude: 39.2666), // MZ/Nampula; GeoNames 1033356
        "geonames-425378": .init(latitude: -3.38193, longitude: 29.36142), // BI/Bujumbura Mairie; GeoNames 425378
        "geonames-1488754": .init(latitude: 57.15222, longitude: 65.52722), // RU/Tyumen Oblast; GeoNames 1488754
        "geonames-315368": .init(latitude: 39.90861, longitude: 41.27694), // TR/Erzurum; GeoNames 315368
        "geonames-1817968": .init(latitude: 26.25, longitude: 105.93333), // CN/Guizhou; GeoNames 1817968
        "geonames-1185128": .init(latitude: 24.374, longitude: 88.60114), // BD/Rajshahi Division; GeoNames 1185128
        "geonames-1180281": .init(latitude: 31.83129, longitude: 70.9017), // PK/Khyber Pakhtunkhwa; GeoNames 1180281
        "geonames-3447399": .init(latitude: -23.50167, longitude: -47.45806), // BR/São Paulo; GeoNames 3447399
        "geonames-1790840": .init(latitude: 23.48054, longitude: 111.28848), // CN/Guangxi; GeoNames 1790840
        "geonames-1734634": .init(latitude: 4.5841, longitude: 101.0829), // MY/Perak; GeoNames 1734634
        "geonames-1797595": .init(latitude: 39.94104, longitude: 119.58936), // CN/Hebei; GeoNames 1797595
        "geonames-88319": .init(latitude: 32.11486, longitude: 20.06859), // LY/Banghazi; GeoNames 88319
        "geonames-3445831": .init(latitude: -18.91861, longitude: -48.27722), // BR/Minas Gerais; GeoNames 3445831
        "geonames-1279017": .init(latitude: 27.88145, longitude: 78.07464), // IN/Uttar Pradesh; GeoNames 1279017
        "geonames-1816920": .init(latitude: 27.23818, longitude: 111.46214), // CN/Hunan; GeoNames 1816920
        "geonames-304922": .init(latitude: 38.35018, longitude: 38.31667), // TR/Malatya; GeoNames 304922
        "geonames-6183235": .init(latitude: 49.8844, longitude: -97.14704), // CA/Manitoba; GeoNames 6183235
        "geonames-8469289": .init(latitude: 35.56126, longitude: 139.71605), // JP/Tokyo; GeoNames 8469289
        "geonames-1514588": .init(latitude: 40.78338, longitude: 72.35067), // UZ/Andijan Region; GeoNames 1514588
        "geonames-1277013": .init(latitude: 28.36678, longitude: 79.43167), // IN/Uttar Pradesh; GeoNames 1277013
        "geonames-107304": .init(latitude: 26.32599, longitude: 43.97497), // SA/Al-Qassim Region; GeoNames 107304
        "geonames-2036986": .init(latitude: 47.34727, longitude: 130.29033), // CN/Heilongjiang; GeoNames 2036986
        "geonames-3995402": .init(latitude: 19.70078, longitude: -101.18443), // MX/Michoacán; GeoNames 3995402
        "geonames-1784055": .init(latitude: 39.70083, longitude: 122.99111), // CN/Liaoning; GeoNames 1784055
        "geonames-1721080": .init(latitude: 8.48222, longitude: 124.64722), // PH/Northern Mindanao; GeoNames 1721080
        "geonames-1801620": .init(latitude: 31.68579, longitude: 118.51008), // CN/Anhui; GeoNames 1801620
        "geonames-1732903": .init(latitude: 3.08507, longitude: 101.53281), // MY/Selangor; GeoNames 1732903
        "geonames-751324": .init(latitude: 41.03903, longitude: 28.85671), // TR/Istanbul; GeoNames 751324
        "geonames-12324556": .init(latitude: 38.98082, longitude: 106.3892), // CN/Ningxia; GeoNames 12324556
        "geonames-1858421": .init(latitude: 32.80589, longitude: 130.69181), // JP/Kumamoto; GeoNames 1858421
        "geonames-2325200": .init(latitude: 7.85367, longitude: 3.93235), // NG/Oyo State; GeoNames 2325200
        "geonames-1627549": .init(latitude: -6.11528, longitude: 106.15417), // ID/Banten; GeoNames 1627549
        "geonames-3981254": .init(latitude: 25.54389, longitude: -103.41898), // MX/Coahuila; GeoNames 3981254
        "geonames-1812961": .init(latitude: 31.13019, longitude: 104.38198), // CN/Sichuan; GeoNames 1812961
        "geonames-2352947": .init(latitude: 7.15571, longitude: 3.34509), // NG/Ogun State; GeoNames 2352947
        "geonames-79415": .init(latitude: 14.79781, longitude: 42.95452), // YE/Al Hudaydah; GeoNames 79415
        "geonames-1787351": .init(latitude: 37.8575, longitude: 113.56333), // CN/Shanxi; GeoNames 1787351
        "geonames-2350841": .init(latitude: 7.25256, longitude: 5.19312), // NG/Ondo State; GeoNames 2350841
        "geonames-3455775": .init(latitude: -23.5325, longitude: -46.79167), // BR/São Paulo; GeoNames 3455775
        "geonames-7758790": .init(latitude: -8.7815, longitude: 13.33384), // AO/Luanda; GeoNames 7758790
        "geonames-2239888": .init(latitude: -8.84693, longitude: 13.23698), // AO/Luanda; GeoNames 2239888
        "geonames-3448636": .init(latitude: -23.17944, longitude: -45.88694), // BR/São Paulo; GeoNames 3448636
        "geonames-1865689": .init(latitude: 35.6, longitude: 139.31667), // JP/Kanagawa; GeoNames 1865689
        "geonames-1004866": .init(latitude: -26.53333, longitude: 27.85), // ZA/Gauteng; GeoNames 1004866
        "geonames-1680102": .init(latitude: 14.7, longitude: 120.9667), // PH/National Capital Region; GeoNames 1680102
        "geonames-1169607": .init(latitude: 34.37002, longitude: 73.47082), // PK/Azad Kashmir; GeoNames 1169607
        "geonames-1854383": .init(latitude: 34.65, longitude: 133.93333), // JP/Okayama; GeoNames 1854383
        "geonames-3985606": .init(latitude: 22.15234, longitude: -100.97135), // MX/San Luis Potosí; GeoNames 3985606
        "geonames-4019233": .init(latitude: 21.88262, longitude: -102.2843), // MX/Aguascalientes; GeoNames 4019233
        "geonames-1713022": .init(latitude: 6.11278, longitude: 125.17167), // PH/Soccsksargen; GeoNames 1713022
        "geonames-1783873": .init(latitude: 32.98385, longitude: 114.02586), // CN/Henan; GeoNames 1783873
        "geonames-1262801": .init(latitude: 28.83893, longitude: 78.77684), // IN/Uttar Pradesh; GeoNames 1262801
        "geonames-11611609": .init(latitude: 35.56707, longitude: 139.24167), // JP/Kanagawa; GeoNames 11611609
        "geonames-6075357": .init(latitude: 43.5789, longitude: -79.6583), // CA/Ontario; GeoNames 6075357
        "geonames-702550": .init(latitude: 49.83826, longitude: 24.02324), // UA/Lviv; GeoNames 702550
        "geonames-1513157": .init(latitude: 40.9983, longitude: 71.67257), // UZ/Namangan; GeoNames 1513157
        "geonames-687700": .init(latitude: 47.85167, longitude: 35.11714), // UA/Zaporizhzhia; GeoNames 687700
        "geonames-3988086": .init(latitude: 25.42595, longitude: -100.97963), // MX/Coahuila; GeoNames 3988086
        "geonames-173576": .init(latitude: 35.53125, longitude: 35.79088), // SY/Latakia; GeoNames 173576
        "geonames-1252948": .init(latitude: 18, longitude: 79.58333), // IN/Telangana; GeoNames 1252948
        "geonames-1694781": .init(latitude: 14.48156, longitude: 121.01749), // PH/National Capital Region; GeoNames 1694781
        "geonames-482283": .init(latitude: 53.5303, longitude: 49.3461), // RU/Samara Oblast; GeoNames 482283
        "geonames-7874116": .init(latitude: 18.5, longitude: -70), // DO/Santo Domingo Province; GeoNames 7874116
        "geonames-1183105": .init(latitude: 34.67719, longitude: 73.02329), // PK/Khyber Pakhtunkhwa; GeoNames 1183105
        "geonames-8601412": .init(latitude: 18.48511, longitude: -69.84757), // DO/Santo Domingo Province; GeoNames 8601412
        "geonames-359796": .init(latitude: 29.97371, longitude: 32.52627), // EG/Suez; GeoNames 359796
        "geonames-1815463": .init(latitude: 35.20889, longitude: 111.73861), // CN/Shanxi; GeoNames 1815463
        "geonames-3451328": .init(latitude: -21.1775, longitude: -47.81028), // BR/São Paulo; GeoNames 3451328
        "geonames-1650527": .init(latitude: -1.26753, longitude: 116.82887), // ID/East Kalimantan; GeoNames 1650527
        "geonames-2347470": .init(latitude: 10.31032, longitude: 9.84388), // NG/Bauchi; GeoNames 2347470
        "geonames-1851717": .init(latitude: 34.98333, longitude: 138.38333), // JP/Shizuoka; GeoNames 1851717
        "geonames-2033196": .init(latitude: 40.78341, longitude: 114.87139), // CN/Hebei; GeoNames 2033196
        "geonames-4644585": .init(latitude: 36.16589, longitude: -86.78444), // US/Tennessee; GeoNames 4644585
        "geonames-2037346": .init(latitude: 42.01556, longitude: 121.65889), // CN/Liaoning; GeoNames 2037346
        "geonames-107968": .init(latitude: 21.27028, longitude: 40.41583), // SA/Mecca Region; GeoNames 107968
        "geonames-1796989": .init(latitude: 22.38124, longitude: 112.68492), // CN/Guangdong; GeoNames 1796989
        "geonames-1807234": .init(latitude: 30.24706, longitude: 115.04814), // CN/Hubei; GeoNames 1807234
        "geonames-2036113": .init(latitude: 41.27194, longitude: 123.17306), // CN/Liaoning; GeoNames 2036113
        "geonames-8740157": .init(latitude: 16.85, longitude: 96.06667), // MM/Yangon; GeoNames 8740157
        "geonames-1052373": .init(latitude: -19.84361, longitude: 34.83889), // MZ/Sofala; GeoNames 1052373
        "geonames-3104324": .init(latitude: 41.65606, longitude: -0.87734), // ES/Aragon; GeoNames 3104324
        "geonames-2510911": .init(latitude: 37.38283, longitude: -5.97317), // ES/Andalusia; GeoNames 2510911
        "geonames-1816269": .init(latitude: 23.89013, longitude: 106.62684), // CN/Guangxi; GeoNames 1816269
        "geonames-1630789": .init(latitude: -0.03194, longitude: 109.325), // ID/West Kalimantan; GeoNames 1630789
        "geonames-1626801": .init(latitude: -7.70623, longitude: 114.00976), // ID/East Java; GeoNames 1626801
        "geonames-2351943": .init(latitude: 6.61563, longitude: 3.33337), // NG/Lagos; GeoNames 2351943
        "geonames-1816336": .init(latitude: 37.36667, longitude: 118.01667), // CN/Shandong; GeoNames 1816336
        "geonames-4544349": .init(latitude: 35.46756, longitude: -97.51643), // US/Oklahoma; GeoNames 4544349
        "geonames-1785738": .init(latitude: 35.02306, longitude: 110.99278), // CN/Shanxi; GeoNames 1785738
        "geonames-1812955": .init(latitude: 37.44661, longitude: 116.36706), // CN/Shandong; GeoNames 1812955
        "geonames-2394819": .init(latitude: 6.36536, longitude: 2.41833), // BJ/Littoral; GeoNames 2394819
        "geonames-5520993": .init(latitude: 31.75872, longitude: -106.48693), // US/Texas; GeoNames 5520993
        "geonames-1270927": .init(latitude: 26.76628, longitude: 83.36889), // IN/Uttar Pradesh; GeoNames 1270927
        "geonames-4005492": .init(latitude: 25.67663, longitude: -100.25907), // MX/Nuevo León; GeoNames 4005492
        "geonames-3081368": .init(latitude: 51.10286, longitude: 17.03006), // PL/Lower Silesia; GeoNames 3081368
        "geonames-1270668": .init(latitude: 16.29974, longitude: 80.45729), // IN/Andhra Pradesh; GeoNames 1270668
        "geonames-2334802": .init(latitude: 12.99082, longitude: 7.60177), // NG/Katsina State; GeoNames 2334802
        "geonames-1796669": .init(latitude: 34.78081, longitude: 111.19287), // CN/Henan; GeoNames 1796669
        "geonames-6642286": .init(latitude: 30.39607, longitude: 114.88655), // CN/Hubei; GeoNames 6642286
        "geonames-2591957": .init(latitude: -8.93611, longitude: 13.26518), // AO/Luanda; GeoNames 2591957
        "geonames-101628": .init(latitude: 28.3998, longitude: 36.57151), // SA/Tabuk Region; GeoNames 101628
        "geonames-911148": .init(latitude: -12.80243, longitude: 28.21323), // ZM/Copperbelt; GeoNames 911148
        "geonames-894701": .init(latitude: -20.15, longitude: 28.58333), // ZW/Bulawayo; GeoNames 894701
        "geonames-2035715": .init(latitude: 44.54804, longitude: 129.62594), // CN/Heilongjiang; GeoNames 2035715
        "geonames-3471872": .init(latitude: -10.91111, longitude: -37.07167), // BR/Sergipe; GeoNames 3471872
        "geonames-3459712": .init(latitude: -26.30444, longitude: -48.84556), // BR/Santa Catarina; GeoNames 3459712
        "geonames-1804153": .init(latitude: 29.56227, longitude: 103.76386), // CN/Sichuan; GeoNames 1804153
        "geonames-3449701": .init(latitude: -23.66389, longitude: -46.53833), // BR/São Paulo; GeoNames 3449701
        "geonames-9072919": .init(latitude: 35.41414, longitude: 119.52908), // CN/Shandong; GeoNames 9072919
        "geonames-1845759": .init(latitude: 36.8065, longitude: 127.1522), // KR/Chungcheongnam-do; GeoNames 1845759
        "geonames-3533462": .init(latitude: 16.84942, longitude: -99.90891), // MX/Guerrero; GeoNames 3533462
        "geonames-1650213": .init(latitude: -3.31987, longitude: 114.59075), // ID/South Kalimantan; GeoNames 1650213
        "geonames-1793900": .init(latitude: 30.50802, longitude: 105.57332), // CN/Sichuan; GeoNames 1793900
        "geonames-5907364": .init(latitude: 43.68341, longitude: -79.76633), // CA/Ontario; GeoNames 5907364
        "geonames-2591953": .init(latitude: -8.86639, longitude: 13.26173), // AO/Luanda; GeoNames 2591953
        "geonames-9181182": .init(latitude: 35.75641, longitude: 115.04363), // CN/Henan; GeoNames 9181182
        "geonames-3667905": .init(latitude: 4.57937, longitude: -74.21682), // CO/Cundinamarca; GeoNames 3667905
        "geonames-3515431": .init(latitude: 19.54005, longitude: -99.19538), // MX/México; GeoNames 3515431
        "geonames-5746545": .init(latitude: 45.52345, longitude: -122.67621), // US/Oregon; GeoNames 5746545
        "geonames-2242906": .init(latitude: -9.14692, longitude: 13.41936), // AO/Bengo; GeoNames 2242906
        "geonames-3981461": .init(latitude: 20.64121, longitude: -103.29342), // MX/Jalisco; GeoNames 3981461
        "geonames-554840": .init(latitude: 56.85225, longitude: 53.19862), // RU/Udmurtiya Republic; GeoNames 554840
        "geonames-3778045": .init(latitude: 9.74569, longitude: -63.18323), // VE/Monagas; GeoNames 3778045
        "geonames-1278718": .init(latitude: 20.93333, longitude: 77.75), // IN/Maharashtra; GeoNames 1278718
        "geonames-2036075": .init(latitude: 41.24, longitude: 119.40111), // CN/Liaoning; GeoNames 2036075
        "geonames-4990729": .init(latitude: 42.33143, longitude: -83.04575), // US/Michigan; GeoNames 4990729
        "geonames-2325590": .init(latitude: 7.77104, longitude: 4.55698), // NG/Osun State; GeoNames 2325590
        "geonames-1275665": .init(latitude: 28.01762, longitude: 73.31495), // IN/Rajasthan; GeoNames 1275665
        "geonames-6317344": .init(latitude: -8.11278, longitude: -35.01472), // BR/Pernambuco; GeoNames 6317344
        "geonames-13631351": .init(latitude: -8.80523, longitude: 13.2897), // AO/Luanda; GeoNames 13631351
        "geonames-5506956": .init(latitude: 36.17497, longitude: -115.13722), // US/Nevada; GeoNames 5506956
        "geonames-1843847": .init(latitude: 37.20682, longitude: 126.8169), // KR/Gyeonggi-do; GeoNames 1843847
        "geonames-2165087": .init(latitude: -28.00029, longitude: 153.43088), // AU/Queensland; GeoNames 2165087
        "geonames-3093133": .init(latitude: 51.77058, longitude: 19.47395), // PL/Łódź Voivodeship; GeoNames 3093133
        "geonames-1845457": .init(latitude: 35.82483, longitude: 127.14796), // KR/Jeollabuk-do; GeoNames 1845457
        "geonames-285839": .init(latitude: 29.07694, longitude: 48.08389), // KW/Al Aḩmadī; GeoNames 285839
        "geonames-922741": .init(latitude: -10.98303, longitude: 26.7384), // CD/Haut-Katanga; GeoNames 922741
        "geonames-1642858": .init(latitude: -1.6, longitude: 103.61667), // ID/Jambi; GeoNames 1642858
        "geonames-1808770": .init(latitude: 35.73231, longitude: 114.28616), // CN/Henan; GeoNames 1808770
        "geonames-1185186": .init(latitude: 23.46186, longitude: 91.18503), // BD/Chittagong; GeoNames 1185186
        "geonames-204953": .init(latitude: -6.41621, longitude: 20.79995), // CD/Kasai; GeoNames 204953
        "geonames-1180942": .init(latitude: 30.96621, longitude: 73.97908), // PK/Punjab; GeoNames 1180942
        "geonames-4641239": .init(latitude: 35.14953, longitude: -90.04898), // US/Tennessee; GeoNames 4641239
        "geonames-1805611": .init(latitude: 31.03361, longitude: 112.20472), // CN/Hubei; GeoNames 1805611
        "geonames-1510853": .init(latitude: 53.36199, longitude: 83.72786), // RU/Altai Krai; GeoNames 1510853
        "geonames-3693528": .init(latitude: -5.18192, longitude: -80.65715), // PE/Piura; GeoNames 3693528
        "geonames-2034714": .init(latitude: 43.16143, longitude: 124.37785), // CN/Jilin; GeoNames 2034714
        "geonames-1275971": .init(latitude: 21.20919, longitude: 81.4285), // IN/Chhattisgarh; GeoNames 1275971
        "geonames-901344": .init(latitude: -12.95867, longitude: 28.63659), // ZM/Copperbelt; GeoNames 901344
        "geonames-3465624": .init(latitude: -19.93167, longitude: -44.05361), // BR/Minas Gerais; GeoNames 3465624
        "geonames-479123": .init(latitude: 54.32824, longitude: 48.38657), // RU/Ulyanovsk; GeoNames 479123
        "geonames-2648579": .init(latitude: 55.86515, longitude: -4.25763), // GB/Scotland; GeoNames 2648579
        "geonames-4299276": .init(latitude: 38.25424, longitude: -85.75941), // US/Kentucky; GeoNames 4299276
        "geonames-1846918": .init(latitude: 37.32361, longitude: 126.82194), // KR/Gyeonggi-do; GeoNames 1846918
        "geonames-360761": .init(latitude: 31.03637, longitude: 31.38069), // EG/Dakahlia; GeoNames 360761
        "geonames-128226": .init(latitude: 34.31417, longitude: 47.065), // IR/Kermanshah Province; GeoNames 128226
        "geonames-1806096": .init(latitude: 36.28389, longitude: 120.00333), // CN/Shandong; GeoNames 1806096
        "geonames-2934246": .init(latitude: 51.22319, longitude: 6.77927), // DE/North Rhine-Westphalia; GeoNames 2934246
        "geonames-1793879": .init(latitude: 31.71111, longitude: 113.36306), // CN/Hubei; GeoNames 1793879
        "geonames-3587902": .init(latitude: 14.52512, longitude: -90.58544), // GT/Guatemala; GeoNames 3587902
        "geonames-2022890": .init(latitude: 48.46204, longitude: 135.0971), // RU/Khabarovsk; GeoNames 2022890
        "geonames-3465038": .init(latitude: -15.59611, longitude: -56.09667), // BR/Mato Grosso; GeoNames 3465038
        "geonames-3463478": .init(latitude: -12.26667, longitude: -38.96667), // BR/Bahia; GeoNames 3463478
        "geonames-1707174": .init(latitude: 14.45056, longitude: 120.98278), // PH/National Capital Region; GeoNames 1707174
        "geonames-1814934": .init(latitude: 30.66134, longitude: 117.47783), // CN/Anhui; GeoNames 1814934
        "geonames-3530139": .init(latitude: 19.3467, longitude: -99.16174), // MX/Mexico City; GeoNames 3530139
        "geonames-2825297": .init(latitude: 48.78232, longitude: 9.17702), // DE/Baden-Wurttemberg; GeoNames 2825297
        "geonames-1787816": .init(latitude: 29.98521, longitude: 102.999), // CN/Sichuan; GeoNames 1787816
        "geonames-1273780": .init(latitude: 20.46497, longitude: 85.87927), // IN/Odisha; GeoNames 1273780
        "geonames-1275248": .init(latitude: 19.23496, longitude: 72.85976), // IN/Maharashtra; GeoNames 1275248
        "geonames-3698350": .init(latitude: -6.77008, longitude: -79.85495), // PE/Lambayeque; GeoNames 3698350
        "geonames-468902": .init(latitude: 57.62987, longitude: 39.87368), // RU/Yaroslavl Oblast; GeoNames 468902
        "geonames-1859730": .init(latitude: 35.80521, longitude: 139.71072), // JP/Saitama; GeoNames 1859730
        "geonames-13118225": .init(latitude: 3.21727, longitude: 101.5608), // MY/Selangor; GeoNames 13118225
        "geonames-1175892": .init(latitude: 31.26981, longitude: 72.31687), // PK/Punjab; GeoNames 1175892
        "geonames-106281": .init(latitude: 27.52188, longitude: 41.69073), // SA/Ha'il Region; GeoNames 106281
        "geonames-1276032": .init(latitude: 21.76287, longitude: 72.15331), // IN/Gujarat; GeoNames 1276032
        "geonames-1020098": .init(latitude: -26.18848, longitude: 28.32078), // ZA/Gauteng; GeoNames 1020098
        "geonames-3515001": .init(latitude: 16.75357, longitude: -93.11578), // MX/Chiapas; GeoNames 3515001
        "geonames-703845": .init(latitude: 47.90572, longitude: 33.39404), // UA/Dnipropetrovsk; GeoNames 703845
        "geonames-1796663": .init(latitude: 26.24861, longitude: 117.61861), // CN/Fujian; GeoNames 1796663
        "geonames-1257416": .init(latitude: 16.85438, longitude: 74.56417), // IN/Maharashtra; GeoNames 1257416
        "geonames-1269317": .init(latitude: 22.47292, longitude: 70.06673), // IN/Gujarat; GeoNames 1269317
        "geonames-3347762": .init(latitude: -14.91717, longitude: 13.4925), // AO/Huíla; GeoNames 3347762
        "geonames-2034786": .init(latitude: 46.67686, longitude: 131.13273), // CN/Heilongjiang; GeoNames 2034786
        "geonames-64021": .init(latitude: 9.93611, longitude: 43.18278), // SO/Awdal; GeoNames 64021
        "geonames-1802204": .init(latitude: 37.88452, longitude: 114.64629), // CN/Hebei; GeoNames 1802204
        "geonames-532096": .init(latitude: 42.97782, longitude: 47.50027), // RU/Dagestan; GeoNames 532096
        "geonames-1846898": .init(latitude: 37.3925, longitude: 126.92694), // KR/Gyeonggi-do; GeoNames 1846898
        "geonames-3348313": .init(latitude: -12.77611, longitude: 15.73917), // AO/Huambo; GeoNames 3348313
        "geonames-13512502": .init(latitude: 23.36779, longitude: 103.38212), // CN/Yunnan; GeoNames 13512502
        "geonames-1860827": .init(latitude: 31.56667, longitude: 130.55), // JP/Kagoshima; GeoNames 1860827
        "geonames-78754": .init(latitude: 14.54248, longitude: 49.12424), // YE/Muhafazat Hadramaout; GeoNames 78754
        "geonames-118743": .init(latitude: 37.27611, longitude: 49.58862), // IR/Gilan Province; GeoNames 118743
        "geonames-3430863": .init(latitude: -38.00042, longitude: -57.5562), // AR/Buenos Aires; GeoNames 3430863
        "geonames-2928810": .init(latitude: 51.45657, longitude: 7.01228), // DE/North Rhine-Westphalia; GeoNames 2928810
        "geonames-360829": .init(latitude: 30.97063, longitude: 31.1669), // EG/Gharbia; GeoNames 360829
        "geonames-1165221": .init(latitude: 31.71287, longitude: 73.98556), // PK/Punjab; GeoNames 1165221
        "geonames-2033370": .init(latitude: 40.66472, longitude: 122.23176), // CN/Liaoning; GeoNames 2033370
        "geonames-1785018": .init(latitude: 24.51333, longitude: 117.65556), // CN/Fujian; GeoNames 1785018
        "geonames-3520339": .init(latitude: 26.08005, longitude: -98.28456), // MX/Tamaulipas; GeoNames 3520339
        "geonames-12382296": .init(latitude: 10.9239, longitude: 106.71428), // VN/Ho Chi Minh City (HCMC); GeoNames 12382296
        "geonames-2935517": .init(latitude: 51.51494, longitude: 7.466), // DE/North Rhine-Westphalia; GeoNames 2935517
        "geonames-4347778": .init(latitude: 39.29038, longitude: -76.61219), // US/Maryland; GeoNames 4347778
        "geonames-1732747": .init(latitude: 1.5243, longitude: 103.824), // MY/Johor; GeoNames 1732747
        "geonames-1646448": .init(latitude: -6.87222, longitude: 107.5425), // ID/West Java; GeoNames 1646448
        "geonames-3458449": .init(latitude: -23.31028, longitude: -51.16278), // BR/Paraná; GeoNames 3458449
        "geonames-3688465": .init(latitude: 7.125, longitude: -73.11895), // CO/Santander Department; GeoNames 3688465
        "geonames-3176219": .init(latitude: 44.40478, longitude: 8.94439), // IT/Liguria; GeoNames 3176219
        "geonames-1863440": .init(latitude: 35.65583, longitude: 139.32389), // JP/Tokyo; GeoNames 1863440
        "geonames-128234": .init(latitude: 30.28321, longitude: 57.07879), // IR/Kerman; GeoNames 128234
        "geonames-121801": .init(latitude: 37.55274, longitude: 45.07605), // IR/West Azerbaijan; GeoNames 121801
        "geonames-7627067": .init(latitude: 41.00231, longitude: 28.8598), // TR/Istanbul; GeoNames 7627067
        "geonames-347497": .init(latitude: 30.78847, longitude: 31.00192), // EG/Gharbia; GeoNames 347497
        "geonames-1269321": .init(latitude: 32.73528, longitude: 74.86167), // IN/Jammu and Kashmir; GeoNames 1269321
        "geonames-10063567": .init(latitude: 1.39324, longitude: 103.62322), // MY/Johor; GeoNames 10063567
        "geonames-1720681": .init(latitude: 14.21167, longitude: 121.16528), // PH/Calabarzon; GeoNames 1720681
        "geonames-3515428": .init(latitude: 19.29513, longitude: -99.16206), // MX/Mexico City; GeoNames 3515428
        "geonames-1140026": .init(latitude: 34.34817, longitude: 62.19967), // AF/Herat; GeoNames 1140026
        "geonames-1177654": .init(latitude: 32.5742, longitude: 74.07542), // PK/Punjab; GeoNames 1177654
        "geonames-1489425": .init(latitude: 56.50049, longitude: 84.98216), // RU/Tomsk Oblast; GeoNames 1489425
        "geonames-738377": .init(latitude: 41.01643, longitude: 29.12476), // TR/Istanbul; GeoNames 738377
        "geonames-1529195": .init(latitude: 44.3023, longitude: 86.03694), // CN/Xinjiang; GeoNames 1529195
        "geonames-184622": .init(latitude: -0.30719, longitude: 36.07225), // KE/Nakuru County; GeoNames 184622
        "geonames-5969782": .init(latitude: 43.25011, longitude: -79.84963), // CA/Ontario; GeoNames 5969782
        "geonames-248946": .init(latitude: 32.55556, longitude: 35.85), // JO/Irbid; GeoNames 248946
        "geonames-1736376": .init(latitude: 6.12361, longitude: 102.24333), // MY/Kelantan; GeoNames 1736376
        "geonames-6159905": .init(latitude: 49.10635, longitude: -122.82509), // CA/British Columbia; GeoNames 6159905
        "geonames-2542715": .init(latitude: 33.89352, longitude: -5.54727), // MA/Fes-Meknes; GeoNames 2542715
        "geonames-3875024": .init(latitude: -33.61169, longitude: -70.57577), // CL/Santiago Metropolitan; GeoNames 3875024
        "geonames-369004": .init(latitude: 12.04888, longitude: 24.88069), // SD/Southern Darfur; GeoNames 369004
        "geonames-2935022": .init(latitude: 51.05089, longitude: 13.73832), // DE/Saxony; GeoNames 2935022
        "geonames-515003": .init(latitude: 51.76712, longitude: 55.09883), // RU/Orenburg Oblast; GeoNames 515003
        "geonames-5454711": .init(latitude: 35.08449, longitude: -106.65114), // US/New Mexico; GeoNames 5454711
        "geonames-1275362": .init(latitude: 23.66934, longitude: 86.15161), // IN/Jharkhand; GeoNames 1275362
        "geonames-1164408": .init(latitude: 27.70323, longitude: 68.85889), // PK/Sindh; GeoNames 1164408
        "geonames-5263045": .init(latitude: 43.0389, longitude: -87.90647), // US/Wisconsin; GeoNames 5263045
        "geonames-2338900": .init(latitude: 7.4824, longitude: 4.56032), // NG/Osun State; GeoNames 2338900
        "geonames-2340451": .init(latitude: 10.28969, longitude: 11.16729), // NG/Gombe State; GeoNames 2340451
        "geonames-1877449": .init(latitude: 39.91833, longitude: 127.53639), // KP/South Hamgyong; GeoNames 1877449
        "geonames-1503901": .init(latitude: 55.35417, longitude: 86.10435), // RU/Kuzbass; GeoNames 1503901
        "geonames-98854": .init(latitude: 31.05799, longitude: 46.25726), // IQ/Dhi Qar; GeoNames 98854
        "geonames-1018725": .init(latitude: -29.12107, longitude: 26.214), // ZA/Free State; GeoNames 1018725
        "geonames-2638077": .init(latitude: 53.38297, longitude: -1.4659), // GB/England; GeoNames 2638077
        "geonames-3515807": .init(latitude: 19.64388, longitude: -99.21598), // MX/México; GeoNames 3515807
        "geonames-3351663": .init(latitude: -12.57674, longitude: 13.40268), // AO/Benguela; GeoNames 3351663
        "geonames-7648070": .init(latitude: 11.56194, longitude: 43.10666), // DJ/Djibouti; GeoNames 7648070
        "geonames-1699076": .init(latitude: 14.39028, longitude: 121.0475), // PH/Calabarzon; GeoNames 1699076
        "geonames-1159301": .init(latitude: 29.4963, longitude: 60.8629), // IR/Sistan and Baluchestan; GeoNames 1159301
        "geonames-1670029": .init(latitude: 25.01427, longitude: 121.46719), // TW/Taipei; GeoNames 1670029
        "geonames-1261977": .init(latitude: 19.16023, longitude: 77.31497), // IN/Maharashtra; GeoNames 1261977
        "geonames-1265873": .init(latitude: 11.24802, longitude: 75.7804), // IN/Kerala; GeoNames 1265873
        "geonames-2243271": .init(latitude: -5.56198, longitude: 12.19476), // AO/Cabinda; GeoNames 2243271
        "geonames-2566636": .init(latitude: 6.45197, longitude: 3.33115), // NG/Lagos; GeoNames 2566636
        "geonames-10276592": .init(latitude: 4.68836, longitude: 6.31525), // NG/Bayelsa State; GeoNames 10276592
        "geonames-2036581": .init(latitude: 46.79711, longitude: 130.31118), // CN/Heilongjiang; GeoNames 2036581
        "geonames-1529376": .init(latitude: 41.76055, longitude: 86.15231), // CN/Xinjiang; GeoNames 1529376
        "geonames-1266285": .init(latitude: 16.69563, longitude: 74.23167), // IN/Maharashtra; GeoNames 1266285
        "geonames-3662762": .init(latitude: -8.76194, longitude: -63.90389), // BR/Rondônia; GeoNames 3662762
        "geonames-3836873": .init(latitude: -26.81601, longitude: -65.21051), // AR/Tucuman; GeoNames 3836873
        "geonames-1735227": .init(latitude: 3.8077, longitude: 103.326), // MY/Pahang; GeoNames 1735227
        "geonames-694423": .init(latitude: 44.60795, longitude: 33.52134), // UA/Sevastopol City; GeoNames 694423
        "geonames-1261529": .init(latitude: 14.44992, longitude: 79.98697), // IN/Andhra Pradesh; GeoNames 1261529
        "geonames-2944388": .init(latitude: 53.07582, longitude: 8.80717), // DE/Bremen; GeoNames 2944388
        "geonames-2325330": .init(latitude: 5.48363, longitude: 7.03325), // NG/Imo State; GeoNames 2325330
        "geonames-6847550": .init(latitude: 5.58822, longitude: 100.37085), // MY/Kedah; GeoNames 6847550
        "geonames-1735498": .init(latitude: 5.647, longitude: 100.48772), // MY/Kedah; GeoNames 1735498
        "geonames-11209896": .init(latitude: 32.77856, longitude: 130.74537), // JP/Kumamoto; GeoNames 11209896
        "geonames-1270752": .init(latitude: 17.33583, longitude: 76.83757), // IN/Karnataka; GeoNames 1270752
        "geonames-5318313": .init(latitude: 32.22174, longitude: -110.92648), // US/Arizona; GeoNames 5318313
        "geonames-7795834": .init(latitude: 3.2549, longitude: 101.6668), // MY/Selangor; GeoNames 7795834
        "geonames-1279159": .init(latitude: 26.4521, longitude: 74.63867), // IN/Rajasthan; GeoNames 1279159
        "geonames-5350937": .init(latitude: 36.74773, longitude: -119.77237), // US/California; GeoNames 5350937
        "geonames-154380": .init(latitude: -8.9, longitude: 33.45), // TZ/Mbeya; GeoNames 154380
        "geonames-3459505": .init(latitude: -21.76417, longitude: -43.35028), // BR/Minas Gerais; GeoNames 3459505
        "geonames-2346229": .init(latitude: 4.95893, longitude: 8.32695), // NG/Cross River State; GeoNames 2346229
        "geonames-2540483": .init(latitude: 34.68139, longitude: -1.90858), // MA/Oriental; GeoNames 2540483
        "geonames-1496990": .init(latitude: 53.75752, longitude: 87.13599), // RU/Kuzbass; GeoNames 1496990
        "geonames-500096": .init(latitude: 54.62696, longitude: 39.70415), // RU/Ryazan Oblast; GeoNames 500096
        "geonames-1166547": .init(latitude: 31.97386, longitude: 72.33109), // PK/Punjab; GeoNames 1166547
        "geonames-1166548": .init(latitude: 30.66595, longitude: 73.10186), // PK/Punjab; GeoNames 1166548
        "geonames-304531": .init(latitude: 36.81196, longitude: 34.63886), // TR/Mersin; GeoNames 304531
        "geonames-10346824": .init(latitude: 40.21401, longitude: 28.91567), // TR/Bursa Province; GeoNames 10346824
        "geonames-2644688": .init(latitude: 53.79648, longitude: -1.54785), // GB/England; GeoNames 2644688
        "geonames-3088171": .init(latitude: 52.40692, longitude: 16.92993), // PL/Greater Poland; GeoNames 3088171
        "geonames-1529660": .init(latitude: 41.18418, longitude: 80.27921), // CN/Xinjiang; GeoNames 1529660
        "geonames-2344082": .init(latitude: 6.60086, longitude: 3.48818), // NG/Lagos; GeoNames 2344082
        "geonames-3407669": .init(latitude: -1.36556, longitude: -48.37222), // BR/Pará; GeoNames 3407669
        "geonames-1732722": .init(latitude: 1.462, longitude: 103.9053), // MY/Johor; GeoNames 1732722
        "geonames-580497": .init(latitude: 46.34968, longitude: 48.04076), // RU/Astrakhan Oblast; GeoNames 580497
        "geonames-1168718": .init(latitude: 30.81029, longitude: 73.45155), // PK/Punjab; GeoNames 1168718
        "geonames-10943053": .init(latitude: 0.36389, longitude: 32.52861), // UG/Central Region; GeoNames 10943053
        "geonames-1842943": .init(latitude: 35.23417, longitude: 128.88111), // KR/Gyeongsangnam-do; GeoNames 1842943
        "geonames-172955": .init(latitude: 35.95283, longitude: 39.00788), // SY/Raqqa; GeoNames 172955
        "geonames-3827409": .init(latitude: 19.44506, longitude: -99.14612), // MX/Mexico City; GeoNames 3827409
        "geonames-1862627": .init(latitude: 34.81667, longitude: 134.7), // JP/Hyōgo; GeoNames 1862627
        "geonames-3680656": .init(latitude: 4.43573, longitude: -75.20289), // CO/Tolima Department; GeoNames 3680656
        "geonames-359783": .init(latitude: 27.18096, longitude: 31.18368), // EG/Asyut; GeoNames 359783
        "geonames-132144": .init(latitude: 34.79922, longitude: 48.51456), // IR/Hamadan Province; GeoNames 132144
        "geonames-6316406": .init(latitude: -16.82333, longitude: -49.24389), // BR/Goiás; GeoNames 6316406
        "geonames-1194041": .init(latitude: 24.89843, longitude: 88.52844), // BD/Rajshahi Division; GeoNames 1194041
        "geonames-1625812": .init(latitude: -7.55611, longitude: 110.83167), // ID/Central Java; GeoNames 1625812
        "geonames-298117": .init(latitude: 38.49457, longitude: 43.38323), // TR/Van; GeoNames 298117
        "geonames-5389489": .init(latitude: 38.58157, longitude: -121.4944), // US/California; GeoNames 5389489
        "geonames-1565019": .init(latitude: 10.84863, longitude: 106.77209), // VN/Ho Chi Minh City (HCMC); GeoNames 1565019
        "geonames-738329": .init(latitude: 41.02274, longitude: 29.01366), // TR/Istanbul; GeoNames 738329
        "geonames-511565": .init(latitude: 53.19568, longitude: 45.01075), // RU/Penza Oblast; GeoNames 511565
        "geonames-1133616": .init(latitude: 36.70904, longitude: 67.11087), // AF/Balkh; GeoNames 1133616
        "geonames-1138336": .init(latitude: 31.61332, longitude: 65.71013), // AF/Kandahar; GeoNames 1138336
        "geonames-1273313": .init(latitude: 30.32443, longitude: 78.03392), // IN/Uttarakhand; GeoNames 1273313
        "geonames-1272013": .init(latitude: 11.3428, longitude: 77.72741), // IN/Tamil Nadu; GeoNames 1272013
        "geonames-3838233": .init(latitude: -24.80645, longitude: -65.41999), // AR/Salta; GeoNames 3838233
        "geonames-3447779": .init(latitude: -20.12861, longitude: -40.30778), // BR/Espírito Santo; GeoNames 3447779
        "geonames-747340": .init(latitude: 41.0435, longitude: 28.87619), // TR/Istanbul; GeoNames 747340
        "geonames-1568574": .init(latitude: 13.77648, longitude: 109.22367), // VN/Gia Lai; GeoNames 1568574
        "geonames-361320": .init(latitude: 29.30995, longitude: 30.8418), // EG/Faiyum; GeoNames 361320
        "geonames-1272175": .init(latitude: 23.51583, longitude: 87.30801), // IN/West Bengal; GeoNames 1272175
        "geonames-1849053": .init(latitude: 36.56667, longitude: 139.88333), // JP/Tochigi; GeoNames 1849053
        "geonames-4011743": .init(latitude: 24.02032, longitude: -104.65756), // MX/Durango; GeoNames 4011743
        "geonames-3470142": .init(latitude: -22.76417, longitude: -43.39944), // BR/Rio de Janeiro; GeoNames 3470142
        "geonames-1167460": .init(latitude: 28.41987, longitude: 70.30345), // PK/Punjab; GeoNames 1167460
        "geonames-1253894": .init(latitude: 19.21667, longitude: 73.15), // IN/Maharashtra; GeoNames 1253894
        "geonames-1264773": .init(latitude: 28.75143, longitude: 77.29023), // IN/Uttar Pradesh; GeoNames 1264773
        "geonames-1256525": .init(latitude: 26.71004, longitude: 88.42851), // IN/West Bengal; GeoNames 1256525
        "geonames-2861650": .init(latitude: 49.45421, longitude: 11.07752), // DE/Bavaria; GeoNames 2861650
        "geonames-3456283": .init(latitude: -22.88333, longitude: -43.10361), // BR/Rio de Janeiro; GeoNames 3456283
        "geonames-1253914": .init(latitude: 23.18239, longitude: 75.77643), // IN/Madhya Pradesh; GeoNames 1253914
        "geonames-2910831": .init(latitude: 52.37052, longitude: 9.73322), // DE/Lower Saxony; GeoNames 2910831
        "geonames-3396016": .init(latitude: 0.03889, longitude: -51.06639), // BR/Amapá; GeoNames 3396016
        "geonames-949880": .init(latitude: -25.99636, longitude: 28.2268), // ZA/Gauteng; GeoNames 949880
        "geonames-6201369": .init(latitude: 18.53333, longitude: -72.4), // HT/Ouest; GeoNames 6201369
        "geonames-1926099": .init(latitude: 33.83916, longitude: 132.76574), // JP/Ehime; GeoNames 1926099
        "geonames-1275610": .init(latitude: 20.76957, longitude: 72.96134), // IN/Gujarat; GeoNames 1275610
        "geonames-1174625": .init(latitude: 31.11866, longitude: 74.45025), // PK/Punjab; GeoNames 1174625
        "geonames-3523466": .init(latitude: 25.87972, longitude: -97.50417), // MX/Tamaulipas; GeoNames 3523466
        "geonames-1703417": .init(latitude: 14.55027, longitude: 121.03269), // PH/National Capital Region; GeoNames 1703417
        "geonames-523750": .init(latitude: 55.73718, longitude: 52.41961), // RU/Tatarstan Republic; GeoNames 523750
        "geonames-535121": .init(latitude: 52.5876, longitude: 39.55151), // RU/Lipetsk Oblast; GeoNames 535121
        "geonames-2314705": .init(latitude: -5.04098, longitude: 18.81619), // CD/Kwilu; GeoNames 2314705
        "geonames-1818446": .init(latitude: 22.39175, longitude: 113.97157), // HK/Tuen Mun; GeoNames 1818446
        "geonames-1785036": .init(latitude: 38.93417, longitude: 100.45167), // CN/Gansu; GeoNames 1785036
        "geonames-548408": .init(latitude: 58.59809, longitude: 49.65783), // RU/Kirov Oblast; GeoNames 548408
        "geonames-1280849": .init(latitude: 39.46718, longitude: 75.98675), // CN/Xinjiang; GeoNames 1280849
        "geonames-12750654": .init(latitude: 1.53333, longitude: 103.66667), // MY/Johor; GeoNames 12750654
        "geonames-103630": .init(latitude: 17.49326, longitude: 44.12766), // SA/Najran Region; GeoNames 103630
        "geonames-2879139": .init(latitude: 51.33962, longitude: 12.37129), // DE/Saxony; GeoNames 2879139
        "geonames-2934691": .init(latitude: 51.43247, longitude: 6.76516), // DE/North Rhine-Westphalia; GeoNames 2934691
        "geonames-1278314": .init(latitude: 23.68333, longitude: 86.98333), // IN/West Bengal; GeoNames 1278314
        "geonames-143127": .init(latitude: 34.09493, longitude: 49.69809), // IR/Markazi; GeoNames 143127
        "geonames-3880980": .init(latitude: -33.51421, longitude: -70.7651), // CL/Santiago Metropolitan; GeoNames 3880980
        "geonames-627907": .init(latitude: 52.4345, longitude: 30.9754), // BY/Homyel’ Voblasc’; GeoNames 627907
        "geonames-610611": .init(latitude: 50.27969, longitude: 57.20718), // KZ/Aktobe; GeoNames 610611
        "geonames-1176358": .init(latitude: 29.5051, longitude: 71.22202), // PK/Punjab; GeoNames 1176358
        "geonames-1732724": .init(latitude: 1.5024, longitude: 103.744), // MY/Johor; GeoNames 1732724
        "geonames-2591976": .init(latitude: -8.91783, longitude: 13.18562), // AO/Luanda; GeoNames 2591976
        "geonames-12514556": .init(latitude: 3.15454, longitude: 101.58022), // MY/Selangor; GeoNames 12514556
        "geonames-1263780": .init(latitude: 12.91723, longitude: 74.85603), // IN/Karnataka; GeoNames 1263780
        "geonames-3668605": .init(latitude: 11.23855, longitude: -74.19427), // CO/Magdalena Department; GeoNames 3668605
        "geonames-1857553": .init(latitude: 35.77995, longitude: 139.90144), // JP/Chiba; GeoNames 1857553
        "geonames-1462674": .init(latitude: 22.50515, longitude: 91.81339), // BD/Chittagong; GeoNames 1462674
        "geonames-1707267": .init(latitude: 10.31028, longitude: 123.94944), // PH/Central Visayas; GeoNames 1707267
        "geonames-609655": .init(latitude: 49.80187, longitude: 73.10211), // KZ/Karaganda; GeoNames 609655
        "geonames-2644210": .init(latitude: 53.41058, longitude: -2.97794), // GB/England; GeoNames 2644210
        "geonames-1818920": .init(latitude: 22.38333, longitude: 114.18333), // HK/Sha Tin; GeoNames 1818920
        "geonames-1180289": .init(latitude: 30.04587, longitude: 70.64029), // PK/Punjab; GeoNames 1180289
        "geonames-1862752": .init(latitude: 34.66667, longitude: 135.58333), // JP/Osaka; GeoNames 1862752
        "geonames-1168021": .init(latitude: 31.89844, longitude: 73.27339), // PK/Punjab; GeoNames 1168021
        "geonames-569696": .init(latitude: 56.13218, longitude: 47.246), // RU/Chuvash Republic; GeoNames 569696
        "geonames-1839071": .init(latitude: 36.02917, longitude: 129.36481), // KR/Gyeongsangbuk-do; GeoNames 1839071
        "geonames-3674453": .init(latitude: 8.75081, longitude: -75.87823), // CO/Córdoba; GeoNames 3674453
        "geonames-181032": .init(latitude: -1.14665, longitude: 36.96087), // KE/Kiambu County; GeoNames 181032
        "geonames-3666304": .init(latitude: 10.46538, longitude: -73.2531), // CO/Cesar Department; GeoNames 3666304
        "geonames-1276533": .init(latitude: 15.85212, longitude: 74.50447), // IN/Karnataka; GeoNames 1276533
        "geonames-292932": .init(latitude: 25.40177, longitude: 55.47878), // AE/Ajman; GeoNames 292932
        "geonames-7628420": .init(latitude: 41.00244, longitude: 29.23187), // TR/Istanbul; GeoNames 7628420
        "geonames-377039": .init(latitude: 19.61745, longitude: 37.21644), // SD/Red Sea; GeoNames 377039
        "geonames-3515302": .init(latitude: 19.28786, longitude: -99.65324), // MX/México; GeoNames 3515302
        "geonames-3532624": .init(latitude: 19.54367, longitude: -99.23449), // MX/México; GeoNames 3532624
        "geonames-360890": .init(latitude: 30.15293, longitude: 31.31501), // EG/Qalyubia; GeoNames 360890
        "geonames-5074472": .init(latitude: 41.25626, longitude: -95.94043), // US/Nebraska; GeoNames 5074472
        "geonames-1855207": .init(latitude: 34.71562, longitude: 135.33199), // JP/Hyōgo; GeoNames 1855207
        "geonames-2593460": .init(latitude: -4.38361, longitude: 15.39139), // CD/Kinshasa; GeoNames 2593460
        "geonames-1257806": .init(latitude: 29.9679, longitude: 77.54522), // IN/Uttar Pradesh; GeoNames 1257806
        "geonames-1253286": .init(latitude: 12.9184, longitude: 79.13255), // IN/Tamil Nadu; GeoNames 1253286
        "geonames-1858311": .init(latitude: 34.58333, longitude: 133.76667), // JP/Okayama; GeoNames 1858311
        "geonames-3467693": .init(latitude: -21.75227, longitude: -41.33044), // BR/Rio de Janeiro; GeoNames 3467693
        "geonames-1730737": .init(latitude: 15.15, longitude: 120.58333), // PH/Central Luzon; GeoNames 1730737
        "geonames-1276058": .init(latitude: 22.86643, longitude: 88.40113), // IN/West Bengal; GeoNames 1276058
        "geonames-333795": .init(latitude: 9.35, longitude: 42.8), // ET/Somali; GeoNames 333795
        "geonames-480562": .init(latitude: 54.19609, longitude: 37.61822), // RU/Tula Oblast; GeoNames 480562
        "geonames-98860": .init(latitude: 32.02594, longitude: 44.34625), // IQ/Najaf; GeoNames 98860
        "geonames-4487042": .init(latitude: 35.7721, longitude: -78.63861), // US/North Carolina; GeoNames 4487042
        "geonames-1710914": .init(latitude: 14.42972, longitude: 120.93667), // PH/Calabarzon; GeoNames 1710914
        "geonames-1789647": .init(latitude: 27.89642, longitude: 102.26341), // CN/Sichuan; GeoNames 1789647
        "geonames-1264115": .init(latitude: 20.54966, longitude: 74.53462), // IN/Maharashtra; GeoNames 1264115
        "geonames-3448639": .init(latitude: -20.81972, longitude: -49.37944), // BR/São Paulo; GeoNames 3448639
        "geonames-3466537": .init(latitude: -29.16806, longitude: -51.17944), // BR/Rio Grande do Sul; GeoNames 3466537
        "geonames-7701384": .init(latitude: 38.382, longitude: 27.132), // TR/İzmir Province; GeoNames 7701384
        "geonames-2327220": .init(latitude: 7.55122, longitude: 6.23589), // NG/Kogi State; GeoNames 2327220
        "geonames-1833788": .init(latitude: 37.7415, longitude: 127.0474), // KR/Gyeonggi-do; GeoNames 1833788
        "geonames-2654675": .init(latitude: 51.45523, longitude: -2.59665), // GB/England; GeoNames 2654675
        "geonames-1006984": .init(latitude: -33.01529, longitude: 27.91162), // ZA/Eastern Cape; GeoNames 1006984
        "geonames-111822": .init(latitude: 31.89722, longitude: 54.3675), // IR/Yazd Province; GeoNames 111822
        "geonames-57289": .init(latitude: 9.56, longitude: 44.065), // SO/Woqooyi Galbeed; GeoNames 57289
        "geonames-1854487": .init(latitude: 33.23333, longitude: 131.6), // JP/Oita; GeoNames 1854487
        "geonames-8440756": .init(latitude: 28.83059, longitude: 77.57295), // IN/Uttar Pradesh; GeoNames 8440756
        "geonames-6696918": .init(latitude: 24.99368, longitude: 121.29696), // TW/Taiwan; GeoNames 6696918
        "geonames-198629": .init(latitude: 0.52036, longitude: 35.26993), // KE/Uasin Gishu County; GeoNames 198629
        "geonames-4393217": .init(latitude: 39.09973, longitude: -94.57857), // US/Missouri; GeoNames 4393217
        "geonames-2057087": .init(latitude: -10.17083, longitude: 123.60694), // ID/East Nusa Tenggara; GeoNames 2057087
        "geonames-944385": .init(latitude: -26.67313, longitude: 27.92615), // ZA/Gauteng; GeoNames 944385
        "geonames-2747373": .init(latitude: 52.07667, longitude: 4.29861), // NL/South Holland; GeoNames 2747373
        "geonames-5367929": .init(latitude: 33.76696, longitude: -118.18923), // US/California; GeoNames 5367929
        "geonames-1271439": .init(latitude: 24.79686, longitude: 85.00385), // IN/Bihar; GeoNames 1271439
        "geonames-2513416": .init(latitude: 37.98704, longitude: -1.13004), // ES/Murcia; GeoNames 2513416
        "geonames-5304391": .init(latitude: 33.42227, longitude: -111.82264), // US/Arizona; GeoNames 5304391
        "geonames-153220": .init(latitude: -6.82102, longitude: 37.66122), // TZ/Morogoro; GeoNames 153220
        "geonames-1700925": .init(latitude: 14.6481, longitude: 121.1133), // PH/National Capital Region; GeoNames 1700925
        "geonames-2544571": .init(latitude: 34.26101, longitude: -6.5802), // MA/Rabat-Salé-Kénitra; GeoNames 2544571
        "geonames-288967": .init(latitude: 23.67027, longitude: 58.18911), // OM/Muscat; GeoNames 288967
        "geonames-1646511": .init(latitude: -6.0144, longitude: 106.0542), // ID/Banten; GeoNames 1646511
        "geonames-700569": .init(latitude: 46.97625, longitude: 31.99296), // UA/Mykolaiv; GeoNames 700569
        "geonames-1863917": .init(latitude: 34.48333, longitude: 133.36667), // JP/Hiroshima; GeoNames 1863917
        "geonames-5139568": .init(latitude: 40.56233, longitude: -74.13986), // US/New York; GeoNames 5139568
        "geonames-3672486": .init(latitude: 4.81428, longitude: -75.69488), // CO/Risaralda Department; GeoNames 3672486
        "geonames-4018390": .init(latitude: 25.78143, longitude: -100.18911), // MX/Nuevo León; GeoNames 4018390
        "geonames-3448877": .init(latitude: -22.80389, longitude: -43.37222), // BR/Rio de Janeiro; GeoNames 3448877
        "geonames-1701966": .init(latitude: 14.5832, longitude: 121.0409), // PH/National Capital Region; GeoNames 1701966
        "geonames-3592519": .init(latitude: 14.63077, longitude: -90.60711), // GT/Guatemala; GeoNames 3592519
        "geonames-1840898": .init(latitude: 37.761, longitude: 126.77272), // KR/Gyeonggi-do; GeoNames 1840898
        "geonames-2338325": .init(latitude: 7.52591, longitude: 5.75342), // NG/Ondo State; GeoNames 2338325
        "geonames-11592397": .init(latitude: -8.90552, longitude: 13.22213), // AO/Luanda; GeoNames 11592397
        "geonames-1562414": .init(latitude: 10.34599, longitude: 107.08426), // VN/Ho Chi Minh City (HCMC); GeoNames 1562414
        "geonames-3632998": .init(latitude: 10.24972, longitude: -67.59475), // VE/Aragua; GeoNames 3632998
        "geonames-2294877": .init(latitude: 9.40079, longitude: -0.8393), // GH/Northern; GeoNames 2294877
        "geonames-1583518": .init(latitude: 10.90682, longitude: 106.7694), // VN/Ho Chi Minh City (HCMC); GeoNames 1583518
        "geonames-231165": .init(latitude: 0.4, longitude: 32.63333), // UG/Central Region; GeoNames 231165
        "geonames-355449": .init(latitude: 25.29336, longitude: 32.55402), // EG/Qena; GeoNames 355449
        "geonames-170017": .init(latitude: 35.13179, longitude: 36.75783), // SY/Hama; GeoNames 170017
        "geonames-1265491": .init(latitude: 15.82887, longitude: 78.03602), // IN/Andhra Pradesh; GeoNames 1265491
        "geonames-2318044": .init(latitude: 9.20839, longitude: 12.48146), // NG/Adamawa; GeoNames 2318044
        "geonames-1568510": .init(latitude: 10.01245, longitude: 105.08091), // VN/An Giang; GeoNames 1568510
        "geonames-1865387": .init(latitude: 34.71667, longitude: 135.41667), // JP/Hyōgo; GeoNames 1865387
        "geonames-3651297": .init(latitude: -0.25368, longitude: -79.17628), // EC/Santo Domingo de los Tsáchilas; GeoNames 3651297
        "geonames-163345": .init(latitude: 34.88902, longitude: 35.88659), // SY/Tartus; GeoNames 163345
        "geonames-331180": .init(latitude: 13.49667, longitude: 39.47528), // ET/Tigray; GeoNames 331180
        "geonames-330186": .init(latitude: 8.55, longitude: 39.26667), // ET/Oromiya; GeoNames 330186
        "geonames-5417598": .init(latitude: 38.83388, longitude: -104.82136), // US/Colorado; GeoNames 5417598
        "geonames-3939459": .init(latitude: -12.06866, longitude: -75.21027), // PE/Junin; GeoNames 3939459
        "geonames-99347": .init(latitude: 32.46367, longitude: 44.41963), // IQ/Babil; GeoNames 99347
        "geonames-2312895": .init(latitude: 0.04865, longitude: 18.26034), // CD/Équateur; GeoNames 2312895
        "geonames-1873757": .init(latitude: 38.7375, longitude: 125.40778), // KP/Nampo; GeoNames 1873757
        "geonames-2239862": .init(latitude: -9.54015, longitude: 16.34096), // AO/Malanje; GeoNames 2239862
        "geonames-4005867": .init(latitude: 25.79663, longitude: -100.31767), // MX/Nuevo León; GeoNames 4005867
        "geonames-1729564": .init(latitude: 10.66667, longitude: 122.95), // PH/Western Visayas; GeoNames 1729564
        "geonames-4791259": .init(latitude: 36.85293, longitude: -75.97799), // US/Virginia; GeoNames 4791259
        "geonames-1701500": .init(latitude: 10.63111, longitude: 122.97889), // PH/Western Visayas; GeoNames 1701500
        "geonames-158597": .init(latitude: -3.83333, longitude: 32.6), // TZ/Shinyanga; GeoNames 158597
        "geonames-1675151": .init(latitude: 24.80361, longitude: 120.96861), // TW/Taiwan; GeoNames 1675151
        "geonames-8469284": .init(latitude: 35.73333, longitude: 139.85), // JP/Tokyo; GeoNames 8469284
        "geonames-320857": .init(latitude: 38.47921, longitude: 27.2399), // TR/İzmir Province; GeoNames 320857
        "geonames-321836": .init(latitude: 37.88738, longitude: 41.13221), // TR/Batman; GeoNames 321836
        "geonames-326282": .init(latitude: 6.97444, longitude: 45.34083), // ET/Somali; GeoNames 326282
        "geonames-449504": .init(latitude: 35.55222, longitude: 51.23504), // IR/Tehran; GeoNames 449504
        "geonames-1591527": .init(latitude: 21.27307, longitude: 106.1946), // VN/Bac Ninh; GeoNames 1591527
        "geonames-8074174": .init(latitude: 36.89157, longitude: 30.76498), // TR/Antalya; GeoNames 8074174
        "geonames-298333": .init(latitude: 37.16708, longitude: 38.79392), // TR/Şanlıurfa; GeoNames 298333
        "geonames-538560": .init(latitude: 51.72689, longitude: 36.18457), // RU/Kursk Oblast; GeoNames 538560
        "geonames-1573517": .init(latitude: 20.43389, longitude: 106.17729), // VN/Ninh Binh; GeoNames 1573517
        "geonames-2501152": .init(latitude: 36.365, longitude: 6.61472), // DZ/Constantine; GeoNames 2501152
        "geonames-1017780": .init(latitude: -26.21197, longitude: 28.25958), // ZA/Gauteng; GeoNames 1017780
        "geonames-3403642": .init(latitude: -7.23056, longitude: -35.88111), // BR/Paraíba; GeoNames 3403642
        "geonames-4006702": .init(latitude: 31.87149, longitude: -116.60071), // MX/Baja California; GeoNames 4006702
        "geonames-315808": .init(latitude: 38.67431, longitude: 39.22321), // TR/Elazığ; GeoNames 315808
        "geonames-3459462": .init(latitude: -23.18639, longitude: -46.88417), // BR/São Paulo; GeoNames 3459462
        "geonames-3514450": .init(latitude: 19.25465, longitude: -99.10356), // MX/Mexico City; GeoNames 3514450
        "geonames-1715430": .init(latitude: 14.32944, longitude: 120.93667), // PH/Calabarzon; GeoNames 1715430
        "geonames-2286304": .init(latitude: 9.45803, longitude: -5.62961), // CI/Savanes District; GeoNames 2286304
        "geonames-3453643": .init(latitude: -22.72528, longitude: -47.64917), // BR/São Paulo; GeoNames 3453643
        "geonames-1864092": .init(latitude: 35.34926, longitude: 139.47666), // JP/Kanagawa; GeoNames 1864092
        "geonames-1734052": .init(latitude: 5.8402, longitude: 118.1179), // MY/Sabah; GeoNames 1734052
        "geonames-1308465": .init(latitude: 16.49051, longitude: 97.62825), // MM/Mon; GeoNames 1308465
        "geonames-6050610": .init(latitude: 45.56995, longitude: -73.692), // CA/Quebec; GeoNames 6050610
        "geonames-3456814": .init(latitude: -16.735, longitude: -43.86167), // BR/Minas Gerais; GeoNames 3456814
        "geonames-1869012": .init(latitude: 39.43167, longitude: 125.93278), // KP/South Pyongan; GeoNames 1869012
        "geonames-7628416": .init(latitude: 41.10652, longitude: 28.86847), // TR/Istanbul; GeoNames 7628416
        "geonames-2319480": .init(latitude: 5.05127, longitude: 7.9335), // NG/Akwa Ibom State; GeoNames 2319480
        "geonames-2352379": .init(latitude: 7.62329, longitude: 5.22087), // NG/Ekiti State; GeoNames 2352379
        "geonames-3675443": .init(latitude: 5.0668, longitude: -75.50684), // CO/Caldas Department; GeoNames 3675443
        "geonames-1841246": .init(latitude: 35.12725, longitude: 126.83149), // KR/Gwangju; GeoNames 1841246
        "geonames-1586896": .init(latitude: 12.66747, longitude: 108.03775), // VN/Dak Lak; GeoNames 1586896
        "geonames-487846": .init(latitude: 45.03442, longitude: 41.9642), // RU/Stavropol Kray; GeoNames 487846
        "geonames-1859924": .init(latitude: 35.86224, longitude: 139.97732), // JP/Chiba; GeoNames 1859924
        "geonames-2327735": .init(latitude: 8.13373, longitude: 4.24014), // NG/Oyo State; GeoNames 2327735
        "geonames-3688452": .init(latitude: 3.58333, longitude: -77), // CO/Valle del Cauca Department; GeoNames 3688452
        "geonames-940909": .init(latitude: -27.97742, longitude: 26.73506), // ZA/Free State; GeoNames 940909
        "geonames-1818953": .init(latitude: 22.33023, longitude: 114.15945), // HK/Sham Shui Po District; GeoNames 1818953
        "geonames-1857871": .init(latitude: 35.54028, longitude: 139.45083), // JP/Tokyo; GeoNames 1857871
        "geonames-359493": .init(latitude: 30.58768, longitude: 31.502), // EG/Sharqia; GeoNames 359493
        "geonames-689558": .init(latitude: 49.2322, longitude: 28.46871), // UA/Vinnytsia; GeoNames 689558
        "geonames-361055": .init(latitude: 30.60427, longitude: 32.27225), // EG/Ismailia; GeoNames 361055
        "geonames-1279105": .init(latitude: 20.70957, longitude: 76.9981), // IN/Maharashtra; GeoNames 1279105
        "geonames-13608165": .init(latitude: -8.83411, longitude: 13.29517), // AO/Luanda; GeoNames 13608165
        "geonames-3514783": .init(latitude: 19.18095, longitude: -96.1429), // MX/Veracruz; GeoNames 3514783
        "geonames-571476": .init(latitude: 53.27096, longitude: 34.32143), // RU/Bryansk Oblast; GeoNames 571476
        "geonames-741763": .init(latitude: 40.93567, longitude: 29.15507), // TR/Istanbul; GeoNames 741763
        "geonames-584923": .init(latitude: 40.58972, longitude: 49.66861), // AZ/Sumqayit; GeoNames 584923
        "geonames-1163964": .init(latitude: 24.78914, longitude: 68.96535), // PK/Sindh; GeoNames 1163964
        "geonames-1734705": .init(latitude: 5.3302, longitude: 103.1408), // MY/Terengganu; GeoNames 1734705
        "geonames-1849814": .init(latitude: 35.08333, longitude: 137.15), // JP/Aichi; GeoNames 1849814
        "geonames-2313002": .init(latitude: -5.83861, longitude: 13.46306), // CD/Bas-Congo; GeoNames 2313002
        "geonames-109353": .init(latitude: 24.15541, longitude: 47.33457), // SA/Riyadh Region; GeoNames 109353
        "geonames-1818304": .init(latitude: 22.35, longitude: 114.18333), // HK/Wong Tai Sin District; GeoNames 1818304
        "geonames-2330100": .init(latitude: 9.61524, longitude: 6.54776), // NG/Niger State; GeoNames 2330100
        "geonames-13118244": .init(latitude: 14.57837, longitude: 121.03522), // PH/National Capital Region; GeoNames 13118244
        "geonames-3526617": .init(latitude: 19.53124, longitude: -96.91589), // MX/Veracruz; GeoNames 3526617
        "geonames-12557764": .init(latitude: 3.19916, longitude: 101.64983), // MY/Kuala Lumpur; GeoNames 12557764
        "geonames-1852139": .init(latitude: 33.63627, longitude: 133.00572), // JP/Ehime; GeoNames 1852139
        "geonames-173811": .init(latitude: 36.50237, longitude: 40.74772), // SY/Al-Hasakah; GeoNames 173811
        "geonames-6058560": .init(latitude: 42.98339, longitude: -81.23304), // CA/Ontario; GeoNames 6058560
        "geonames-343137": .init(latitude: 7.06205, longitude: 38.47635), // ET/Sidama Region; GeoNames 343137
        "geonames-1049261": .init(latitude: -19.11639, longitude: 33.48333), // MZ/Manica; GeoNames 1049261
        "geonames-1163965": .init(latitude: 25.4605, longitude: 68.71745), // PK/Sindh; GeoNames 1163965
        "geonames-2290486": .init(latitude: 6.87735, longitude: -6.45022), // CI/Sassandra-Marahoue; GeoNames 2290486
        "geonames-1337233": .init(latitude: 24.85098, longitude: 89.37108), // BD/Rajshahi Division; GeoNames 1337233
        "geonames-7290718": .init(latitude: -22.99835, longitude: -43.36545), // BR/Rio de Janeiro; GeoNames 7290718
        "geonames-2234974": .init(latitude: 5.9597, longitude: 10.14597), // CM/North-West; GeoNames 2234974
        "geonames-480060": .init(latitude: 56.85836, longitude: 35.90057), // RU/Tver Oblast; GeoNames 480060
        "geonames-1566319": .init(latitude: 21.59422, longitude: 105.84817), // VN/Thai Nguyen; GeoNames 1566319
        "geonames-3664980": .init(latitude: 2.81972, longitude: -60.67333), // BR/Roraima; GeoNames 3664980
        "geonames-3662574": .init(latitude: -9.97472, longitude: -67.81), // BR/Acre; GeoNames 3662574
        "geonames-5378538": .init(latitude: 37.80437, longitude: -122.2708), // US/California; GeoNames 5378538
        "geonames-1851100": .init(latitude: 34.33333, longitude: 134.05), // JP/Kagawa; GeoNames 1851100
        "geonames-1819607": .init(latitude: 22.33047, longitude: 114.19222), // HK/Kowloon City; GeoNames 1819607
        "geonames-3449433": .init(latitude: -23.96083, longitude: -46.33361), // BR/São Paulo; GeoNames 3449433
        "geonames-3392242": .init(latitude: -9.39861, longitude: -40.50083), // BR/Pernambuco; GeoNames 3392242
        "geonames-3457381": .init(latitude: -23.66778, longitude: -46.46139), // BR/São Paulo; GeoNames 3457381
        "geonames-1736309": .init(latitude: 6.12104, longitude: 100.36014), // MY/Kedah; GeoNames 1736309
        "geonames-1694611": .init(latitude: 14.53748, longitude: 121.00144), // PH/National Capital Region; GeoNames 1694611
        "geonames-3522551": .init(latitude: 27.47629, longitude: -99.51639), // MX/Tamaulipas; GeoNames 3522551
        "geonames-1849876": .init(latitude: 36.7, longitude: 137.21667), // JP/Toyama; GeoNames 1849876
        "geonames-2528910": .init(latitude: 35.57845, longitude: -5.36837), // MA/Tanger-Tetouan-Al Hoceima; GeoNames 2528910
        "geonames-6947640": .init(latitude: 40.982, longitude: 28.6399), // TR/Istanbul; GeoNames 6947640
        "geonames-1562820": .init(latitude: 21.32274, longitude: 105.40198), // VN/Phu Tho; GeoNames 1562820
        "geonames-3532497": .init(latitude: 19.48698, longitude: -99.18594), // MX/Mexico City; GeoNames 3532497
        "geonames-4174757": .init(latitude: 27.94752, longitude: -82.45843), // US/Florida; GeoNames 4174757
        "geonames-234179": .init(latitude: 0.25344, longitude: 32.55723), // UG/Central Region; GeoNames 234179
        "geonames-532288": .init(latitude: 53.39808, longitude: 59.0066), // RU/Chelyabinsk; GeoNames 532288
        "geonames-4553433": .init(latitude: 36.15398, longitude: -95.99277), // US/Oklahoma; GeoNames 4553433
        "geonames-1818506": .init(latitude: 22.32789, longitude: 114.24992), // HK/Sai Kung District; GeoNames 1818506
        "geonames-3645532": .init(latitude: 8.12366, longitude: -63.54694), // VE/Bolívar; GeoNames 3645532
        "geonames-1762110": .init(latitude: 1.532, longitude: 103.7549), // MY/Johor; GeoNames 1762110
        "geonames-2285853": .init(latitude: 5.29716, longitude: -3.96753), // CI/Abidjan Autonomous District; GeoNames 2285853
        "geonames-3985241": .init(latitude: 25.74167, longitude: -100.30222), // MX/Nuevo León; GeoNames 3985241
        "geonames-5037649": .init(latitude: 44.97997, longitude: -93.26384), // US/Minnesota; GeoNames 5037649
        "geonames-2082600": .init(latitude: -2.53371, longitude: 140.71813), // ID/Papua; GeoNames 2082600
        "geonames-143083": .init(latitude: 38.2498, longitude: 48.2933), // IR/Ardabil Province; GeoNames 143083
        "geonames-281133": .init(latitude: 31.50161, longitude: 34.46672), // PS/Gaza Strip; GeoNames 281133
        "geonames-3457671": .init(latitude: -23.42528, longitude: -51.93861), // BR/Paraná; GeoNames 3457671
        "geonames-1848313": .init(latitude: 35.28361, longitude: 139.66722), // JP/Kanagawa; GeoNames 1848313
        "geonames-353802": .init(latitude: 24.47669, longitude: 32.94626), // EG/Aswan; GeoNames 353802
        "geonames-3981369": .init(latitude: 20.62263, longitude: -103.24168), // MX/Jalisco; GeoNames 3981369
        "geonames-204405": .init(latitude: -3.39534, longitude: 29.13779), // CD/South Kivu; GeoNames 204405
        "geonames-1862540": .init(latitude: 34.81352, longitude: 135.64914), // JP/Osaka; GeoNames 1862540
        "geonames-555312": .init(latitude: 56.99988, longitude: 40.97257), // RU/Ivanovo Oblast; GeoNames 555312
        "geonames-3644768": .init(latitude: 10.4639, longitude: -64.17859), // VE/Sucre; GeoNames 3644768
        "geonames-971421": .init(latitude: -27.75796, longitude: 29.9318), // ZA/KwaZulu-Natal; GeoNames 971421
        "geonames-1842225": .init(latitude: 36.1136, longitude: 128.336), // KR/Gyeongsangbuk-do; GeoNames 1842225
        "geonames-3464739": .init(latitude: -23.68611, longitude: -46.62278), // BR/São Paulo; GeoNames 3464739
        "geonames-1863641": .init(latitude: 35.42291, longitude: 136.76039), // JP/Gifu; GeoNames 1863641
        "geonames-3402655": .init(latitude: -8.28333, longitude: -35.97611), // BR/Pernambuco; GeoNames 3402655
        "geonames-1682812": .init(latitude: 15.48017, longitude: 120.59794), // PH/Central Luzon; GeoNames 1682812
        "geonames-1849837": .init(latitude: 34.78244, longitude: 135.46932), // JP/Osaka; GeoNames 1849837
        "geonames-372753": .init(latitude: 15.45099, longitude: 36.39998), // SD/Kassala; GeoNames 372753
        "geonames-1856717": .init(latitude: 31.91667, longitude: 131.41667), // JP/Miyazaki; GeoNames 1856717
        "geonames-7732748": .init(latitude: 6.44632, longitude: 3.47717), // NG/Lagos; GeoNames 7732748
        "geonames-3899539": .init(latitude: -23.65094, longitude: -70.39752), // CL/Antofagasta; GeoNames 3899539
        "geonames-1279290": .init(latitude: 23.83605, longitude: 91.27939), // IN/Tripura; GeoNames 1279290
        "geonames-2347209": .init(latitude: 9.08044, longitude: 6.0099), // NG/Niger State; GeoNames 2347209
        "geonames-217695": .init(latitude: 1.55941, longitude: 30.25224), // CD/Ituri; GeoNames 217695
        "geonames-323779": .init(latitude: 36.20655, longitude: 36.15722), // TR/Hatay; GeoNames 323779
        "geonames-9645085": .init(latitude: 10.76823, longitude: 106.66632), // VN/Ho Chi Minh City (HCMC); GeoNames 9645085
        "geonames-10630449": .init(latitude: -26.65682, longitude: 153.07955), // AU/Queensland; GeoNames 10630449
        "geonames-191245": .init(latitude: -0.10221, longitude: 34.76171), // KE/Kisumu County; GeoNames 191245
        "geonames-702658": .init(latitude: 48.56814, longitude: 39.30553), // UA/Luhansk; GeoNames 702658
        "geonames-1649150": .init(latitude: -3.80044, longitude: 102.26554), // ID/Bengkulu; GeoNames 1649150
        "geonames-3648546": .init(latitude: 8.62064, longitude: -70.23105), // VE/Barinas; GeoNames 3648546
        "geonames-3444914": .init(latitude: -14.86611, longitude: -40.83944), // BR/Bahia; GeoNames 3444914
        "geonames-4281730": .init(latitude: 37.69224, longitude: -97.33754), // US/Kansas; GeoNames 4281730
        "geonames-2558545": .init(latitude: 35.25165, longitude: -3.93723), // MA/Tanger-Tetouan-Al Hoceima; GeoNames 2558545
        "geonames-3083829": .init(latitude: 53.42894, longitude: 14.55302), // PL/West Pomerania; GeoNames 3083829
        "geonames-3726786": .init(latitude: 18.54478, longitude: -72.30036), // HT/Ouest; GeoNames 3726786
        "geonames-3445026": .init(latitude: -20.32972, longitude: -40.2925), // BR/Espírito Santo; GeoNames 3445026
        "geonames-11523293": .init(latitude: 36.59245, longitude: 127.29223), // KR/Sejong-si; GeoNames 11523293
        "geonames-2591949": .init(latitude: -8.83796, longitude: 13.28399), // AO/Luanda; GeoNames 2591949
        "geonames-740264": .init(latitude: 41.27976, longitude: 36.3361), // TR/Samsun; GeoNames 740264
        "geonames-149606": .init(latitude: -5.06893, longitude: 39.09875), // TZ/Tanga; GeoNames 149606
        "geonames-379003": .init(latitude: 13.18421, longitude: 30.21669), // SD/North Kordofan; GeoNames 379003
        "geonames-3347939": .init(latitude: -12.3644, longitude: 13.53601), // AO/Benguela; GeoNames 3347939
        "geonames-145531": .init(latitude: -9.66078, longitude: 20.39155), // AO/Lunda Sul; GeoNames 145531
        "geonames-3470279": .init(latitude: -22.31472, longitude: -49.06056), // BR/São Paulo; GeoNames 3470279
        "geonames-3688928": .init(latitude: 6.33732, longitude: -75.55795), // CO/Antioquia; GeoNames 3688928
        "geonames-3672778": .init(latitude: 1.21456, longitude: -77.27846), // CO/Nariño; GeoNames 3672778
        "geonames-3836277": .init(latitude: -31.64881, longitude: -60.70868), // AR/Santa Fe; GeoNames 3836277
        "geonames-2282006": .init(latitude: 4.74851, longitude: -6.6363), // CI/Bas-Sassandra District; GeoNames 2282006
        "geonames-2331140": .init(latitude: 7.73375, longitude: 8.52139), // NG/Benue State; GeoNames 2331140
        "geonames-1633034": .init(latitude: -0.90833, longitude: 119.87083), // ID/Central Sulawesi; GeoNames 1633034
        "geonames-2294915": .init(latitude: 4.89816, longitude: -1.76029), // GH/Western; GeoNames 2294915
        "geonames-1606590": .init(latitude: 13.5976, longitude: 100.5972), // TH/Samut Prakan; GeoNames 1606590
        "geonames-105072": .init(latitude: 18.3, longitude: 42.73333), // SA/'Asir Region; GeoNames 105072
        "geonames-3660689": .init(latitude: -1.24908, longitude: -78.61675), // EC/Tungurahua Province; GeoNames 3660689
        "geonames-3466998": .init(latitude: -23.52272, longitude: -46.835), // BR/São Paulo; GeoNames 3466998
        "geonames-3827598": .init(latitude: 19.68028, longitude: -99.01), // MX/México; GeoNames 3827598
        "geonames-2395914": .init(latitude: 6.44852, longitude: 2.35566), // BJ/Atlantique; GeoNames 2395914
        "geonames-2947416": .init(latitude: 51.48165, longitude: 7.21648), // DE/North Rhine-Westphalia; GeoNames 2947416
        "geonames-1851483": .init(latitude: 34.76143, longitude: 135.51567), // JP/Osaka; GeoNames 1851483
        "geonames-1175748": .init(latitude: 31.56808, longitude: 73.18317), // PK/Punjab; GeoNames 1175748
        "geonames-310859": .init(latitude: 37.5847, longitude: 36.92641), // TR/Kahramanmaraş; GeoNames 310859
        "geonames-1854376": .init(latitude: 34.95, longitude: 137.16667), // JP/Aichi; GeoNames 1854376
        "geonames-3514519": .init(latitude: 19.27875, longitude: -98.94329), // MX/México; GeoNames 3514519
        "geonames-3526700": .init(latitude: 19.39528, longitude: -99.09778), // MX/Mexico City; GeoNames 3526700
        "geonames-2515270": .init(latitude: 28.10178, longitude: -15.41573), // ES/Canary Islands; GeoNames 2515270
        "geonames-1716771": .init(latitude: 7.22361, longitude: 124.24639), // PH/Autonomous Region in Muslim Mindanao; GeoNames 1716771
        "geonames-288764": .init(latitude: 23.57769, longitude: 58.39982), // OM/Muscat; GeoNames 288764
        "geonames-1265014": .init(latitude: 18.39721, longitude: 76.56784), // IN/Maharashtra; GeoNames 1265014
        "geonames-3996322": .init(latitude: 23.22163, longitude: -106.41885), // MX/Sinaloa; GeoNames 3996322
        "geonames-520494": .init(latitude: 57.91944, longitude: 59.965), // RU/Sverdlovsk Oblast; GeoNames 520494
        "geonames-4004330": .init(latitude: 20.671, longitude: -101.35577), // MX/Guanajuato; GeoNames 4004330
        "geonames-1861949": .init(latitude: 35.3, longitude: 136.8), // JP/Aichi; GeoNames 1861949
        "geonames-1349452": .init(latitude: 23.84858, longitude: 90.25002), // BD/Dhaka Division; GeoNames 1349452
        "geonames-675810": .init(latitude: 47.16667, longitude: 27.6), // RO/Iași County; GeoNames 675810
        "geonames-986822": .init(latitude: -26.08577, longitude: 27.77515), // ZA/Gauteng; GeoNames 986822
        "geonames-1185107": .init(latitude: 25.00146, longitude: 89.32266), // BD/Rajshahi Division; GeoNames 1185107
        "geonames-1849846": .init(latitude: 34.76667, longitude: 137.38333), // JP/Aichi; GeoNames 1849846
        "geonames-3719028": .init(latitude: 18.5125, longitude: -72.28528), // HT/Ouest; GeoNames 3719028
        "geonames-2745912": .init(latitude: 52.09083, longitude: 5.12222), // NL/Utrecht; GeoNames 2745912
        "geonames-1272691": .init(latitude: 20.9013, longitude: 74.77737), // IN/Maharashtra; GeoNames 1272691
        "geonames-1749822": .init(latitude: 3, longitude: 101.61667), // MY/Selangor; GeoNames 1749822
        "geonames-2326171": .init(latitude: 7.09316, longitude: 4.83528), // NG/Ondo State; GeoNames 2326171
        "geonames-1182682": .init(latitude: 31.56884, longitude: 72.64917), // PK/Punjab; GeoNames 1182682
        "geonames-958724": .init(latitude: -25.66756, longitude: 27.24208), // ZA/North West; GeoNames 958724
        "geonames-5325738": .init(latitude: 35.37329, longitude: -119.01871), // US/California; GeoNames 5325738
        "geonames-939270": .init(latitude: -25.87133, longitude: 29.23323), // ZA/Mpumalanga; GeoNames 939270
        "geonames-2235189": .init(latitude: 5.47775, longitude: 10.41759), // CM/West; GeoNames 2235189
        "geonames-1565022": .init(latitude: 10.9804, longitude: 106.6519), // VN/Ho Chi Minh City (HCMC); GeoNames 1565022
        "geonames-1851002": .init(latitude: 36.33333, longitude: 139.01667), // JP/Gunma; GeoNames 1851002
        "geonames-1734810": .init(latitude: 2.7297, longitude: 101.9381), // MY/Negeri Sembilan; GeoNames 1734810
        "geonames-1856215": .init(latitude: 36.65, longitude: 138.18333), // JP/Nagano; GeoNames 1856215
        "geonames-1734199": .init(latitude: 4.24482, longitude: 117.89115), // MY/Sabah; GeoNames 1734199
        "geonames-2653822": .init(latitude: 51.48, longitude: -3.18), // GB/Wales; GeoNames 2653822
        "geonames-1106542": .init(latitude: -18.01274, longitude: 31.07555), // ZW/Harare; GeoNames 1106542
        "geonames-2320576": .init(latitude: 5.52491, longitude: 7.49461), // NG/Abia State; GeoNames 2320576
        "geonames-3629672": .init(latitude: 10.21382, longitude: -64.6328), // VE/Anzoátegui; GeoNames 3629672
        "geonames-298299": .init(latitude: 38.67351, longitude: 29.4058), // TR/Uşak; GeoNames 298299
        "geonames-1283613": .init(latitude: 27.68027, longitude: 84.43647), // NP/Bagmati Province; GeoNames 1283613
        "geonames-7483813": .init(latitude: 24.41112, longitude: 88.98673), // BD/Rajshahi Division; GeoNames 7483813
        "geonames-353219": .init(latitude: 29.81667, longitude: 31.05), // EG/Giza; GeoNames 353219
        "geonames-2644668": .init(latitude: 52.6386, longitude: -1.13169), // GB/England; GeoNames 2644668
        "geonames-7535637": .init(latitude: -34.66018, longitude: -58.36744), // AR/Buenos Aires; GeoNames 7535637
        "geonames-2654993": .init(latitude: 53.79391, longitude: -1.75206), // GB/England; GeoNames 2654993
        "geonames-1626381": .init(latitude: -6.91806, longitude: 106.92667), // ID/West Java; GeoNames 1626381
        "geonames-1703320": .init(latitude: 14.67333, longitude: 120.93972), // PH/National Capital Region; GeoNames 1703320
        "geonames-3463011": .init(latitude: -20.53861, longitude: -47.40083), // BR/São Paulo; GeoNames 3463011
        "geonames-5150529": .init(latitude: 41.4995, longitude: -81.69541), // US/Ohio; GeoNames 5150529
        "geonames-2337181": .init(latitude: 7.97022, longitude: 3.59626), // NG/Oyo State; GeoNames 2337181
        "geonames-2318123": .init(latitude: 4.92675, longitude: 6.26764), // NG/Bayelsa State; GeoNames 2318123
        "geonames-2341374": .init(latitude: 7.32275, longitude: 9.00108), // NG/Benue State; GeoNames 2341374
        "geonames-5950268": .init(latitude: 43.64415, longitude: -79.56985), // CA/Ontario; GeoNames 5950268
        "geonames-13546342": .init(latitude: -8.88001, longitude: 13.19617), // AO/Luanda; GeoNames 13546342
        "geonames-1838343": .init(latitude: 36.99472, longitude: 127.08889), // KR/Gyeonggi-do; GeoNames 1838343
        "geonames-3630297": .init(latitude: 10.47679, longitude: -66.80786), // VE/Miranda; GeoNames 3630297
        "geonames-1588060": .init(latitude: 11.15, longitude: 106.6), // VN/Ho Chi Minh City (HCMC); GeoNames 1588060
        "geonames-324190": .init(latitude: 36.54375, longitude: 31.99982), // TR/Antalya; GeoNames 324190
        "geonames-1172128": .init(latitude: 27.55898, longitude: 68.21204), // PK/Sindh; GeoNames 1172128
        "geonames-379062": .init(latitude: 14.03493, longitude: 35.38344), // SD/Al Qaḑārif; GeoNames 379062
        "geonames-627904": .init(latitude: 53.6758, longitude: 23.82887), // BY/Grodnenskaya; GeoNames 627904
        "geonames-1647003": .init(latitude: -6.48167, longitude: 106.85417), // ID/West Java; GeoNames 1647003
        "geonames-1169116": .init(latitude: 26.23939, longitude: 68.40369), // PK/Sindh; GeoNames 1169116
        "geonames-4335045": .init(latitude: 29.95465, longitude: -90.07507), // US/Louisiana; GeoNames 4335045
        "geonames-1678228": .init(latitude: 25.13089, longitude: 121.74094), // TW/Taiwan; GeoNames 1678228
        "geonames-2187404": .init(latitude: -36.99282, longitude: 174.87986), // NZ/Auckland; GeoNames 2187404
        "geonames-2441291": .init(latitude: 13.5, longitude: 7.10174), // NE/Maradi Region; GeoNames 2441291
        "geonames-1182092": .init(latitude: 30.16667, longitude: 72.65), // PK/Punjab; GeoNames 1182092
        "geonames-6947637": .init(latitude: 40.9833, longitude: 29.1167), // TR/Istanbul; GeoNames 6947637
        "geonames-3469968": .init(latitude: -26.91944, longitude: -49.06611), // BR/Santa Catarina; GeoNames 3469968
        "geonames-1170395": .init(latitude: 34.7795, longitude: 72.36265), // PK/Khyber Pakhtunkhwa; GeoNames 1170395
        "geonames-3389353": .init(latitude: -2.44306, longitude: -54.70833), // BR/Pará; GeoNames 3389353
        "geonames-2805753": .init(latitude: 51.25627, longitude: 7.14816), // DE/North Rhine-Westphalia; GeoNames 2805753
        "geonames-2014407": .init(latitude: 51.82648, longitude: 107.59979), // RU/Buryatiya Republic; GeoNames 2014407
        "geonames-2338400": .init(latitude: 6.81944, longitude: 3.91731), // NG/Ogun State; GeoNames 2338400
        "geonames-620127": .init(latitude: 55.1904, longitude: 30.2049), // BY/Vitebsk; GeoNames 620127
        "geonames-7628419": .init(latitude: 40.96072, longitude: 29.27067), // TR/Istanbul; GeoNames 7628419
        "geonames-1516905": .init(latitude: 42.89799, longitude: 71.37334), // KZ/Zhambyl; GeoNames 1516905
        "geonames-1832828": .init(latitude: 35.34199, longitude: 129.03358), // KR/Gyeongsangnam-do; GeoNames 1832828
        "geonames-1689395": .init(latitude: 14.81389, longitude: 121.04528), // PH/Central Luzon; GeoNames 1689395
        "geonames-13631407": .init(latitude: 30.4431, longitude: 47.87802), // IQ/Basra; GeoNames 13631407
        "geonames-1948005": .init(latitude: 37.47722, longitude: 126.86639), // KR/Gyeonggi-do; GeoNames 1948005
        "geonames-111453": .init(latitude: 36.67642, longitude: 48.49628), // IR/Zanjan; GeoNames 111453
        "geonames-3673899": .init(latitude: 2.93001, longitude: -75.27973), // CO/Huila Department; GeoNames 3673899
        "geonames-2112539": .init(latitude: 37.05, longitude: 140.88333), // JP/Fukushima; GeoNames 2112539
        "geonames-473247": .init(latitude: 56.13854, longitude: 40.39976), // RU/Vladimir Oblast; GeoNames 473247
        "geonames-1026014": .init(latitude: -16.15639, longitude: 33.58667), // MZ/Tete; GeoNames 1026014
        "geonames-1729524": .init(latitude: 14.45896, longitude: 120.93851), // PH/Calabarzon; GeoNames 1729524
        "geonames-1926004": .init(latitude: 34.23333, longitude: 135.16667), // JP/Wakayama; GeoNames 1926004
        "geonames-1673816": .init(latitude: 22.62659, longitude: 120.36126), // TW/Takao; GeoNames 1673816
        "geonames-2214846": .init(latitude: 32.37535, longitude: 15.09254), // LY/Misratah; GeoNames 2214846
        "geonames-3348078": .init(latitude: -12.38333, longitude: 16.93333), // AO/Bíe; GeoNames 3348078
        "geonames-1519922": .init(latitude: 44.85278, longitude: 65.50917), // KZ/Kyzylorda; GeoNames 1519922
        "geonames-1164776": .init(latitude: 26.03008, longitude: 68.80867), // PK/Sindh; GeoNames 1164776
        "geonames-1859740": .init(latitude: 35.90861, longitude: 139.48528), // JP/Saitama; GeoNames 1859740
        "geonames-1850910": .init(latitude: 34.84833, longitude: 135.61678), // JP/Osaka; GeoNames 1850910
        "geonames-3516266": .init(latitude: 14.91074, longitude: -92.26452), // MX/Chiapas; GeoNames 3516266
        "geonames-3514670": .init(latitude: 17.98625, longitude: -92.93928), // MX/Tabasco; GeoNames 3514670
        "geonames-1735162": .init(latitude: 3.207, longitude: 101.727), // MY/Selangor; GeoNames 1735162
        "geonames-625665": .init(latitude: 53.90876, longitude: 30.34044), // BY/Mogilev; GeoNames 625665
        "geonames-141681": .init(latitude: 27.1865, longitude: 56.2808), // IR/Hormozgan; GeoNames 141681
        "geonames-291074": .init(latitude: 25.78953, longitude: 55.9432), // AE/Ras Al Khaimah; GeoNames 291074
        "geonames-3647651": .init(latitude: 10.39907, longitude: -71.45206), // VE/Zulia; GeoNames 3647651
        "geonames-1640344": .init(latitude: -3.9778, longitude: 122.51507), // ID/Southeast Sulawesi; GeoNames 1640344
        "geonames-299817": .init(latitude: 36.91766, longitude: 34.89277), // TR/Mersin; GeoNames 299817
        "geonames-342884": .init(latitude: 11.59364, longitude: 37.39077), // ET/Amhara; GeoNames 342884
        "geonames-1028434": .init(latitude: -17.87861, longitude: 36.88833), // MZ/Zambezia Province; GeoNames 1028434
        "geonames-581049": .init(latitude: 64.5461, longitude: 40.55183), // RU/Arkhangelskaya; GeoNames 581049
        "geonames-1645133": .init(latitude: 1.66711, longitude: 101.44316), // ID/Riau; GeoNames 1645133
        "geonames-2451185": .init(latitude: 11.31755, longitude: -5.66654), // ML/Sikasso; GeoNames 2451185
        "geonames-117574": .init(latitude: 35.31495, longitude: 46.99883), // IR/Kurdistan Province; GeoNames 117574
        "geonames-2025339": .init(latitude: 52.04311, longitude: 113.49171), // RU/Zabaykalskiy (Transbaikal) Kray; GeoNames 2025339
        "geonames-1688749": .init(latitude: 14.3595, longitude: 121.0473), // PH/Calabarzon; GeoNames 1688749
        "geonames-2388873": .init(latitude: 4.25671, longitude: 18.41583), // CF/Ombella-M'Poko; GeoNames 2388873
        "geonames-1321218": .init(latitude: 23.19014, longitude: 94.06405), // MM/Sagaing Region; GeoNames 1321218
        "geonames-2655984": .init(latitude: 54.59682, longitude: -5.92541), // GB/Northern Ireland; GeoNames 2655984
        "geonames-3566067": .init(latitude: 21.38083, longitude: -77.91694), // CU/Camagüey; GeoNames 3566067
        "geonames-1651531": .init(latitude: -3.69583, longitude: 128.18333), // ID/Maluku; GeoNames 1651531
        "geonames-629634": .init(latitude: 52.10894, longitude: 23.71749), // BY/Brest; GeoNames 629634
        "geonames-8310663": .init(latitude: -33.42979, longitude: 151.37144), // AU/New South Wales; GeoNames 8310663
        "geonames-3435217": .init(latitude: -27.46784, longitude: -58.8344), // AR/Corrientes; GeoNames 3435217
        "geonames-1877030": .init(latitude: 39.84198, longitude: 127.63206), // KP/South Hamgyong; GeoNames 1877030
        "geonames-1858729": .init(latitude: 35.89035, longitude: 139.78916), // JP/Saitama; GeoNames 1858729
        "geonames-2652221": .init(latitude: 52.40656, longitude: -1.51217), // GB/England; GeoNames 2652221
        "geonames-578072": .init(latitude: 50.60343, longitude: 36.58091), // RU/Belgorod Oblast; GeoNames 578072
        "geonames-1053384": .init(latitude: -18.1492, longitude: 49.40234), // MG/Atsinanana; GeoNames 1053384
        "geonames-7281838": .init(latitude: -27.63917, longitude: 153.10944), // AU/Queensland; GeoNames 7281838
        "geonames-1853574": .init(latitude: 35, longitude: 135.86667), // JP/Shiga; GeoNames 1853574
        "geonames-371760": .init(latitude: 13.1629, longitude: 32.66347), // SD/White Nile; GeoNames 371760
        "geonames-8715035": .init(latitude: 35.70449, longitude: 139.66946), // JP/Tokyo; GeoNames 8715035
        "geonames-1646170": .init(latitude: -6.7063, longitude: 108.557), // ID/West Java; GeoNames 1646170
        "geonames-3625829": .init(latitude: 10.22856, longitude: -67.47421), // VE/Aragua; GeoNames 3625829
        "geonames-1850181": .init(latitude: 35.79916, longitude: 139.46903), // JP/Saitama; GeoNames 1850181
        "geonames-1721906": .init(latitude: 15.48586, longitude: 120.96648), // PH/Central Luzon; GeoNames 1721906
        "geonames-338832": .init(latitude: 9.59306, longitude: 41.86611), // ET/Dire Dawa; GeoNames 338832
        "geonames-2506999": .init(latitude: 36.9, longitude: 7.76667), // DZ/Annaba; GeoNames 2506999
        "geonames-1711084": .init(latitude: 8.2289, longitude: 124.24344), // PH/Northern Mindanao; GeoNames 1711084
        "geonames-3667849": .init(latitude: 10.91843, longitude: -74.76459), // CO/Atlántico; GeoNames 3667849
        "geonames-2529013": .init(latitude: 33.92866, longitude: -6.90656), // MA/Rabat-Salé-Kénitra; GeoNames 2529013
        "geonames-2566633": .init(latitude: 6.44694, longitude: 3.41528), // NG/Lagos; GeoNames 2566633
        "geonames-96994": .init(latitude: 36.86608, longitude: 42.9879), // IQ/Duhok; GeoNames 96994
        "geonames-553915": .init(latitude: 54.53063, longitude: 36.27), // RU/Kaluga Oblast; GeoNames 553915
        "geonames-4014875": .init(latitude: 20.52181, longitude: -100.81399), // MX/Guanajuato; GeoNames 4014875
        "geonames-2411989": .init(latitude: 13.43833, longitude: -16.67806), // GM/Banjul; GeoNames 2411989
        "geonames-1199503": .init(latitude: 23.78822, longitude: 90.37359), // BD/Dhaka Division; GeoNames 1199503
        "geonames-308988": .init(latitude: 38.45772, longitude: 27.1142), // TR/İzmir Province; GeoNames 308988
        "geonames-702320": .init(latitude: 48.04782, longitude: 37.92576), // UA/Donetsk; GeoNames 702320
        "geonames-3529947": .init(latitude: 18.9261, longitude: -99.23075), // MX/Morelos; GeoNames 3529947
        "geonames-6066513": .init(latitude: 43.86682, longitude: -79.2663), // CA/Ontario; GeoNames 6066513
        "geonames-1876373": .init(latitude: 37.97083, longitude: 126.55444), // KP/Kaesong; GeoNames 1876373
        "geonames-1185098": .init(latitude: 23.89154, longitude: 90.40232), // BD/Dhaka Division; GeoNames 1185098
        "geonames-963241": .init(latitude: -26.0941, longitude: 28.00123), // ZA/Gauteng; GeoNames 963241
        "geonames-2537881": .init(latitude: 32.29939, longitude: -9.23718), // MA/Marrakesh-Safi; GeoNames 2537881
        "geonames-693805": .init(latitude: 44.95719, longitude: 34.11079), // UA/Crimea; GeoNames 693805
        "geonames-765876": .init(latitude: 51.25058, longitude: 22.57009), // PL/Lublin; GeoNames 765876
        "geonames-3454244": .init(latitude: -31.76997, longitude: -52.34101), // BR/Rio Grande do Sul; GeoNames 3454244
        "geonames-4167147": .init(latitude: 28.53834, longitude: -81.37924), // US/Florida; GeoNames 4167147
        "geonames-3868121": .init(latitude: -33.02457, longitude: -71.55183), // CL/Valparaiso; GeoNames 3868121
        "geonames-119505": .init(latitude: 36.26877, longitude: 50.0041), // IR/Qazvin Province; GeoNames 119505
        "geonames-2130629": .init(latitude: 43.77063, longitude: 142.36489), // JP/Hokkaido; GeoNames 2130629
        "geonames-3981941": .init(latitude: 21.50733, longitude: -104.89332), // MX/Nayarit; GeoNames 3981941
        "geonames-1833105": .init(latitude: 37.35139, longitude: 127.94528), // KR/Gangwon-do; GeoNames 1833105
        "geonames-364103": .init(latitude: 14.40118, longitude: 33.51989), // SD/Al Jazirah; GeoNames 364103
        "geonames-9645084": .init(latitude: 10.76383, longitude: 106.64355), // VN/Ho Chi Minh City (HCMC); GeoNames 9645084
        "geonames-601294": .init(latitude: 42.45861, longitude: 59.60576), // UZ/Karakalpakstan; GeoNames 601294
        "geonames-1857843": .init(latitude: 36.4, longitude: 139.08333), // JP/Gunma; GeoNames 1857843
        "geonames-3530580": .init(latitude: 23.74061, longitude: -99.14364), // MX/Tamaulipas; GeoNames 3530580
        "geonames-3982912": .init(latitude: 22.18912, longitude: -100.93792), // MX/San Luis Potosí; GeoNames 3982912
        "geonames-1859146": .init(latitude: 33.55, longitude: 133.53333), // JP/Kochi; GeoNames 1859146
        "geonames-2949186": .init(latitude: 52.03333, longitude: 8.53333), // DE/North Rhine-Westphalia; GeoNames 2949186
        "geonames-2503769": .init(latitude: 36.47004, longitude: 2.8277), // DZ/Blida; GeoNames 2503769
        "geonames-1819595": .init(latitude: 22.36828, longitude: 114.13877), // HK/Kwai Tsing District; GeoNames 1819595
        "geonames-1701947": .init(latitude: 10.32361, longitude: 123.92222), // PH/Central Visayas; GeoNames 1701947
        "geonames-586523": .init(latitude: 40.68157, longitude: 46.36134), // AZ/Gǝncǝ; GeoNames 586523
        "geonames-127319": .init(latitude: 30.44079, longitude: 48.18428), // IR/Khuzestan; GeoNames 127319
        "geonames-2946447": .init(latitude: 50.73438, longitude: 7.09549), // DE/North Rhine-Westphalia; GeoNames 2946447
        "geonames-3102014": .init(latitude: 53.1235, longitude: 18.00762), // PL/Kujawsko-Pomorskie; GeoNames 3102014
        "geonames-491687": .init(latitude: 54.77826, longitude: 32.05088), // RU/Smolensk Oblast; GeoNames 491687
        "geonames-608668": .init(latitude: 51.24601, longitude: 51.42558), // KZ/West Kazakhstan; GeoNames 608668
        "geonames-127349": .init(latitude: 33.48778, longitude: 48.35583), // IR/Lorestan Province; GeoNames 127349
        "geonames-3583096": .init(latitude: 13.71024, longitude: -89.13989), // SV/San Salvador Department; GeoNames 3583096
        "geonames-2595778": .init(latitude: 14.77446, longitude: -17.40212), // SN/Dakar; GeoNames 2595778
        "geonames-728193": .init(latitude: 42.15387, longitude: 24.75001), // BG/Plovdiv; GeoNames 728193
        "geonames-4013704": .init(latitude: 27.48642, longitude: -109.94079), // MX/Sonora; GeoNames 4013704
        "geonames-1866923": .init(latitude: 39.15278, longitude: 127.44361), // KP/Kangwŏn-do; GeoNames 1866923
        "geonames-1520240": .init(latitude: 52.27601, longitude: 76.96881), // KZ/Pavlodar Region; GeoNames 1520240
        "geonames-324496": .init(latitude: 38.37255, longitude: 34.02537), // TR/Aksaray; GeoNames 324496
        "geonames-918702": .init(latitude: -13.63333, longitude: 32.65), // ZM/Eastern Province; GeoNames 918702
        "geonames-2044757": .init(latitude: 41.79556, longitude: 129.77583), // KP/North Hamgyong; GeoNames 2044757
        "geonames-936374": .init(latitude: -26.1625, longitude: 27.8725), // ZA/Gauteng; GeoNames 936374
        "geonames-3693345": .init(latitude: -8.37915, longitude: -74.55387), // PE/Ucayali; GeoNames 3693345
        "geonames-2519240": .init(latitude: 37.89155, longitude: -4.77275), // ES/Andalusia; GeoNames 2519240
        "geonames-2655613": .init(latitude: 53.39337, longitude: -3.01479), // GB/England; GeoNames 2655613
        "geonames-2990969": .init(latitude: 47.21725, longitude: -1.55336), // FR/Pays de la Loire; GeoNames 2990969
        "geonames-2337704": .init(latitude: 7.62789, longitude: 4.74161), // NG/Osun State; GeoNames 2337704
        "geonames-1631766": .init(latitude: -6.8886, longitude: 109.6753), // ID/Central Java; GeoNames 1631766
        "geonames-1209106": .init(latitude: 23.8, longitude: 90.45), // BD/Dhaka Division; GeoNames 1209106
        "geonames-660158": .init(latitude: 60.2052, longitude: 24.6522), // FI/Uusimaa; GeoNames 660158
        "geonames-192126": .init(latitude: -1.24627, longitude: 36.66291), // KE/Kiambu County; GeoNames 192126
        "geonames-1732811": .init(latitude: 2.03046, longitude: 103.31689), // MY/Johor; GeoNames 1732811
        "geonames-2641170": .init(latitude: 52.9536, longitude: -1.15047), // GB/England; GeoNames 2641170
        "geonames-13631350": .init(latitude: -9.06259, longitude: 13.0456), // AO/Luanda; GeoNames 13631350
        "geonames-99608": .init(latitude: 31.83561, longitude: 47.14483), // IQ/Maysan; GeoNames 99608
        "geonames-6173577": .init(latitude: 43.8361, longitude: -79.49827), // CA/Ontario; GeoNames 6173577
        "geonames-2236568": .init(latitude: -7.60874, longitude: 15.06131), // AO/Uíge; GeoNames 2236568
        "geonames-3446682": .init(latitude: -23.02639, longitude: -45.55528), // BR/São Paulo; GeoNames 3446682
        "geonames-3526682": .init(latitude: 19.31334, longitude: -98.88421), // MX/México; GeoNames 3526682
        "geonames-1527534": .init(latitude: 40.52828, longitude: 72.7985), // KG/Osh Region; GeoNames 1527534
        "geonames-3652941": .init(latitude: -1.05764, longitude: -80.45145), // EC/Manabí; GeoNames 3652941
        "geonames-3665900": .init(latitude: 4.13238, longitude: -73.62564), // CO/Meta Department; GeoNames 3665900
        "geonames-1874533": .init(latitude: 38.99182, longitude: 125.65871), // KP/Pyongyang; GeoNames 1874533
        "geonames-3701329": .init(latitude: 9.05032, longitude: -79.47068), // PA/Panamá; GeoNames 3701329
        "geonames-1876401": .init(latitude: 39.70056, longitude: 125.89333), // KP/South Pyongan; GeoNames 1876401
        "geonames-1571968": .init(latitude: 20.25809, longitude: 105.97965), // VN/Ninh Binh; GeoNames 1571968
        "geonames-3556969": .init(latitude: 20.88722, longitude: -76.26306), // CU/Holguín Province; GeoNames 3556969
        "geonames-1520316": .init(latitude: 49.97143, longitude: 82.60586), // KZ/East Kazakhstan; GeoNames 1520316
        "geonames-1818209": .init(latitude: 22.37137, longitude: 114.11329), // HK/Tsuen Wan; GeoNames 1818209
        "geonames-2437798": .init(latitude: 13.80716, longitude: 8.9881), // NE/Zinder Region; GeoNames 2437798
        "geonames-498698": .init(latitude: 54.18485, longitude: 45.17166), // RU/Mordoviya Republic; GeoNames 498698
        "geonames-99762": .init(latitude: 31.99289, longitude: 44.92552), // IQ/Al-Qadisiyah; GeoNames 99762
        "geonames-726050": .init(latitude: 43.21912, longitude: 27.91024), // BG/Varna; GeoNames 726050
        "geonames-1177384": .init(latitude: 32.07095, longitude: 73.68802), // PK/Punjab; GeoNames 1177384
        "geonames-12278193": .init(latitude: 48.83584, longitude: 2.64241), // FR/Île-de-France; GeoNames 12278193
        "geonames-1633118": .init(latitude: -2.20833, longitude: 113.91667), // ID/Central Kalimantan; GeoNames 1633118
        "geonames-358448": .init(latitude: 31.03408, longitude: 30.46823), // EG/Beheira; GeoNames 358448
        "geonames-1181096": .init(latitude: 31.72091, longitude: 72.97836), // PK/Punjab; GeoNames 1181096
        "geonames-3671916": .init(latitude: 2.43823, longitude: -76.61316), // CO/Cauca Department; GeoNames 3671916
        "geonames-2639577": .init(latitude: 51.45625, longitude: -0.97113), // GB/England; GeoNames 2639577
        "geonames-159908": .init(latitude: -2.8725, longitude: 32.2325), // TZ/Geita; GeoNames 159908
        "geonames-680963": .init(latitude: 44.18073, longitude: 28.63432), // RO/Constanța County; GeoNames 680963
        "geonames-734077": .init(latitude: 40.64072, longitude: 22.93493), // GR/Central Macedonia; GeoNames 734077
        "geonames-2244802": .init(latitude: 14.78944, longitude: -16.92602), // SN/Thies; GeoNames 2244802
        "geonames-3698304": .init(latitude: -9.07508, longitude: -78.59373), // PE/Ancash; GeoNames 3698304
        "geonames-3182351": .init(latitude: 41.12066, longitude: 16.86982), // IT/Apulia; GeoNames 3182351
        "geonames-4683416": .init(latitude: 27.80058, longitude: -97.39638), // US/Texas; GeoNames 4683416
        "geonames-3658192": .init(latitude: -2.16919, longitude: -79.83987), // EC/Guayas; GeoNames 3658192
        "geonames-99131": .init(latitude: 32.5128, longitude: 45.81817), // IQ/Wasit; GeoNames 99131
        "geonames-1732869": .init(latitude: 2.0442, longitude: 102.5689), // MY/Johor; GeoNames 1732869
        "geonames-2228373": .init(latitude: 10.59095, longitude: 14.31593), // CM/Far North; GeoNames 2228373
        "geonames-2645425": .init(latitude: 53.7446, longitude: -0.33525), // GB/England; GeoNames 2645425
        "geonames-2639912": .init(latitude: 53.76282, longitude: -2.70452), // GB/England; GeoNames 2639912
        "geonames-317109": .init(latitude: 37.77417, longitude: 29.0875), // TR/Denizli; GeoNames 317109
        "geonames-2338313": .init(latitude: 6.59651, longitude: 3.34205), // NG/Lagos; GeoNames 2338313
        "geonames-7799991": .init(latitude: 30.03, longitude: 31.47), // EG/Cairo; GeoNames 7799991
        "geonames-3444924": .init(latitude: -20.31944, longitude: -40.33778), // BR/Espírito Santo; GeoNames 3444924
        "geonames-3673164": .init(latitude: 3.53479, longitude: -76.29774), // CO/Valle del Cauca Department; GeoNames 3673164
        "geonames-472459": .init(latitude: 59.2239, longitude: 39.88398), // RU/Vologda Oblast; GeoNames 472459
        "geonames-4508722": .init(latitude: 39.12711, longitude: -84.51439), // US/Ohio; GeoNames 4508722
        "geonames-1870883": .init(latitude: 38.50722, longitude: 125.75583), // KP/North Hwanghae; GeoNames 1870883
        "geonames-1016670": .init(latitude: -29.26737, longitude: 26.72595), // ZA/Free State; GeoNames 1016670
        "geonames-1722186": .init(latitude: 8.94917, longitude: 125.54361), // PH/Caraga; GeoNames 1722186
        "geonames-143860": .init(latitude: 35.65884, longitude: 51.05775), // IR/Tehran; GeoNames 143860
        "geonames-120292": .init(latitude: 35.7214, longitude: 51.109), // IR/Tehran; GeoNames 120292
        "geonames-1501321": .init(latitude: 55.44905, longitude: 65.34344), // RU/Kurgan Oblast; GeoNames 1501321
        "geonames-3516355": .init(latitude: 22.28519, longitude: -97.87777), // MX/Tamaulipas; GeoNames 3516355
        "geonames-1721281": .init(latitude: 14.2726, longitude: 121.1262), // PH/Calabarzon; GeoNames 1721281
        "geonames-149658": .init(latitude: -5.01622, longitude: 32.82663), // TZ/Tabora; GeoNames 149658
        "geonames-1594308": .init(latitude: 13.88579, longitude: 109.10823), // VN/Gia Lai; GeoNames 1594308
        "geonames-2867543": .init(latitude: 51.96236, longitude: 7.62571), // DE/North Rhine-Westphalia; GeoNames 2867543
        "geonames-2873891": .init(latitude: 49.4891, longitude: 8.46694), // DE/Baden-Wurttemberg; GeoNames 2873891
        "geonames-1641134": .init(latitude: -6.30525, longitude: 107.3197), // ID/West Java; GeoNames 1641134
        "geonames-2113126": .init(latitude: 39.71667, longitude: 140.11667), // JP/Akita; GeoNames 2113126
        "geonames-1846052": .init(latitude: 35.19278, longitude: 128.08472), // KR/Gyeongsangnam-do; GeoNames 1846052
        "geonames-1843491": .init(latitude: 35.94389, longitude: 126.95444), // KR/Jeollabuk-do; GeoNames 1843491
        "geonames-3474574": .init(latitude: -10.16745, longitude: -48.32766), // BR/Tocantins; GeoNames 3474574
        "geonames-473249": .init(latitude: 43.04101, longitude: 44.66986), // RU/North Ossetia–Alania; GeoNames 473249
        "geonames-3718420": .init(latitude: 19.93984, longitude: -72.83037), // HT/Nord-Ouest; GeoNames 3718420
        "geonames-358048": .init(latitude: 31.41648, longitude: 31.81332), // EG/Damietta; GeoNames 358048
        "geonames-3429886": .init(latitude: -27.39184, longitude: -55.92379), // AR/Misiones; GeoNames 3429886
        "geonames-1016181": .init(latitude: -26.23656, longitude: 28.36938), // ZA/Gauteng; GeoNames 1016181
        "geonames-2323675": .init(latitude: 5.89405, longitude: 5.67666), // NG/Delta; GeoNames 2323675
        "geonames-128476": .init(latitude: 33.98237, longitude: 51.42769), // IR/Isfahan; GeoNames 128476
        "geonames-6861211": .init(latitude: 34.00228, longitude: 51.43879), // IR/Isfahan; GeoNames 6861211
        "geonames-5206379": .init(latitude: 40.44062, longitude: -79.99589), // US/Pennsylvania; GeoNames 5206379
        "geonames-3689560": .init(latitude: 4.53656, longitude: -75.67263), // CO/Quindío Department; GeoNames 3689560
        "geonames-149703": .init(latitude: -7.96667, longitude: 31.61667), // TZ/Rukwa; GeoNames 149703
        "geonames-515012": .init(latitude: 52.96879, longitude: 36.0791), // RU/Oryol oblast; GeoNames 515012
        "geonames-2778067": .init(latitude: 47.06733, longitude: 15.44197), // AT/Styria; GeoNames 2778067
        "geonames-5045360": .init(latitude: 44.94441, longitude: -93.09327), // US/Minnesota; GeoNames 5045360
        "geonames-3439101": .init(latitude: -25.5036, longitude: -54.65067), // PY/Alto Paraná Department; GeoNames 3439101
        "geonames-350203": .init(latitude: 31.39951, longitude: 30.41718), // EG/Beheira; GeoNames 350203
        "geonames-897045": .init(latitude: -12.1688, longitude: 26.38938), // ZM/North-Western; GeoNames 897045
        "geonames-2954172": .init(latitude: 48.37154, longitude: 10.89851), // DE/Bavaria; GeoNames 2954172
        "geonames-3106672": .init(latitude: 41.65541, longitude: -4.72353), // ES/Castille and León; GeoNames 3106672
        "geonames-1738050": .init(latitude: 4.39928, longitude: 113.99163), // MY/Sarawak; GeoNames 1738050
        "geonames-1170880": .init(latitude: 34.19794, longitude: 72.04965), // PK/Khyber Pakhtunkhwa; GeoNames 1170880
        "geonames-1490624": .init(latitude: 61.25757, longitude: 73.41775), // RU/Khanty-Mansia; GeoNames 1490624
        "geonames-2636432": .init(latitude: 51.62079, longitude: -3.94323), // GB/Wales; GeoNames 2636432
        "geonames-2641673": .init(latitude: 54.97328, longitude: -1.61396), // GB/England; GeoNames 2641673
        "geonames-5959974": .init(latitude: 45.47723, longitude: -75.70164), // CA/Quebec; GeoNames 5959974
        "geonames-363807": .init(latitude: 9.01222, longitude: 27.57081), // SS/Northern Bahr al Ghazal; GeoNames 363807
        "geonames-1725115": .init(latitude: 14.34267, longitude: 121.08071), // PH/Calabarzon; GeoNames 1725115
        "geonames-3632308": .init(latitude: 8.57899, longitude: -71.16922), // VE/Mérida; GeoNames 3632308
        "geonames-1282931": .init(latitude: 27.67658, longitude: 85.31417), // NP/Bagmati Province; GeoNames 1282931
        "geonames-1514019": .init(latitude: 40.38421, longitude: 71.78432), // UZ/Fergana; GeoNames 1514019
        "geonames-3865086": .init(latitude: -38.7176, longitude: -62.26545), // AR/Buenos Aires; GeoNames 3865086
        "geonames-2250805": .init(latitude: 14.15197, longitude: -16.07259), // SN/Kaolack; GeoNames 2250805
        "geonames-1642588": .init(latitude: -8.17211, longitude: 113.69953), // ID/East Java; GeoNames 1642588
        "geonames-2130658": .init(latitude: 40.81667, longitude: 140.73333), // JP/Aomori; GeoNames 2130658
        "geonames-558418": .init(latitude: 43.31195, longitude: 45.68895), // RU/Chechnya; GeoNames 558418
        "geonames-2316702": .init(latitude: -5.85098, longitude: 13.05364), // CD/Bas-Congo; GeoNames 2316702
        "geonames-776069": .init(latitude: 53.13333, longitude: 23.16433), // PL/Podlasie; GeoNames 776069
        "geonames-8461573": .init(latitude: -9.81697, longitude: 22.87023), // CD/Lualaba; GeoNames 8461573
        "geonames-2246512": .init(latitude: 14.71542, longitude: -17.27334), // SN/Dakar; GeoNames 2246512
        "geonames-2637433": .init(latitude: 51.53782, longitude: 0.71433), // GB/England; GeoNames 2637433
        "geonames-5072006": .init(latitude: 40.8, longitude: -96.66696), // US/Nebraska; GeoNames 5072006
        "geonames-2112923": .init(latitude: 37.75, longitude: 140.46667), // JP/Fukushima; GeoNames 2112923
        "geonames-484646": .init(latitude: 52.73632, longitude: 41.44102), // RU/Tambov Oblast; GeoNames 484646
        "geonames-3105976": .init(latitude: 42.23282, longitude: -8.72264), // ES/Galicia; GeoNames 3105976
        "geonames-1279186": .init(latitude: 23.72894, longitude: 92.71791), // IN/Mizoram; GeoNames 1279186
        "geonames-1650217": .init(latitude: -3.4406, longitude: 114.8365), // ID/South Kalimantan; GeoNames 1650217
        "geonames-109571": .init(latitude: 25.36467, longitude: 49.58764), // SA/Eastern Province; GeoNames 109571
        "geonames-1271715": .init(latitude: 23.21667, longitude: 72.68333), // IN/Gujarat; GeoNames 1271715
        "geonames-1519422": .init(latitude: 50.42064, longitude: 80.25025), // KZ/Abai Region; GeoNames 1519422
        "geonames-946877": .init(latitude: -33.75562, longitude: 25.40074), // ZA/Eastern Cape; GeoNames 946877
        "geonames-325330": .init(latitude: 37.76441, longitude: 38.27629), // TR/Adıyaman Province; GeoNames 325330
        "geonames-109101": .init(latitude: 25.40768, longitude: 49.59028), // SA/Eastern Province; GeoNames 109101
        "geonames-3429577": .init(latitude: -27.46363, longitude: -58.98665), // AR/Chaco; GeoNames 3429577
        "geonames-610529": .init(latitude: 47.1048, longitude: 51.88427), // KZ/Atyrau Oblisi; GeoNames 610529
        "geonames-2111834": .init(latitude: 39.7, longitude: 141.15), // JP/Iwate; GeoNames 2111834
        "geonames-3628473": .init(latitude: 7.76593, longitude: -72.23576), // VE/Táchira; GeoNames 3628473
        "geonames-2505572": .init(latitude: 35.55597, longitude: 6.17414), // DZ/Batna; GeoNames 2505572
        "geonames-598316": .init(latitude: 54.90156, longitude: 23.90909), // LT/Kaunas; GeoNames 598316
        "geonames-3654533": .init(latitude: -3.25886, longitude: -79.95876), // EC/El Oro; GeoNames 3654533
        "geonames-2809346": .init(latitude: 50.08601, longitude: 8.24435), // DE/Hesse; GeoNames 2809346
        "geonames-916095": .init(latitude: -14.4469, longitude: 28.44644), // ZM/Central Province; GeoNames 916095
        "geonames-2040893": .init(latitude: 40.10056, longitude: 124.39806), // KP/P'yŏngan-bukto; GeoNames 2040893
        "geonames-1591449": .init(latitude: 21.18608, longitude: 106.07631), // VN/Bac Ninh; GeoNames 1591449
        "geonames-3096472": .init(latitude: 50.2597, longitude: 19.02173), // PL/Silesia; GeoNames 3096472
        "geonames-752850": .init(latitude: 40.78056, longitude: 30.40333), // TR/Sakarya; GeoNames 752850
        "geonames-877401": .init(latitude: -10.68333, longitude: 35.65), // TZ/Ruvuma; GeoNames 877401
        "geonames-217562": .init(latitude: 0.14164, longitude: 29.29117), // CD/North Kivu; GeoNames 217562
        "geonames-3928128": .init(latitude: -18.01465, longitude: -70.25362), // PE/Tacna; GeoNames 3928128
        "geonames-1818558": .init(latitude: 22.45679, longitude: 114.00234), // HK/Yuen Long; GeoNames 1818558
        "geonames-1575627": .init(latitude: 10.38639, longitude: 105.43518), // VN/An Giang; GeoNames 1575627
        "geonames-11808941": .init(latitude: 4.93422, longitude: -1.71454), // GH/Western; GeoNames 11808941
        "geonames-10858926": .init(latitude: 0.29517, longitude: 32.50159), // UG/Central Region; GeoNames 10858926
        "geonames-294801": .init(latitude: 32.81303, longitude: 34.99928), // IL/Haifa; GeoNames 294801
        "geonames-1845136": .init(latitude: 37.88302, longitude: 127.7289), // KR/Gangwon-do; GeoNames 1845136
        "geonames-3487903": .init(latitude: 8.5931, longitude: -70.2261), // VE/Barinas; GeoNames 3487903
        "geonames-2248477": .init(latitude: 14.42196, longitude: -16.96375), // SN/Thies; GeoNames 2248477
        "geonames-2892794": .init(latitude: 49.00937, longitude: 8.40444), // DE/Baden-Wurttemberg; GeoNames 2892794
        "geonames-360686": .init(latitude: 28.09193, longitude: 30.75813), // EG/Minya; GeoNames 360686
        "geonames-1720840": .init(latitude: 14.5786, longitude: 121.1222), // PH/Calabarzon; GeoNames 1720840
        "geonames-2165798": .init(latitude: -38.14711, longitude: 144.36069), // AU/Victoria; GeoNames 2165798
        "geonames-710735": .init(latitude: 51.50541, longitude: 31.28656), // UA/Chernihiv Oblast; GeoNames 710735
        "geonames-3868626": .init(latitude: -33.036, longitude: -71.62963), // CL/Valparaiso; GeoNames 3868626
        "geonames-3938527": .init(latitude: -14.07538, longitude: -75.73422), // PE/Ica; GeoNames 3938527
        "geonames-3680450": .init(latitude: 6.18461, longitude: -75.59913), // CO/Antioquia; GeoNames 3680450
        "geonames-1043893": .init(latitude: -13.31278, longitude: 35.24056), // MZ/Niassa Province; GeoNames 1043893
        "geonames-1185117": .init(latitude: 23.92298, longitude: 90.71768), // BD/Dhaka Division; GeoNames 1185117
        "geonames-3068799": .init(latitude: 49.83465, longitude: 18.28204), // CZ/Moravian-Silesian Region; GeoNames 3068799
        "geonames-2467454": .init(latitude: 34.74056, longitude: 10.76028), // TN/Sfax Governorate; GeoNames 2467454
        "geonames-5261457": .init(latitude: 43.07305, longitude: -89.40123), // US/Wisconsin; GeoNames 5261457
        "geonames-2171507": .init(latitude: -34.424, longitude: 150.89345), // AU/New South Wales; GeoNames 2171507
        "geonames-696643": .init(latitude: 49.58925, longitude: 34.55367), // UA/Poltava; GeoNames 696643
        "geonames-1336142": .init(latitude: 23.97464, longitude: 91.11228), // BD/Chittagong; GeoNames 1336142
        "geonames-2343983": .init(latitude: 7.65649, longitude: 4.92235), // NG/Ekiti State; GeoNames 2343983
        "geonames-1215355": .init(latitude: 3.6001, longitude: 98.4854), // ID/North Sumatra; GeoNames 1215355
        "geonames-509820": .init(latitude: 61.78491, longitude: 34.34691), // RU/Karelia; GeoNames 509820
        "geonames-3627047": .init(latitude: 10.23291, longitude: -66.66474), // VE/Miranda; GeoNames 3627047
        "geonames-1568770": .init(latitude: 15.12047, longitude: 108.79232), // VN/Quang Ngai; GeoNames 1568770
        "geonames-1216311": .init(latitude: 38.86056, longitude: 65.78905), // UZ/Qashqadaryo; GeoNames 1216311
        "geonames-3667983": .init(latitude: 9.3045, longitude: -75.3905), // CO/Sucre Department; GeoNames 3667983
        "geonames-232110": .init(latitude: 0.43803, longitude: 32.60246), // UG/Central Region; GeoNames 232110
        "geonames-418710": .init(latitude: 32.6856, longitude: 51.53609), // IR/Isfahan; GeoNames 418710
        "geonames-543878": .init(latitude: 57.76638, longitude: 40.92828), // RU/Kostroma Oblast; GeoNames 543878
        "geonames-1269771": .init(latitude: 24.80805, longitude: 93.9442), // IN/Manipur; GeoNames 1269771
        "geonames-2288829": .init(latitude: 6.13193, longitude: -5.9506), // CI/Goh-Djiboua; GeoNames 2288829
        "geonames-2325314": .init(latitude: 7.1962, longitude: 5.58681), // NG/Ondo State; GeoNames 2325314
        "geonames-1835648": .init(latitude: 34.9505, longitude: 127.48784), // KR/Jeollanam-do; GeoNames 1835648
        "geonames-1185056": .init(latitude: 34.1463, longitude: 73.21168), // PK/Khyber Pakhtunkhwa; GeoNames 1185056
        "geonames-2505854": .init(latitude: 36.72615, longitude: 3.18291), // DZ/Algiers; GeoNames 2505854
        "geonames-1671467": .init(latitude: 25.0815, longitude: 121.58809), // TW/Taiwan; GeoNames 1671467
        "geonames-1849796": .init(latitude: 34.73333, longitude: 136.51667), // JP/Mie; GeoNames 1849796
        "geonames-706369": .init(latitude: 49.41835, longitude: 26.97936), // UA/Khmelnytskyi; GeoNames 706369
        "geonames-3654667": .init(latitude: -3.99313, longitude: -79.20422), // EC/Loja; GeoNames 3654667
        "geonames-1818673": .init(latitude: 22.45007, longitude: 114.16877), // HK/Tai Po; GeoNames 1818673
        "geonames-1514896": .init(latitude: 40.12649, longitude: 70.62526), // TJ/Sughd; GeoNames 1514896
        "geonames-3347719": .init(latitude: -11.78333, longitude: 19.91667), // AO/Moxico; GeoNames 3347719
        "geonames-1220253": .init(latitude: 39.9142, longitude: 69.00328), // TJ/Sughd; GeoNames 1220253
        "geonames-359173": .init(latitude: 29.07441, longitude: 31.09785), // EG/Beni Suweif; GeoNames 359173
        "geonames-1193745": .init(latitude: 24.15608, longitude: 90.7728), // BD/Dhaka Division; GeoNames 1193745
        "geonames-3557689": .init(latitude: 20.14444, longitude: -75.20917), // CU/Guantánamo Province; GeoNames 3557689
        "geonames-289888": .init(latitude: 25.29194, longitude: 51.42444), // QA/Baladiyat ar Rayyan; GeoNames 289888
        "geonames-965289": .init(latitude: -23.90449, longitude: 29.46885), // ZA/Limpopo; GeoNames 965289
        "geonames-1139715": .init(latitude: 34.42647, longitude: 70.45153), // AF/Nangarhar; GeoNames 1139715
        "geonames-170794": .init(latitude: 35.33588, longitude: 40.14084), // SY/Deir ez-Zor; GeoNames 170794
        "geonames-3121424": .init(latitude: 43.53573, longitude: -5.66152), // ES/Asturias; GeoNames 3121424
        "geonames-106297": .init(latitude: 28.43279, longitude: 45.97077), // SA/Eastern Province; GeoNames 106297
        "geonames-9645072": .init(latitude: 10.7468, longitude: 106.64903), // VN/Ho Chi Minh City (HCMC); GeoNames 9645072
        "geonames-1574023": .init(latitude: 10.36004, longitude: 106.35996), // VN/Dong Thap; GeoNames 1574023
        "geonames-2111901": .init(latitude: 36.35, longitude: 140.45), // JP/Ibaraki; GeoNames 2111901
        "geonames-2651347": .init(latitude: 52.92277, longitude: -1.47663), // GB/England; GeoNames 2651347
        "geonames-293918": .init(latitude: 32.0888, longitude: 34.88666), // IL/Central District; GeoNames 293918
        "geonames-339219": .init(latitude: 11.13333, longitude: 39.63333), // ET/Amhara; GeoNames 339219
        "geonames-1580410": .init(latitude: 20.95045, longitude: 107.07336), // VN/Quảng Ninh; GeoNames 1580410
        "geonames-2921466": .init(latitude: 51.50508, longitude: 7.09654), // DE/North Rhine-Westphalia; GeoNames 2921466
        "geonames-710791": .init(latitude: 49.44452, longitude: 32.05738), // UA/Cherkasy; GeoNames 710791
        "geonames-1702540": .init(latitude: 14.8443, longitude: 120.81039), // PH/Central Luzon; GeoNames 1702540
        "geonames-2637487": .init(latitude: 50.90395, longitude: -1.40428), // GB/England; GeoNames 2637487
        "geonames-748879": .init(latitude: 40.54889, longitude: 34.95333), // TR/Çorum; GeoNames 748879
        "geonames-3430697": .init(latitude: -34.66536, longitude: -58.72744), // AR/Buenos Aires; GeoNames 3430697
        "geonames-1884138": .init(latitude: 34.76062, longitude: 127.66215), // KR/Jeollanam-do; GeoNames 1884138
        "geonames-1841066": .init(latitude: 34.81282, longitude: 126.39181), // KR/Jeollanam-do; GeoNames 1841066
        "geonames-1283581": .init(latitude: 27.01736, longitude: 84.88047), // NP/Madhesh; GeoNames 1283581
        "geonames-466806": .init(latitude: 56.63877, longitude: 47.89078), // RU/Mariy-El Republic; GeoNames 466806
        "geonames-7838895": .init(latitude: 32.01778, longitude: 36.04639), // JO/Zarqa; GeoNames 7838895
        "geonames-1215502": .init(latitude: 5.54167, longitude: 95.33333), // ID/Aceh; GeoNames 1215502
        "geonames-349158": .init(latitude: 30.55258, longitude: 31.00904), // EG/Monufia; GeoNames 349158
        "geonames-1170295": .init(latitude: 25.5276, longitude: 69.01255), // PK/Sindh; GeoNames 1170295
        "geonames-3682385": .init(latitude: 7.06222, longitude: -73.08644), // CO/Santander Department; GeoNames 3682385
        "geonames-1850158": .init(latitude: 34.06667, longitude: 134.56667), // JP/Tokushima; GeoNames 1850158
        "geonames-1841598": .init(latitude: 35.82333, longitude: 128.73778), // KR/Gyeongsangbuk-do; GeoNames 1841598
        "geonames-347796": .init(latitude: 26.55695, longitude: 31.69478), // EG/Sohag; GeoNames 347796
        "geonames-3717588": .init(latitude: 19.11136, longitude: -72.70078), // HT/Artibonite; GeoNames 3717588
        "geonames-1185281": .init(latitude: 22.65657, longitude: 89.79123), // BD/Khulna Division; GeoNames 1185281
        "geonames-1581047": .init(latitude: 18.34282, longitude: 105.90569), // VN/Hà Tĩnh Province; GeoNames 1581047
        "geonames-6141256": .init(latitude: 52.13238, longitude: -106.66892), // CA/Saskatchewan; GeoNames 6141256
        "geonames-2500017": .init(latitude: 34.67279, longitude: 3.263), // DZ/Djelfa; GeoNames 2500017
        "geonames-158027": .init(latitude: -6.76667, longitude: 38.91667), // TZ/Pwani; GeoNames 158027
        "geonames-3247449": .init(latitude: 50.77664, longitude: 6.08342), // DE/North Rhine-Westphalia; GeoNames 3247449
        "geonames-3740007": .init(latitude: 18.58028, longitude: -72.33806), // HT/Ouest; GeoNames 3740007
        "geonames-380148": .init(latitude: 11.46186, longitude: 26.12583), // SD/Eastern Darfur; GeoNames 380148
        "geonames-136256": .init(latitude: 32.38114, longitude: 48.40581), // IR/Khuzestan; GeoNames 136256
        "geonames-710719": .init(latitude: 48.29045, longitude: 25.93241), // UA/Chernivtsi; GeoNames 710719
        "geonames-3654410": .init(latitude: -0.94937, longitude: -80.73137), // EC/Manabí; GeoNames 3654410
        "geonames-2389422": .init(latitude: 4.45437, longitude: 18.53475), // CF/Ombella-M'Poko; GeoNames 2389422
        "geonames-3652350": .init(latitude: -1.66506, longitude: -78.65887), // EC/Chimborazo Province; GeoNames 3652350
        "geonames-300619": .init(latitude: 39.74833, longitude: 37.01611), // TR/Sivas; GeoNames 300619
        "geonames-2633691": .init(latitude: 52.58547, longitude: -2.12296), // GB/England; GeoNames 2633691
        "geonames-1819873": .init(latitude: 22.49487, longitude: 114.13949), // HK/North District; GeoNames 1819873
        "geonames-1678836": .init(latitude: 23.47917, longitude: 120.44889), // TW/Taiwan; GeoNames 1678836
        "geonames-124877": .init(latitude: 37.39206, longitude: 46.23909), // IR/East Azerbaijan; GeoNames 124877
        "geonames-3429652": .init(latitude: -34.72065, longitude: -58.25454), // AR/Buenos Aires; GeoNames 3429652
        "geonames-1863985": .init(latitude: 36.06443, longitude: 136.22257), // JP/Fukui; GeoNames 1863985
        "geonames-2869894": .init(latitude: 51.18539, longitude: 6.44172), // DE/North Rhine-Westphalia; GeoNames 2869894
        "geonames-686967": .init(latitude: 50.26235, longitude: 28.67913), // UA/Zhytomyr Oblast; GeoNames 686967
        "geonames-161218": .init(latitude: -2.8, longitude: 33.98333), // TZ/Simiyu; GeoNames 161218
        "geonames-1069166": .init(latitude: -19.86586, longitude: 47.03333), // MG/Vakinankaratra; GeoNames 1069166
        "geonames-363619": .init(latitude: 4.09444, longitude: 30.67639), // SS/Central Equatoria; GeoNames 363619
        "geonames-1062663": .init(latitude: -15.71667, longitude: 46.31667), // MG/Boeny; GeoNames 1062663
        "geonames-2640194": .init(latitude: 50.37153, longitude: -4.14305), // GB/England; GeoNames 2640194
        "geonames-1512979": .init(latitude: 40.52861, longitude: 70.9425), // UZ/Fergana; GeoNames 1512979
        "geonames-293703": .init(latitude: 31.97102, longitude: 34.78939), // IL/Central District; GeoNames 293703
        "geonames-2636841": .init(latitude: 53.00415, longitude: -2.18538), // GB/England; GeoNames 2636841
        "geonames-3836564": .init(latitude: -24.1928, longitude: -65.29342), // AR/Jujuy; GeoNames 3836564
        "geonames-3104499": .init(latitude: 42.84998, longitude: -2.67268), // ES/Basque Country; GeoNames 3104499
        "geonames-3120619": .init(latitude: 41.35967, longitude: 2.10028), // ES/Catalonia; GeoNames 3120619
        "geonames-3099424": .init(latitude: 54.51889, longitude: 18.53188), // PL/Pomerania; GeoNames 3099424
        "geonames-5992996": .init(latitude: 43.42537, longitude: -80.5112), // CA/Ontario; GeoNames 5992996
        "geonames-3522210": .init(latitude: 20.11697, longitude: -98.73329), // MX/Hidalgo; GeoNames 3522210
        "geonames-919009": .init(latitude: -12.52897, longitude: 27.88382), // ZM/Copperbelt; GeoNames 919009
        "geonames-692194": .init(latitude: 50.91741, longitude: 34.79906), // UA/Sumy; GeoNames 692194
        "geonames-2642465": .init(latitude: 52.04172, longitude: -0.75583), // GB/England; GeoNames 2642465
        "geonames-12170526": .init(latitude: -8.98007, longitude: 13.30781), // AO/Luanda; GeoNames 12170526
        "geonames-1002108": .init(latitude: -26.215, longitude: 28.164), // ZA/Gauteng; GeoNames 1002108
        "geonames-2392204": .init(latitude: 9.33716, longitude: 2.63031), // BJ/Borgou; GeoNames 2392204
        "geonames-215771": .init(latitude: 2.77391, longitude: 27.61603), // CD/Haut-Uele; GeoNames 215771
        "geonames-116996": .init(latitude: 36.56332, longitude: 53.06009), // IR/Māzandarān; GeoNames 116996
        "geonames-2407790": .init(latitude: 7.87687, longitude: -11.19025), // SL/Eastern Province; GeoNames 2407790
        "geonames-99106": .init(latitude: 30.96324, longitude: 47.26998), // IQ/Basra; GeoNames 99106
        "geonames-3347019": .init(latitude: -15.19611, longitude: 12.15222), // AO/Namibe; GeoNames 3347019
        "geonames-1608133": .init(latitude: 13.86075, longitude: 100.51477), // TH/Nonthaburi; GeoNames 1608133
        "geonames-1336134": .init(latitude: 21.43973, longitude: 92.00955), // BD/Chittagong; GeoNames 1336134
        "geonames-1513243": .init(latitude: 40.47237, longitude: 71.72463), // UZ/Fergana; GeoNames 1513243
        "geonames-2394092": .init(latitude: 6.38948, longitude: 2.34581), // BJ/Atlantique; GeoNames 2394092
        "geonames-683844": .init(latitude: 45.64861, longitude: 25.60613), // RO/Brașov County; GeoNames 683844
        "geonames-962367": .init(latitude: -28.78301, longitude: 32.03768), // ZA/KwaZulu-Natal; GeoNames 962367
        "geonames-350550": .init(latitude: 26.16418, longitude: 32.72671), // EG/Qena; GeoNames 350550
        "geonames-632453": .init(latitude: 60.29414, longitude: 25.04099), // FI/Uusimaa; GeoNames 632453
        "geonames-2891122": .init(latitude: 54.32133, longitude: 10.13489), // DE/Schleswig-Holstein; GeoNames 2891122
        "geonames-379555": .init(latitude: 13.62793, longitude: 25.34936), // SD/Northern Darfur; GeoNames 379555
        "geonames-2244799": .init(latitude: 14.78333, longitude: -16.96667), // SN/Thies; GeoNames 2244799
        "geonames-3633622": .init(latitude: 10.34954, longitude: -67.04266), // VE/Miranda; GeoNames 3633622
        "geonames-3835869": .init(latitude: -27.80047, longitude: -64.26285), // AR/Santiago del Estero; GeoNames 3835869
        "geonames-2481700": .init(latitude: 36.19112, longitude: 5.41373), // DZ/Sétif; GeoNames 2481700
        "geonames-140044": .init(latitude: 33.8973, longitude: 48.7516), // IR/Lorestan Province; GeoNames 140044
        "geonames-32767": .init(latitude: 35.42873, longitude: 51.57757), // IR/Tehran; GeoNames 32767
        "geonames-325303": .init(latitude: 38.75667, longitude: 30.54333), // TR/Afyonkarahisar Province; GeoNames 325303
        "geonames-179330": .init(latitude: -1.03326, longitude: 37.06933), // KE/Nairobi County; GeoNames 179330
        "geonames-1690039": .init(latitude: 15.03425, longitude: 120.68445), // PH/Central Luzon; GeoNames 1690039
        "geonames-3347353": .init(latitude: -14.6585, longitude: 17.69099), // AO/Cubango; GeoNames 3347353
        "geonames-333772": .init(latitude: 7.67344, longitude: 36.83441), // ET/Oromiya; GeoNames 333772
        "geonames-665087": .init(latitude: 45.75372, longitude: 21.22571), // RO/Timiș County; GeoNames 665087
        "geonames-3537906": .init(latitude: 22.40711, longitude: -79.96581), // CU/Villa Clara Province; GeoNames 3537906
        "geonames-3119841": .init(latitude: 43.37135, longitude: -8.396), // ES/Galicia; GeoNames 3119841
        "geonames-4000900": .init(latitude: 24.14231, longitude: -110.31316), // MX/Baja California Sur; GeoNames 4000900
        "geonames-95005": .init(latitude: 34.62805, longitude: 45.31852), // IQ/Sulaymaniyah; GeoNames 95005
        "geonames-366847": .init(latitude: 13.1483, longitude: 33.93117), // SD/Sennar; GeoNames 366847
        "geonames-787657": .init(latitude: 43.32472, longitude: 21.90333), // RS/Central Serbia; GeoNames 787657
        "geonames-3872348": .init(latitude: -33.59217, longitude: -70.6996), // CL/Santiago Metropolitan; GeoNames 3872348
        "geonames-925475": .init(latitude: -11.46556, longitude: 34.02071), // MW/Northern Region; GeoNames 925475
        "geonames-5911606": .init(latitude: 49.26636, longitude: -122.95263), // CA/British Columbia; GeoNames 5911606
        "geonames-2110556": .init(latitude: 38.23333, longitude: 140.36667), // JP/Yamagata; GeoNames 2110556
        "geonames-3640049": .init(latitude: 10.47027, longitude: -66.61934), // VE/Miranda; GeoNames 3640049
        "geonames-2992166": .init(latitude: 43.61093, longitude: 3.87635), // FR/Occitanie; GeoNames 2992166
        "geonames-3100946": .init(latitude: 50.79646, longitude: 19.12409), // PL/Silesia; GeoNames 3100946
        "geonames-1321937": .init(latitude: 16.88874, longitude: 96.10257), // MM/Yangon; GeoNames 1321937
        "geonames-2940132": .init(latitude: 50.8357, longitude: 12.92922), // DE/Saxony; GeoNames 2940132
        "geonames-3841956": .init(latitude: -31.73271, longitude: -60.52897), // AR/Entre Rios; GeoNames 3841956
        "geonames-3583446": .init(latitude: 13.48261, longitude: -88.18211), // SV/San Miguel Department; GeoNames 3583446
        "geonames-944986": .init(latitude: -26.71171, longitude: 27.83795), // ZA/Gauteng; GeoNames 944986
        "geonames-3645213": .init(latitude: 11.40769, longitude: -69.67822), // VE/Falcón; GeoNames 3645213
        "geonames-2641430": .init(latitude: 52.25, longitude: -0.88333), // GB/England; GeoNames 2641430
        "geonames-3937513": .init(latitude: -15.5, longitude: -70.13333), // PE/Puno; GeoNames 3937513
        "geonames-2281606": .init(latitude: 6.62103, longitude: -5.91144), // CI/Zanzan District; GeoNames 2281606
        "geonames-9171969": .init(latitude: 24.06956, longitude: 90.22212), // BD/Dhaka Division; GeoNames 9171969
        "geonames-485239": .init(latitude: 61.66393, longitude: 50.8163), // RU/Komi; GeoNames 485239
        "geonames-132892": .init(latitude: 36.8427, longitude: 54.44391), // IR/Golestan; GeoNames 132892
        "geonames-2755251": .init(latitude: 53.21917, longitude: 6.56667), // NL/Groningen; GeoNames 2755251
        "geonames-1283582": .init(latitude: 26.45505, longitude: 87.27007), // NP/Koshi; GeoNames 1283582
        "geonames-2945024": .init(latitude: 52.26594, longitude: 10.52673), // DE/Lower Saxony; GeoNames 2945024
        "geonames-3625542": .init(latitude: 9.31778, longitude: -70.60361), // VE/Trujillo; GeoNames 3625542
        "geonames-1300466": .init(latitude: 17.33521, longitude: 96.48135), // MM/Bago Region; GeoNames 1300466
        "geonames-2874545": .init(latitude: 52.13129, longitude: 11.63189), // DE/Saxony-Anhalt; GeoNames 2874545
        "geonames-3648439": .init(latitude: 10.43424, longitude: -66.87558), // VE/Miranda; GeoNames 3648439
        "geonames-1336140": .init(latitude: 23.16971, longitude: 89.21371), // BD/Khulna Division; GeoNames 1336140
        "geonames-304827": .init(latitude: 38.61202, longitude: 27.42647), // TR/Manisa; GeoNames 304827
        "geonames-695594": .init(latitude: 50.62036, longitude: 26.23695), // UA/Rivne Oblast; GeoNames 695594
        "geonames-12042053": .init(latitude: 24.35893, longitude: 54.48267), // AE/Abu Dhabi; GeoNames 12042053
        "geonames-64435": .init(latitude: 10.43959, longitude: 45.01432), // SO/Woqooyi Galbeed; GeoNames 64435
        "geonames-2284647": .init(latitude: 7.41251, longitude: -7.55383), // CI/Montagnes; GeoNames 2284647
        "geonames-3899361": .init(latitude: -18.47552, longitude: -70.30058), // CL/Arica y Parinacota Region; GeoNames 3899361
        "geonames-3876682": .init(latitude: -33.46836, longitude: -70.53411), // CL/Santiago Metropolitan; GeoNames 3876682
        "geonames-3688451": .init(latitude: 3.87962, longitude: -77.03105), // CO/Valle del Cauca Department; GeoNames 3688451
        "geonames-3645527": .init(latitude: 10.20161, longitude: -71.3148), // VE/Zulia; GeoNames 3645527
        "geonames-13607978": .init(latitude: -12.58997, longitude: 13.39123), // AO/Benguela; GeoNames 13607978
        "geonames-707753": .init(latitude: 48.29986, longitude: 38.01709), // UA/Donetsk; GeoNames 707753
        "geonames-1035025": .init(latitude: -14.56257, longitude: 40.68538), // MZ/Nampula; GeoNames 1035025
        "geonames-523523": .init(latitude: 43.49806, longitude: 43.61889), // RU/Kabardino-Balkariya Republic; GeoNames 523523
        "geonames-158214": .init(latitude: -4.57667, longitude: 30.1025), // TZ/Kigoma; GeoNames 158214
        "geonames-707471": .init(latitude: 48.92312, longitude: 24.71248), // UA/Ivano-Frankivsk; GeoNames 707471
        "geonames-2224827": .init(latitude: 7.32765, longitude: 13.58472), // CM/Adamaoua; GeoNames 2224827
        "geonames-322165": .init(latitude: 39.64917, longitude: 27.88611), // TR/Balıkesir; GeoNames 322165
        "geonames-3870011": .init(latitude: -38.73628, longitude: -72.59738), // CL/Araucania; GeoNames 3870011
        "geonames-2884509": .init(latitude: 51.33645, longitude: 6.55381), // DE/North Rhine-Westphalia; GeoNames 2884509
        "geonames-1329221": .init(latitude: 21.90709, longitude: 96.04894), // MM/Mandalay Region; GeoNames 1329221
        "geonames-143534": .init(latitude: 36.46961, longitude: 52.35072), // IR/Māzandarān; GeoNames 143534
        "geonames-10402606": .init(latitude: -8.84861, longitude: 13.275), // AO/Luanda; GeoNames 10402606
        "geonames-2925177": .init(latitude: 47.9959, longitude: 7.85222), // DE/Baden-Wurttemberg; GeoNames 2925177
        "geonames-109435": .init(latitude: 27.0174, longitude: 49.62251), // SA/Eastern Province; GeoNames 109435
        "geonames-1868144": .init(latitude: 39.75261, longitude: 126.25798), // KP/South Pyongan; GeoNames 1868144
        "geonames-1328421": .init(latitude: 16.77919, longitude: 94.73212), // MM/Ayeyarwady; GeoNames 1328421
        "geonames-1185099": .init(latitude: 24.89904, longitude: 91.87198), // BD/Sylhet Division; GeoNames 1185099
        "geonames-3363094": .init(latitude: -33.73378, longitude: 18.97523), // ZA/Western Cape; GeoNames 3363094
        "geonames-2756253": .init(latitude: 51.44083, longitude: 5.47778), // NL/North Brabant; GeoNames 2756253
        "geonames-5586437": .init(latitude: 43.6135, longitude: -116.20345), // US/Idaho; GeoNames 5586437
        "geonames-2013159": .init(latitude: 62.03114, longitude: 129.72288), // RU/Sakha; GeoNames 2013159
        "geonames-8594709": .init(latitude: 10.49626, longitude: 107.1685), // VN/Ho Chi Minh City (HCMC); GeoNames 8594709
        "geonames-55671": .init(latitude: -0.35817, longitude: 42.54536), // SO/Lower Juba; GeoNames 55671
        "geonames-2518559": .init(latitude: 38.26218, longitude: -0.70107), // ES/Valencia; GeoNames 2518559
        "geonames-212902": .init(latitude: -2.94373, longitude: 25.92237), // CD/Maniema; GeoNames 212902
        "geonames-680332": .init(latitude: 44.31667, longitude: 23.8), // RO/Dolj; GeoNames 680332
        "geonames-3612907": .init(latitude: 14.03333, longitude: -86.58333), // HN/El Paraíso Department; GeoNames 3612907
        "geonames-1665221": .init(latitude: 23.02444, longitude: 120.25556), // TW/Taiwan; GeoNames 1665221
        "geonames-2410048": .init(latitude: 7.96472, longitude: -11.73833), // SL/Southern Province; GeoNames 2410048
        "geonames-1853303": .init(latitude: 33.23333, longitude: 130.3), // JP/Saga; GeoNames 1853303
        "geonames-1028918": .init(latitude: -12.97395, longitude: 40.51775), // MZ/Cabo Delgado Province; GeoNames 1028918
        "geonames-149879": .init(latitude: -4.81629, longitude: 34.74358), // TZ/Singida; GeoNames 149879
        "geonames-157738": .init(latitude: -4.87694, longitude: 29.62667), // TZ/Kigoma; GeoNames 157738
        "geonames-3843123": .init(latitude: -38.95078, longitude: -68.0592), // AR/Neuquen; GeoNames 3843123
        "geonames-1219649": .init(latitude: 39.07328, longitude: 63.57861), // TM/Lebap; GeoNames 1219649
        "geonames-1736372": .init(latitude: 6.04934, longitude: 102.13987), // MY/Kelantan; GeoNames 1736372
        "geonames-12076997": .init(latitude: -34.51541, longitude: -58.76813), // AR/Buenos Aires; GeoNames 12076997
        "geonames-54225": .init(latitude: 1.71594, longitude: 44.77166), // SO/Lower Shabeelle; GeoNames 54225
        "geonames-701822": .init(latitude: 47.09514, longitude: 37.54131), // UA/Donetsk; GeoNames 701822
        "geonames-295514": .init(latitude: 32.08074, longitude: 34.8338), // IL/Tel Aviv; GeoNames 295514
        "geonames-266826": .init(latitude: 34.43352, longitude: 35.84415), // LB/North Lebanon; GeoNames 266826
        "geonames-741100": .init(latitude: 40.97782, longitude: 37.89047), // TR/Ordu; GeoNames 741100
        "geonames-3805673": .init(latitude: 7.88963, longitude: -67.47181), // VE/Apure; GeoNames 3805673
        "geonames-3727135": .init(latitude: 18.57677, longitude: -72.22625), // HT/Ouest; GeoNames 3727135
        "geonames-295629": .init(latitude: 31.79213, longitude: 34.64966), // IL/Southern District; GeoNames 295629
        "geonames-1571058": .init(latitude: 10.92889, longitude: 108.10208), // VN/Lam Dong; GeoNames 1571058
        "geonames-102651": .init(latitude: 17.1495, longitude: 42.62537), // SA/Jazan Region; GeoNames 102651
        "geonames-294071": .init(latitude: 32.33294, longitude: 34.85917), // IL/Central District; GeoNames 294071
        "geonames-3437056": .init(latitude: -25.33968, longitude: -57.50879), // PY/Central Department; GeoNames 3437056
        "geonames-2983990": .init(latitude: 48.11109, longitude: -1.67431), // FR/Brittany; GeoNames 2983990
        "geonames-2542051": .init(latitude: 33.68607, longitude: -7.38298), // MA/Casablanca-Settat; GeoNames 2542051
        "geonames-3639898": .init(latitude: 10.474, longitude: -66.54241), // VE/Miranda; GeoNames 3639898
        "geonames-4315588": .init(latitude: 30.44332, longitude: -91.18747), // US/Louisiana; GeoNames 4315588
        "geonames-3085128": .init(latitude: 50.28682, longitude: 19.10385), // PL/Silesia; GeoNames 3085128
        "geonames-1517945": .init(latitude: 43.29458, longitude: 68.25685), // KZ/Turkistan; GeoNames 1517945
        "geonames-989921": .init(latitude: -26.85213, longitude: 26.66672), // ZA/North West; GeoNames 989921
        "geonames-2339937": .init(latitude: 12.17024, longitude: 6.66412), // NG/Zamfara State; GeoNames 2339937
        "geonames-709932": .init(latitude: 48.51716, longitude: 34.60617), // UA/Dnipropetrovsk; GeoNames 709932
        "geonames-760778": .init(latitude: 51.40253, longitude: 21.14714), // PL/Mazovia; GeoNames 760778
        "geonames-4781708": .init(latitude: 37.55376, longitude: -77.46026), // US/Virginia; GeoNames 4781708
        "geonames-1679136": .init(latitude: 24.07327, longitude: 120.56276), // TW/Taiwan; GeoNames 1679136
        "geonames-1993459": .init(latitude: 24.0692, longitude: 120.5512), // TW/Taiwan; GeoNames 1993459
        "geonames-2416969": .init(latitude: 7.75624, longitude: -8.8179), // GN/Nzérékoré Region; GeoNames 2416969
        "geonames-6119109": .init(latitude: 50.45008, longitude: -104.6178), // CA/Saskatchewan; GeoNames 6119109
        "geonames-1586443": .init(latitude: 9.17682, longitude: 105.15242), // VN/Ca Mau; GeoNames 1586443
        "geonames-1632654": .init(latitude: -2.12914, longitude: 106.11377), // ID/Bangka–Belitung Islands; GeoNames 1632654
        "geonames-691650": .init(latitude: 49.55404, longitude: 25.59067), // UA/Ternopil; GeoNames 691650
        "geonames-1185162": .init(latitude: 24.75636, longitude: 90.40646), // BD/Mymensingh Division; GeoNames 1185162
        "geonames-2026609": .init(latitude: 50.27593, longitude: 127.52637), // RU/Amur Oblast; GeoNames 2026609
        "geonames-2229752": .init(latitude: 4.6363, longitude: 9.4469), // CM/South-West; GeoNames 2229752
        "geonames-724443": .init(latitude: 48.71441, longitude: 21.25802), // SK/Košice Region; GeoNames 724443
        "geonames-704147": .init(latitude: 49.06253, longitude: 33.40484), // UA/Poltava; GeoNames 704147
        "geonames-884979": .init(latitude: -18.9707, longitude: 32.67086), // ZW/Manicaland; GeoNames 884979
        "geonames-3893894": .init(latitude: -36.82699, longitude: -73.04977), // CL/Biobio; GeoNames 3893894
        "geonames-98717": .init(latitude: 33.42056, longitude: 43.30778), // IQ/Anbar; GeoNames 98717
        "geonames-2874225": .init(latitude: 49.98185, longitude: 8.28008), // DE/Rheinland-Pfalz; GeoNames 2874225
        "geonames-519336": .init(latitude: 58.52131, longitude: 31.27104), // RU/Novgorod Oblast; GeoNames 519336
        "geonames-3641351": .init(latitude: 8.88902, longitude: -64.2527), // VE/Anzoátegui; GeoNames 3641351
        "geonames-1877615": .init(latitude: 38.04056, longitude: 125.71472), // KP/South Hwanghae; GeoNames 1877615
        "geonames-3433899": .init(latitude: -26.18489, longitude: -58.17313), // AR/Formosa; GeoNames 3433899
        "geonames-3608248": .init(latitude: 15.75971, longitude: -86.78221), // HN/Atlántida Department; GeoNames 3608248
        "geonames-2746301": .init(latitude: 51.55551, longitude: 5.0913), // NL/North Brabant; GeoNames 2746301
        "geonames-153209": .init(latitude: -3.35, longitude: 37.33333), // TZ/Kilimanjaro; GeoNames 153209
        "geonames-3666645": .init(latitude: 4.08484, longitude: -76.19548), // CO/Valle del Cauca Department; GeoNames 3666645
        "geonames-1567788": .init(latitude: 9.59995, longitude: 105.97193), // VN/Can Tho City; GeoNames 1567788
        "geonames-2419992": .init(latitude: 10.38542, longitude: -9.30568), // GN/Kankan Region; GeoNames 2419992
        "geonames-229268": .init(latitude: -0.60467, longitude: 30.64851), // UG/Western Region; GeoNames 229268
        "geonames-3655673": .init(latitude: 0.34881, longitude: -78.12462), // EC/Imbabura; GeoNames 3655673
        "geonames-3204541": .init(latitude: 44.77879, longitude: 17.20629), // BA/Srpska; GeoNames 3204541
        "geonames-3531732": .init(latitude: 19.84073, longitude: -90.51676), // MX/Campeche; GeoNames 3531732
        "geonames-3114711": .init(latitude: 43.36029, longitude: -5.84476), // ES/Asturias; GeoNames 3114711
        "geonames-1626542": .init(latitude: -0.87956, longitude: 131.26104), // ID/Southwest Papua; GeoNames 1626542
        "geonames-2524170": .init(latitude: 38.19394, longitude: 15.55256), // IT/Sicily; GeoNames 2524170
        "geonames-1234569": .init(latitude: 6.84019, longitude: 79.87116), // LK/Western Province; GeoNames 1234569
        "geonames-705812": .init(latitude: 48.50834, longitude: 32.26618), // UA/Kirovohrad; GeoNames 705812
        "geonames-1611110": .init(latitude: 13.3622, longitude: 100.98345), // TH/Chon Buri; GeoNames 1611110
        "geonames-2929670": .init(latitude: 50.97734, longitude: 11.03536), // DE/Thuringia; GeoNames 2929670
        "geonames-3657990": .init(latitude: 0.9592, longitude: -79.65397), // EC/Esmeraldas; GeoNames 3657990
        "geonames-2454268": .init(latitude: 12.38723, longitude: -5.46507), // ML/Sikasso; GeoNames 2454268
        "geonames-3493032": .init(latitude: 18.4539, longitude: -69.30864), // DO/San Pedro de Macorís; GeoNames 3493032
        "geonames-677697": .init(latitude: 45.43687, longitude: 28.05028), // RO/Galați County; GeoNames 677697
        "geonames-3129028": .init(latitude: 41.45004, longitude: 2.24741), // ES/Catalonia; GeoNames 3129028
        "geonames-1178338": .init(latitude: 35.91869, longitude: 74.31245), // PK/Gilgit-Baltistan; GeoNames 1178338
        "geonames-3133880": .init(latitude: 63.43049, longitude: 10.39506), // NO/Trøndelag; GeoNames 3133880
        "geonames-3629965": .init(latitude: 10.95771, longitude: -63.86971), // VE/Nueva Esparta; GeoNames 3629965
        "geonames-702569": .init(latitude: 50.75784, longitude: 25.35024), // UA/Volyn; GeoNames 702569
        "geonames-8556321": .init(latitude: 15.76667, longitude: -86.83333), // HN/Atlántida Department; GeoNames 8556321
        "geonames-5780993": .init(latitude: 40.76078, longitude: -111.89105), // US/Utah; GeoNames 5780993
        "geonames-3194360": .init(latitude: 45.25167, longitude: 19.83694), // RS/Vojvodina; GeoNames 3194360
        "geonames-1567069": .init(latitude: 10.53589, longitude: 106.41366), // VN/Tay Ninh; GeoNames 1567069
        "geonames-1819400": .init(latitude: 22.40613, longitude: 114.24079), // HK/Sha Tin; GeoNames 1819400
        "geonames-2243940": .init(latitude: 12.56801, longitude: -16.27326), // SN/Ziguinchor; GeoNames 2243940
        "geonames-1221194": .init(latitude: 37.91459, longitude: 69.78454), // TJ/Khatlon Province; GeoNames 1221194
        "geonames-2544248": .init(latitude: 32.88108, longitude: -6.9063), // MA/Beni Mellal-Khenifra; GeoNames 2544248
        "geonames-4853828": .init(latitude: 41.60054, longitude: -93.60911), // US/Iowa; GeoNames 4853828
        "geonames-2595323": .init(latitude: 5.31198, longitude: -3.99363), // CI/Abidjan Autonomous District; GeoNames 2595323
        "geonames-2520058": .init(latitude: 37.60197, longitude: -0.98397), // ES/Murcia; GeoNames 2520058
        "geonames-3652567": .init(latitude: -1.02881, longitude: -79.46264), // EC/Los Ríos; GeoNames 3652567
        "geonames-2550078": .init(latitude: 33.25682, longitude: -8.50882), // MA/Casablanca-Settat; GeoNames 2550078
        "geonames-665004": .init(latitude: 46.54245, longitude: 24.55747), // RO/Mureș County; GeoNames 665004
        "geonames-1677112": .init(latitude: 24.83833, longitude: 121.00778), // TW/Taiwan; GeoNames 1677112
        "geonames-3873775": .init(latitude: -34.1691, longitude: -70.74053), // CL/O'Higgins Region; GeoNames 3873775
        "geonames-2302357": .init(latitude: 5.10535, longitude: -1.2466), // GH/Central; GeoNames 2302357
        "geonames-1207337": .init(latitude: 23.22714, longitude: 90.65433), // BD/Chittagong; GeoNames 1207337
        "geonames-3598119": .init(latitude: 15.47025, longitude: -90.37455), // GT/Alta Verapaz; GeoNames 3598119
        "geonames-1586151": .init(latitude: 10.46017, longitude: 105.63294), // VN/Dong Thap; GeoNames 1586151
        "geonames-2511174": .init(latitude: 28.46824, longitude: -16.25462), // ES/Canary Islands; GeoNames 2511174
        "geonames-1514891": .init(latitude: 40.29414, longitude: 70.43122), // TJ/Sughd; GeoNames 1514891
        "geonames-110690": .init(latitude: 18.21639, longitude: 42.50528), // SA/'Asir Region; GeoNames 110690
        "geonames-732770": .init(latitude: 42.50651, longitude: 27.46886), // BG/Burgas; GeoNames 732770
        "geonames-504341": .init(latitude: 57.81922, longitude: 28.33181), // RU/Pskov Oblast; GeoNames 504341
        "geonames-2555745": .init(latitude: 32.33725, longitude: -6.34983), // MA/Beni Mellal-Khenifra; GeoNames 2555745
        "geonames-2481007": .init(latitude: 35.18994, longitude: -0.63085), // DZ/Sidi Bel Abbès; GeoNames 2481007
        "geonames-3568342": .init(latitude: 23.03811, longitude: -82.37703), // CU/Havana; GeoNames 3568342
        "geonames-1519928": .init(latitude: 53.21435, longitude: 63.62463), // KZ/Kostanay; GeoNames 1519928
        "geonames-11524601": .init(latitude: 25.00255, longitude: 55.10811), // AE/Dubai; GeoNames 11524601
        "geonames-787607": .init(latitude: 44.80556, longitude: 20.42417), // RS/Central Serbia; GeoNames 787607
        "geonames-2043572": .init(latitude: 40.96946, longitude: 126.58523), // KP/Chagang; GeoNames 2043572
        "geonames-1670909": .init(latitude: 24.92981, longitude: 121.28372), // TW/Taiwan; GeoNames 1670909
        "geonames-3909234": .init(latitude: -17.97153, longitude: -67.0932), // BO/Oruro; GeoNames 3909234
        "geonames-3500957": .init(latitude: 18.42332, longitude: -68.96635), // DO/La Romana; GeoNames 3500957
        "geonames-328689": .init(latitude: 7.2, longitude: 38.6), // ET/Oromiya; GeoNames 328689
        "geonames-3114472": .init(latitude: 42.81687, longitude: -1.64323), // ES/Navarre; GeoNames 3114472
        "geonames-1571067": .init(latitude: 11.56432, longitude: 108.98858), // VN/Khanh Hoa; GeoNames 1571067
        "geonames-339666": .init(latitude: 8.75225, longitude: 38.97846), // ET/Oromiya; GeoNames 339666
        "geonames-2045220": .init(latitude: 40.60611, longitude: 128.78194), // KP/South Hamgyong; GeoNames 2045220
        "geonames-1696710": .init(latitude: 7.8257, longitude: 123.437), // PH/Zamboanga Peninsula; GeoNames 1696710
        "geonames-3628423": .init(latitude: 10.3401, longitude: -68.74297), // VE/Yaracuy; GeoNames 3628423
        "geonames-3346015": .init(latitude: -11.20605, longitude: 13.84371), // AO/Kwanza Sul; GeoNames 3346015
        "geonames-2451478": .init(latitude: 13.44032, longitude: -6.25947), // ML/Ségou; GeoNames 2451478
        "geonames-3654870": .init(latitude: -0.93424, longitude: -78.6152), // EC/Cotopaxi; GeoNames 3654870
        "geonames-630468": .init(latitude: 53.14676, longitude: 29.20548), // BY/Mogilev; GeoNames 630468
        "geonames-1643837": .init(latitude: 0.5375, longitude: 123.0625), // ID/Gorontalo; GeoNames 1643837
        "geonames-2772400": .init(latitude: 48.30639, longitude: 14.28611), // AT/Upper Austria; GeoNames 2772400
        "geonames-1283467": .init(latitude: 28.70159, longitude: 80.58991), // NP/Sudurpashchim Pradesh; GeoNames 1283467
        "geonames-2503826": .init(latitude: 34.85038, longitude: 5.72805), // DZ/Biskra; GeoNames 2503826
        "geonames-153176": .init(latitude: -6.34379, longitude: 31.06951), // TZ/Katavi; GeoNames 153176
        "geonames-3165185": .init(latitude: 45.64953, longitude: 13.77678), // IT/Friuli Venezia Giulia; GeoNames 3165185
        "geonames-7910079": .init(latitude: 6.86, longitude: 37.76159), // ET/South Ethiopia Regional State; GeoNames 7910079
        "geonames-2208485": .init(latitude: 32.46739, longitude: 14.56874), // LY/Misratah; GeoNames 2208485
        "geonames-3171728": .init(latitude: 45.40797, longitude: 11.88586), // IT/Veneto; GeoNames 3171728
        "geonames-3550598": .init(latitude: 20.96135, longitude: -76.95192), // CU/Las Tunas Province; GeoNames 3550598
        "geonames-1857550": .init(latitude: 35.48333, longitude: 133.05), // JP/Shimane; GeoNames 1857550
        "geonames-4562831": .init(latitude: 18.39856, longitude: -66.15572), // PR/Bayamón; GeoNames 4562831
        "geonames-1064890": .init(latitude: -21.45267, longitude: 47.08569), // MG/Upper Matsiatra; GeoNames 1064890
        "geonames-2306079": .init(latitude: 5.69775, longitude: -0.32824), // GH/Greater Accra; GeoNames 2306079
        "geonames-2317397": .init(latitude: -3.31687, longitude: 17.38063), // CD/Kwilu; GeoNames 2317397
        "geonames-303195": .init(latitude: 37.07417, longitude: 36.24778), // TR/Osmaniye; GeoNames 303195
        "geonames-159071": .init(latitude: -7.76667, longitude: 35.7), // TZ/Iringa; GeoNames 159071
        "geonames-721472": .init(latitude: 47.53167, longitude: 21.62444), // HU/Hajdú-Bihar; GeoNames 721472
        "geonames-1336137": .init(latitude: 22.70497, longitude: 90.37013), // BD/Barisal Division; GeoNames 1336137
        "geonames-2219905": .init(latitude: 32.64861, longitude: 14.26191), // LY/Al Marqab; GeoNames 2219905
        "geonames-1708522": .init(latitude: 6.50306, longitude: 124.84694), // PH/Soccsksargen; GeoNames 1708522
        "geonames-4174715": .init(latitude: 30.43826, longitude: -84.28073), // US/Florida; GeoNames 4174715
        "geonames-227812": .init(latitude: 0.44166, longitude: 33.17917), // UG/Central Region; GeoNames 227812
        "geonames-3699088": .init(latitude: -7.16378, longitude: -78.50027), // PE/Cajamarca Department; GeoNames 3699088
        "geonames-601734": .init(latitude: 41.83625, longitude: 59.96661), // TM/Dasoguz; GeoNames 601734
        "geonames-343663": .init(latitude: 6.03333, longitude: 37.55), // ET/South Ethiopia Regional State; GeoNames 343663
        "geonames-1520172": .init(latitude: 54.87343, longitude: 69.15065), // KZ/North Kazakhstan; GeoNames 1520172
        "geonames-3181554": .init(latitude: 45.53558, longitude: 10.21472), // IT/Lombardy; GeoNames 3181554
        "geonames-214614": .init(latitude: -8.73508, longitude: 24.99798), // CD/Haut-Lomami; GeoNames 214614
        "geonames-2800481": .init(latitude: 50.41136, longitude: 4.44448), // BE/Wallonia; GeoNames 2800481
        "geonames-1576633": .init(latitude: 21.85264, longitude: 106.76101), // VN/Lạng Sơn Province; GeoNames 1576633
        "geonames-60149": .init(latitude: 11.76667, longitude: 51.21667), // SO/Bari; GeoNames 60149
        "geonames-1818222": .init(latitude: 22.43333, longitude: 114.03333), // HK/Yuen Long; GeoNames 1818222
        "geonames-1818225": .init(latitude: 22.44518, longitude: 114.02621), // HK/Yuen Long; GeoNames 1818225
        "geonames-2218970": .init(latitude: 32.7571, longitude: 12.72764), // LY/Az Zawiyah; GeoNames 2218970
        "geonames-3887127": .init(latitude: -20.21326, longitude: -70.15027), // CL/Tarapacá; GeoNames 3887127
        "geonames-361546": .init(latitude: 31.13159, longitude: 33.79844), // EG/North Sinai; GeoNames 361546
        "geonames-2119441": .init(latitude: 46.9543, longitude: 142.73559), // RU/Sakhalin Oblast; GeoNames 2119441
        "geonames-3099230": .init(latitude: 50.29761, longitude: 18.67658), // PL/Silesia; GeoNames 3099230
        "geonames-13512674": .init(latitude: 25.4175, longitude: 51.5075), // QA/Al Daayen; GeoNames 13512674
        "geonames-3165926": .init(latitude: 40.46438, longitude: 17.24707), // IT/Apulia; GeoNames 3165926
        "geonames-3439214": .init(latitude: -25.3552, longitude: -57.44545), // PY/Central Department; GeoNames 3439214
        "geonames-184707": .init(latitude: -0.71383, longitude: 36.43261), // KE/Nakuru County; GeoNames 184707
        "geonames-759734": .init(latitude: 50.04132, longitude: 21.99901), // PL/Subcarpathia; GeoNames 759734
        "geonames-3171457": .init(latitude: 44.79935, longitude: 10.32618), // IT/Emilia-Romagna; GeoNames 3171457
        "geonames-3870294": .init(latitude: -35.4232, longitude: -71.64974), // CL/Maule Region; GeoNames 3870294
        "geonames-2315728": .init(latitude: 3.25651, longitude: 19.77234), // CD/Sud-Ubangi; GeoNames 2315728
        "geonames-140463": .init(latitude: 32.86628, longitude: 59.22114), // IR/South Khorasan Province; GeoNames 140463
        "geonames-3696417": .init(latitude: -9.92882, longitude: -76.23989), // PE/Huánuco Department; GeoNames 3696417
        "geonames-745028": .init(latitude: 40.76499, longitude: 29.92928), // TR/Kocaeli; GeoNames 745028
        "geonames-2984114": .init(latitude: 49.26526, longitude: 4.02853), // FR/Grand Est; GeoNames 2984114
        "geonames-2462881": .init(latitude: 27.1418, longitude: -13.18797), // EH/no admin1 supplied; GeoNames 2462881
        "geonames-585915": .init(latitude: 40.44808, longitude: 49.75502), // AZ/Abşeron; GeoNames 585915
        "geonames-1607508": .init(latitude: 13.65855, longitude: 100.53362), // TH/Samut Prakan; GeoNames 1607508
        "geonames-2427455": .init(latitude: 8.57437, longitude: 16.07722), // TD/Logone Occidental; GeoNames 2427455
        "geonames-1024694": .init(latitude: -16.8375, longitude: 36.98556), // MZ/Zambezia Province; GeoNames 1024694
        "geonames-1283339": .init(latitude: 27.42839, longitude: 85.03219), // NP/Bagmati Province; GeoNames 1283339
        "geonames-3185728": .init(latitude: 41.32355, longitude: 19.45469), // AL/Durrës County; GeoNames 3185728
        "geonames-3432043": .init(latitude: -34.92126, longitude: -57.95442), // AR/Buenos Aires; GeoNames 3432043
        "geonames-1283318": .init(latitude: 26.72882, longitude: 85.92628), // NP/Madhesh; GeoNames 1283318
        "geonames-1236854": .init(latitude: 6.848, longitude: 79.9265), // LK/Western Province; GeoNames 1236854
        "geonames-4076784": .init(latitude: 32.36681, longitude: -86.29997), // US/Alabama; GeoNames 4076784
        "geonames-2792413": .init(latitude: 50.63373, longitude: 5.56749), // BE/Wallonia; GeoNames 2792413
        "geonames-1283562": .init(latitude: 27.69121, longitude: 83.45251), // NP/Lumbini Province; GeoNames 1283562
        "geonames-2455518": .init(latitude: 14.44776, longitude: -11.44393), // ML/Kayes; GeoNames 2455518
        "geonames-354502": .init(latitude: 31.11174, longitude: 30.93991), // EG/Kafr el-Sheikh; GeoNames 354502
        "geonames-2477461": .init(latitude: 35.40417, longitude: 8.12417), // DZ/Tébessa; GeoNames 2477461
        "geonames-193624": .init(latitude: -1.17641, longitude: 36.7564), // KE/Kiambu County; GeoNames 193624
        "geonames-2417786": .init(latitude: 9.73333, longitude: -13.41667), // GN/Kindia; GeoNames 2417786
        "geonames-747764": .init(latitude: 40.83889, longitude: 31.16389), // TR/Düzce; GeoNames 747764
        "geonames-2742032": .init(latitude: 41.5514, longitude: -8.42311), // PT/Braga; GeoNames 2742032
        "geonames-909863": .init(latitude: -13.13667, longitude: 28.41661), // ZM/Copperbelt; GeoNames 909863
        "geonames-7026720": .init(latitude: 13.69301, longitude: 100.40755), // TH/Bangkok; GeoNames 7026720
        "geonames-2043837": .init(latitude: 41.40167, longitude: 128.17778), // KP/Yanggang-do; GeoNames 2043837
        "geonames-3567597": .init(latitude: 20.37368, longitude: -76.64272), // CU/Granma Province; GeoNames 3567597
        "geonames-769250": .init(latitude: 50.87033, longitude: 20.62752), // PL/Świętokrzyskie; GeoNames 769250
        "geonames-3080985": .init(latitude: 50.32492, longitude: 18.78576), // PL/Silesia; GeoNames 3080985
        "geonames-2190324": .init(latitude: -37.78333, longitude: 175.28333), // NZ/Waikato Region; GeoNames 2190324
        "geonames-140380": .init(latitude: 37.47473, longitude: 57.32903), // IR/North Khorasan; GeoNames 140380
        "geonames-294751": .init(latitude: 32.0122, longitude: 34.77826), // IL/Tel Aviv; GeoNames 294751
        "geonames-1610780": .init(latitude: 7.00836, longitude: 100.47668), // TH/Songkhla; GeoNames 1610780
        "geonames-228853": .init(latitude: 0.35333, longitude: 32.75528), // UG/Central Region; GeoNames 228853
        "geonames-1514581": .init(latitude: 41.01667, longitude: 70.14361), // UZ/Tashkent Region; GeoNames 1514581
        "geonames-1514879": .init(latitude: 40.28256, longitude: 69.62216), // TJ/Sughd; GeoNames 1514879
        "geonames-2304121": .init(latitude: 5.69951, longitude: -0.03484), // GH/Greater Accra; GeoNames 2304121
        "geonames-1608048": .init(latitude: 13.91179, longitude: 100.49774), // TH/Nonthaburi; GeoNames 1608048
        "geonames-99454": .init(latitude: 33.34913, longitude: 43.78599), // IQ/Anbar; GeoNames 99454
        "geonames-3101950": .init(latitude: 50.34802, longitude: 18.93282), // PL/Silesia; GeoNames 3101950
        "geonames-334609": .init(latitude: 7.54978, longitude: 37.85374), // ET/Central Ethiopia Regional State; GeoNames 334609
        "geonames-3670745": .init(latitude: 11.54444, longitude: -72.90722), // CO/La Guajira Department; GeoNames 3670745
        "geonames-3068160": .init(latitude: 49.74747, longitude: 13.37759), // CZ/Plzeň Region; GeoNames 3068160
        "geonames-3544091": .init(latitude: 22.41649, longitude: -83.69657), // CU/Pinar del Río; GeoNames 3544091
        "geonames-307654": .init(latitude: 39.84528, longitude: 33.50639), // TR/Kırıkkale; GeoNames 307654
        "geonames-3564124": .init(latitude: 22.14681, longitude: -80.4481), // CU/Cienfuegos Province; GeoNames 3564124
        "geonames-295530": .init(latitude: 31.25181, longitude: 34.7913), // IL/Southern District; GeoNames 295530
        "geonames-2421820": .init(latitude: 9.55111, longitude: -13.67306), // GN/Conakry; GeoNames 2421820
        "geonames-2497411": .init(latitude: 33.35608, longitude: 6.86319), // DZ/El Oued; GeoNames 2497411
        "geonames-2453348": .init(latitude: 14.4843, longitude: -4.18296), // ML/Mopti; GeoNames 2453348
        "geonames-248460": .init(latitude: 31.87913, longitude: 35.92098), // JO/Amman; GeoNames 248460
        "geonames-2216885": .init(latitude: 32.75222, longitude: 12.72778), // LY/Az Zawiyah; GeoNames 2216885
        "geonames-380174": .init(latitude: 11.7891, longitude: 34.3592), // SD/Blue Nile; GeoNames 380174
        "geonames-3003796": .init(latitude: 49.49346, longitude: 0.10785), // FR/Normandy; GeoNames 3003796
        "geonames-2852458": .init(latitude: 52.39886, longitude: 13.06566), // DE/Brandenburg; GeoNames 2852458
        "geonames-750516": .init(latitude: 40.73583, longitude: 31.60611), // TR/Bolu; GeoNames 750516
        "geonames-173377": .init(latitude: 37.05215, longitude: 41.23142), // SY/Al-Hasakah; GeoNames 173377
        "geonames-1512236": .init(latitude: 53.7154, longitude: 91.42593), // RU/Khakasiya Republic; GeoNames 1512236
        "geonames-2758401": .init(latitude: 51.58656, longitude: 4.77596), // NL/North Brabant; GeoNames 2758401
        "geonames-671768": .init(latitude: 47.0458, longitude: 21.91833), // RO/Bihor County; GeoNames 671768
        "geonames-2842647": .init(latitude: 49.23262, longitude: 7.00982), // DE/Saarland; GeoNames 2842647
        "geonames-2479536": .init(latitude: 36.87617, longitude: 6.90921), // DZ/Skikda; GeoNames 2479536
        "geonames-1215957": .init(latitude: 37.22417, longitude: 67.27833), // UZ/Surxondaryo Region; GeoNames 1215957
        "geonames-2421535": .init(latitude: 9.79111, longitude: -13.52333), // GN/Kindia; GeoNames 2421535
        "geonames-359280": .init(latitude: 30.45977, longitude: 31.1842), // EG/Qalyubia; GeoNames 359280
        "geonames-1308522": .init(latitude: 22.10856, longitude: 95.13583), // MM/Sagaing Region; GeoNames 1308522
        "geonames-3726540": .init(latitude: 19.26177, longitude: -72.51611), // HT/Artibonite; GeoNames 3726540
        "geonames-2122104": .init(latitude: 53.06393, longitude: 158.62751), // RU/Kamchatka; GeoNames 2122104
        "geonames-246013": .init(latitude: 31.9545, longitude: 35.81831), // JO/Amman; GeoNames 246013
        "geonames-3906194": .init(latitude: -17.39799, longitude: -66.03825), // BO/Cochabamba; GeoNames 3906194
        "geonames-3590979": .init(latitude: 14.84462, longitude: -91.52316), // GT/Quetzaltenango; GeoNames 3590979
        "geonames-670474": .init(latitude: 44.95, longitude: 26.01667), // RO/Prahova; GeoNames 670474
        "geonames-747712": .init(latitude: 41.67719, longitude: 26.55597), // TR/Edirne; GeoNames 747712
        "geonames-912764": .init(latitude: -10.21289, longitude: 31.18084), // ZM/Northern Province; GeoNames 912764
        "geonames-2296606": .init(latitude: 6.20228, longitude: -1.66796), // GH/Ashanti; GeoNames 2296606
        "geonames-1513886": .init(latitude: 40.13351, longitude: 67.82956), // UZ/Jizzakh Region; GeoNames 1513886
        "geonames-2476897": .init(latitude: 35.37103, longitude: 1.31699), // DZ/Tiaret; GeoNames 2476897
        "geonames-3848950": .init(latitude: -29.41328, longitude: -66.85637), // AR/La Rioja; GeoNames 3848950
        "geonames-2271772": .init(latitude: 38.75382, longitude: -9.23083), // PT/Lisbon; GeoNames 2271772
        "geonames-1055429": .init(latitude: -23.35, longitude: 43.66667), // MG/Atsimo-Andrefana; GeoNames 1055429
        "geonames-2498611": .init(latitude: 36.16525, longitude: 1.33452), // DZ/Chlef; GeoNames 2498611
        "geonames-1295765": .init(latitude: 20.14624, longitude: 92.89835), // MM/Rakhine; GeoNames 1295765
        "geonames-145757": .init(latitude: -7.36643, longitude: 20.81557), // AO/Luanda Norte; GeoNames 145757
        "geonames-2661604": .init(latitude: 47.55839, longitude: 7.57327), // CH/Basel-City; GeoNames 2661604
        "geonames-233346": .init(latitude: 2.77457, longitude: 32.29899), // UG/Northern Region; GeoNames 233346
        "geonames-2666199": .init(latitude: 59.85882, longitude: 17.63889), // SE/Uppsala; GeoNames 2666199
        "geonames-295432": .init(latitude: 31.73072, longitude: 34.99293), // IL/Jerusalem; GeoNames 295432
        "geonames-3583334": .init(latitude: 13.98827, longitude: -89.55685), // SV/Santa Ana Department; GeoNames 3583334
        "geonames-290332": .init(latitude: 26.25722, longitude: 50.61194), // BH/Muharraq; GeoNames 290332
        "geonames-352733": .init(latitude: 31.3529, longitude: 27.23725), // EG/Matruh; GeoNames 352733
        "geonames-2505329": .init(latitude: 36.75587, longitude: 5.08433), // DZ/Béjaïa; GeoNames 2505329
        "geonames-3658501": .init(latitude: -1.86032, longitude: -79.97683), // EC/Guayas; GeoNames 3658501
        "geonames-3109718": .init(latitude: 43.46589, longitude: -3.80493), // ES/Cantabria; GeoNames 3109718
        "geonames-2475687": .init(latitude: 34.87833, longitude: -1.315), // DZ/Tlemcen; GeoNames 2475687
        "geonames-281124": .init(latitude: 31.34018, longitude: 34.30627), // PS/Gaza Strip; GeoNames 281124
        "geonames-2310046": .init(latitude: 1.86391, longitude: 9.76582), // GQ/Litoral; GeoNames 2310046
        "geonames-3666608": .init(latitude: 5.54481, longitude: -73.35756), // CO/Boyacá; GeoNames 3666608
        "geonames-3906791": .init(latitude: -17.39228, longitude: -66.27838), // BO/Cochabamba; GeoNames 3906791
        "geonames-202905": .init(latitude: -1.70278, longitude: 29.25639), // RW/Western Province; GeoNames 202905
        "geonames-598098": .init(latitude: 55.7068, longitude: 21.13912), // LT/Klaipėda County; GeoNames 598098
        "geonames-293788": .init(latitude: 32.08227, longitude: 34.81065), // IL/Tel Aviv; GeoNames 293788
        "geonames-786712": .init(latitude: 42.21389, longitude: 20.73972), // XK/Prizren; GeoNames 786712
        "geonames-907770": .init(latitude: -11.19976, longitude: 28.89431), // ZM/Luapula Province; GeoNames 907770
        "geonames-1518262": .init(latitude: 50.05197, longitude: 72.95497), // KZ/Karaganda; GeoNames 1518262
        "geonames-4563243": .init(latitude: 18.38078, longitude: -65.95739), // PR/Carolina; GeoNames 4563243
        "geonames-630429": .init(latitude: 53.13255, longitude: 26.00775), // BY/Brest; GeoNames 630429
        "geonames-3837056": .init(latitude: -33.2914, longitude: -66.32467), // AR/San Luis; GeoNames 3837056
        "geonames-2485801": .init(latitude: 31.94932, longitude: 5.32502), // DZ/Ouargla; GeoNames 2485801
        "geonames-763166": .init(latitude: 53.78376, longitude: 20.49272), // PL/Warmia-Masuria; GeoNames 763166
        "geonames-905395": .init(latitude: -12.54982, longitude: 28.24071), // ZM/Copperbelt; GeoNames 905395
        "geonames-1242833": .init(latitude: 9.66845, longitude: 80.00742), // LK/Northern Province; GeoNames 1242833
        "geonames-686254": .init(latitude: 46.18333, longitude: 21.31667), // RO/Arad County; GeoNames 686254
        "geonames-281129": .init(latitude: 31.5272, longitude: 34.48347), // PS/Gaza Strip; GeoNames 281129
        "geonames-3665688": .init(latitude: 5.33573, longitude: -72.3939), // CO/Casanare Department; GeoNames 3665688
        "geonames-3682426": .init(latitude: 1.61549, longitude: -75.60412), // CO/Caquetá; GeoNames 3682426
        "geonames-1234633": .init(latitude: 6.773, longitude: 79.8816), // LK/Western Province; GeoNames 1234633
        "geonames-255683": .init(latitude: 38.2462, longitude: 21.73508), // GR/West Greece; GeoNames 255683
        "geonames-1582436": .init(latitude: 11.53495, longitude: 106.88324), // VN/Dong Nai; GeoNames 1582436
        "geonames-2348773": .init(latitude: 6.21269, longitude: 7.07199), // NG/Anambra; GeoNames 2348773
        "geonames-1680932": .init(latitude: 17.61577, longitude: 121.72285), // PH/Cagayan Valley; GeoNames 1680932
        "geonames-1218667": .init(latitude: 37.59378, longitude: 61.83031), // TM/Mary; GeoNames 1218667
        "geonames-1818379": .init(latitude: 22.28142, longitude: 114.17258), // HK/Wan Chai; GeoNames 1818379
        "geonames-2694762": .init(latitude: 58.41086, longitude: 15.62157), // SE/Östergötland; GeoNames 2694762
        "geonames-6941099": .init(latitude: 28.05, longitude: 81.61667), // NP/Lumbini Province; GeoNames 6941099
        "geonames-139817": .init(latitude: 28.96887, longitude: 50.83657), // IR/Bushehr; GeoNames 139817
        "geonames-2505530": .init(latitude: 31.61667, longitude: -2.21667), // DZ/Béchar; GeoNames 2505530
        "geonames-1567148": .init(latitude: 15.57364, longitude: 108.47403), // VN/Da Nang City; GeoNames 1567148
        "geonames-3186573": .init(latitude: 44.20169, longitude: 17.90397), // BA/Federation of B&H; GeoNames 3186573
        "geonames-1582926": .init(latitude: 16.81625, longitude: 107.10031), // VN/Quang Tri; GeoNames 1582926
        "geonames-285629": .init(latitude: 29.33278, longitude: 48.02861), // KW/Hawalli; GeoNames 285629
        "geonames-152451": .init(latitude: -1.5, longitude: 33.8), // TZ/Mara; GeoNames 152451
        "geonames-2396518": .init(latitude: -0.71933, longitude: 8.78151), // GA/Ogooué-Maritime; GeoNames 2396518
        "geonames-255274": .init(latitude: 37.94203, longitude: 23.64619), // GR/Attica; GeoNames 255274
        "geonames-268064": .init(latitude: 33.55751, longitude: 35.37148), // LB/South Governorate; GeoNames 268064
        "geonames-287830": .init(latitude: 23.22573, longitude: 56.51572), // OM/Ad Dhahirah; GeoNames 287830
        "geonames-197745": .init(latitude: -0.45275, longitude: 39.64601), // KE/Garissa County; GeoNames 197745
        "geonames-379303": .init(latitude: 13.45262, longitude: 22.44725), // SD/Western Darfur; GeoNames 379303
        "geonames-2487134": .init(latitude: 35.93115, longitude: 0.08918), // DZ/Mostaganem; GeoNames 2487134
        "geonames-2755003": .init(latitude: 52.38084, longitude: 4.63683), // NL/North Holland; GeoNames 2755003
        "geonames-2759661": .init(latitude: 51.98, longitude: 5.91111), // NL/Gelderland; GeoNames 2759661
        "geonames-2223763": .init(latitude: 4.9547, longitude: 9.9404), // CM/Littoral; GeoNames 2223763
        "geonames-191220": .init(latitude: 1.01572, longitude: 35.00622), // KE/Trans Nzoia; GeoNames 191220
        "geonames-1135689": .init(latitude: 36.72895, longitude: 68.857), // AF/Kunduz; GeoNames 1135689
        "geonames-2239076": .init(latitude: -9.29782, longitude: 14.91162), // AO/Cuanza Norte; GeoNames 2239076
        "geonames-2419533": .init(latitude: 10.05692, longitude: -12.86576), // GN/Kindia; GeoNames 2419533
        "geonames-2208032": .init(latitude: -37.68611, longitude: 176.16667), // NZ/Bay of Plenty; GeoNames 2208032
        "geonames-3628053": .init(latitude: 9.91246, longitude: -67.35398), // VE/Guárico; GeoNames 3628053
        "geonames-2747351": .init(latitude: 51.69917, longitude: 5.30417), // NL/North Brabant; GeoNames 2747351
        "geonames-715429": .init(latitude: 46.253, longitude: 20.14824), // HU/Csongrád; GeoNames 715429
        "geonames-370737": .init(latitude: 9.53342, longitude: 31.66049), // SS/Upper Nile; GeoNames 370737
        "geonames-2803201": .init(latitude: 50.83619, longitude: 4.31454), // BE/Brussels Capital; GeoNames 2803201
        "geonames-285066": .init(latitude: 31.52935, longitude: 35.0938), // PS/West Bank; GeoNames 285066
        "geonames-3584399": .init(latitude: 13.72397, longitude: -89.188), // SV/San Salvador Department; GeoNames 3584399
        "geonames-2358946": .init(latitude: 12.25188, longitude: -2.36694), // BF/Centre-Ouest; GeoNames 2358946
        "geonames-1293960": .init(latitude: 20.78919, longitude: 97.03776), // MM/Shan State; GeoNames 1293960
        "geonames-76184": .init(latitude: 14.54274, longitude: 44.40514), // YE/Dhamār; GeoNames 76184
        "geonames-3021372": .init(latitude: 47.31344, longitude: 5.01391), // FR/Bourgogne-Franche-Comté; GeoNames 3021372
        "geonames-3595237": .init(latitude: 14.63542, longitude: -89.99112), // GT/Jalapa; GeoNames 3595237
        "geonames-2439376": .init(latitude: 14.8888, longitude: 5.2692), // NE/Tahoua Region; GeoNames 2439376
        "geonames-3903320": .init(latitude: -21.53549, longitude: -64.72956), // BO/Tarija Department; GeoNames 3903320
        "geonames-3837702": .init(latitude: -28.46957, longitude: -65.78524), // AR/Catamarca; GeoNames 3837702
        "geonames-2503701": .init(latitude: 36.07389, longitude: 4.76139), // DZ/Bordj Bou Arréridj; GeoNames 2503701
        "geonames-890422": .init(latitude: -19.45, longitude: 29.81667), // ZW/Midlands Province; GeoNames 890422
        "geonames-2252309": .init(latitude: 14.64792, longitude: -16.24363), // SN/Diourbel Region; GeoNames 2252309
        "geonames-335035": .init(latitude: 9.31387, longitude: 42.11815), // ET/Harari; GeoNames 335035
        "geonames-617239": .init(latitude: 46.84275, longitude: 29.6284), // MD/Transnistria; GeoNames 617239
        "geonames-3595803": .init(latitude: 14.30097, longitude: -90.78816), // GT/Escuintla; GeoNames 3595803
        "geonames-1152473": .init(latitude: 18.29232, longitude: 99.49277), // TH/Lampang; GeoNames 1152473
        "geonames-2686657": .init(latitude: 59.27412, longitude: 15.2066), // SE/Örebro; GeoNames 2686657
        "geonames-2309527": .init(latitude: 3.75578, longitude: 8.78166), // GQ/Bioko Norte; GeoNames 2309527
        "geonames-250336": .init(latitude: 32.55873, longitude: 36.00816), // JO/Irbid; GeoNames 250336
        "geonames-783920": .init(latitude: 44.8458, longitude: 20.40116), // RS/Central Serbia; GeoNames 783920
        "geonames-3587923": .init(latitude: 14.48285, longitude: -90.53425), // GT/Guatemala; GeoNames 3587923
        "geonames-6254843": .init(latitude: 28.59669, longitude: 81.61658), // NP/Karnali Pradesh; GeoNames 6254843
        "geonames-683902": .init(latitude: 45.27152, longitude: 27.97429), // RO/Brăila County; GeoNames 683902
        "geonames-717582": .init(latitude: 48.10327, longitude: 20.77806), // HU/Borsod-Abaúj-Zemplén; GeoNames 717582
        "geonames-3884373": .init(latitude: -29.90591, longitude: -71.25014), // CL/Coquimbo Region; GeoNames 3884373
        "geonames-1024552": .init(latitude: -25.05194, longitude: 33.64417), // MZ/Gaza Province; GeoNames 1024552
        "geonames-3511540": .init(latitude: 18.41713, longitude: -70.10682), // DO/San Cristóbal; GeoNames 3511540
        "geonames-146384": .init(latitude: 34.68406, longitude: 33.03794), // CY/Limassol; GeoNames 146384
        "geonames-2479215": .init(latitude: 36.28639, longitude: 7.95111), // DZ/Souk Ahras; GeoNames 2479215
        "geonames-201521": .init(latitude: -1.49984, longitude: 29.63497), // RW/Northern Province; GeoNames 201521
        "geonames-1846986": .init(latitude: 36.56798, longitude: 128.72972), // KR/Gyeongsangbuk-do; GeoNames 1846986
        "geonames-98530": .init(latitude: 31.33198, longitude: 45.2944), // IQ/Muthanna; GeoNames 98530
        "geonames-97990": .init(latitude: 33.75403, longitude: 44.60518), // IQ/Diyala; GeoNames 97990
        "geonames-2299522": .init(latitude: 6.09408, longitude: -0.25913), // GH/Eastern; GeoNames 2299522
        "geonames-3118150": .init(latitude: 42.46615, longitude: -2.45115), // ES/La Rioja; GeoNames 3118150
        "geonames-1522203": .init(latitude: 53.28414, longitude: 69.39364), // KZ/Aqmola; GeoNames 1522203
        "geonames-3895088": .init(latitude: -36.60664, longitude: -72.10344), // CL/Ñuble; GeoNames 3895088
        "geonames-2448085": .init(latitude: 16.97333, longitude: 7.99111), // NE/Agadez; GeoNames 2448085
        "geonames-2212775": .init(latitude: 27.03766, longitude: 14.42832), // LY/Sabha District; GeoNames 2212775
        "geonames-2525473": .init(latitude: 39.23054, longitude: 9.11917), // IT/Sardinia; GeoNames 2525473
        "geonames-2244991": .init(latitude: 13.77073, longitude: -13.66734), // SN/Tambacounda; GeoNames 2244991
        "geonames-655194": .init(latitude: 62.24147, longitude: 25.72088), // FI/Central Finland; GeoNames 655194
        "geonames-108512": .init(latitude: 30.97531, longitude: 41.03808), // SA/Northern Borders Region; GeoNames 108512
        "geonames-2415703": .init(latitude: 11.42282, longitude: -9.16852), // GN/Kankan Region; GeoNames 2415703
        "geonames-2239520": .init(latitude: -6.26667, longitude: 14.23833), // AO/Zaire; GeoNames 2239520
        "geonames-192710": .init(latitude: -1.17139, longitude: 36.83556), // KE/Kiambu County; GeoNames 192710
        "geonames-789128": .init(latitude: 44.01667, longitude: 20.91667), // RS/Central Serbia; GeoNames 789128
        "geonames-258576": .init(latitude: 39.62847, longitude: 22.42112), // GR/Thessaly; GeoNames 258576
        "geonames-3547398": .init(latitude: 23.04388, longitude: -81.58284), // CU/Matanzas Province; GeoNames 3547398
        "geonames-2377457": .init(latitude: 20.94188, longitude: -17.03842), // MR/Dakhlet Nouadhibou; GeoNames 2377457
        "geonames-3595069": .init(latitude: 14.28491, longitude: -89.88798), // GT/Jutiapa; GeoNames 3595069
        "geonames-2488835": .init(latitude: 36.26417, longitude: 2.75393), // DZ/Medea; GeoNames 2488835
        "geonames-3046526": .init(latitude: 46.07617, longitude: 18.22814), // HU/Baranya; GeoNames 3046526
        "geonames-3488465": .init(latitude: 17.99107, longitude: -76.95742), // JM/Saint Catherine Parish; GeoNames 3488465
        "geonames-1512473": .init(latitude: 41.55177, longitude: 60.63143), // UZ/Xorazm Region; GeoNames 1512473
        "geonames-160961": .init(latitude: -1.33167, longitude: 31.81222), // TZ/Kagera; GeoNames 160961
        "geonames-3618030": .init(latitude: 12.43527, longitude: -86.87862), // NI/León Department; GeoNames 3618030
        "geonames-1513131": .init(latitude: 40.08444, longitude: 65.37917), // UZ/Navoiy Region; GeoNames 1513131
        "geonames-2475475": .init(latitude: 33.11083, longitude: 6.07), // DZ/Touggourt; GeoNames 2475475
        "geonames-2624886": .init(latitude: 57.048, longitude: 9.9187), // DK/North Denmark; GeoNames 2624886
        "geonames-2496049": .init(latitude: 32.49094, longitude: 3.67347), // DZ/Ghardaia; GeoNames 2496049
        "geonames-2482572": .init(latitude: 34.83033, longitude: 0.15171), // DZ/Saida; GeoNames 2482572
        "geonames-3188582": .init(latitude: 44.53842, longitude: 18.66709), // BA/Federation of B&H; GeoNames 3188582
        "geonames-3600026": .init(latitude: 15.82562, longitude: -87.92968), // HN/Cortés Department; GeoNames 3600026
        "geonames-990930": .init(latitude: -28.73226, longitude: 24.76232), // ZA/Northern Cape; GeoNames 990930
        "geonames-3564178": .init(latitude: 21.8422, longitude: -78.76034), // CU/Ciego de Ávila Province; GeoNames 3564178
        "geonames-2291136": .init(latitude: 8.0402, longitude: -2.80003), // CI/Zanzan District; GeoNames 2291136
        "geonames-81302": .init(latitude: 32.08963, longitude: 23.95385), // LY/Al Butnan; GeoNames 81302
        "geonames-670609": .init(latitude: 44.85, longitude: 24.86667), // RO/Arges; GeoNames 670609
        "geonames-3907584": .init(latitude: -19.58361, longitude: -65.75306), // BO/Potosí Department; GeoNames 3907584
        "geonames-1141269": .init(latitude: 33.55391, longitude: 68.42096), // AF/Ghazni; GeoNames 1141269
        "geonames-2740637": .init(latitude: 40.20686, longitude: -8.41996), // PT/Coimbra; GeoNames 2740637
        "geonames-877747": .init(latitude: -10.26667, longitude: 40.18333), // TZ/Mtwara; GeoNames 877747
        "geonames-2233410": .init(latitude: 4.15342, longitude: 9.24231), // CM/South-West; GeoNames 2233410
        "geonames-3947019": .init(latitude: -13.1638, longitude: -74.22345), // PE/Ayacucho; GeoNames 3947019
        "geonames-245785": .init(latitude: 13.82916, longitude: 20.8324), // TD/Ouadaï; GeoNames 245785
        "geonames-255524": .init(latitude: 38.01539, longitude: 23.69187), // GR/Attica; GeoNames 255524
        "geonames-150006": .init(latitude: -3.66393, longitude: 33.42118), // TZ/Shinyanga; GeoNames 150006
        "geonames-2675408": .init(latitude: 59.42804, longitude: 17.95093), // SE/Stockholm; GeoNames 2675408
        "geonames-412800": .init(latitude: 29.25722, longitude: 48.05722), // KW/Mubārak al Kabīr; GeoNames 412800
        "geonames-3613533": .init(latitude: 15.61444, longitude: -87.95302), // HN/Cortés Department; GeoNames 3613533
        "geonames-2473449": .init(latitude: 35.6781, longitude: 10.09633), // TN/Kairouan; GeoNames 2473449
        "geonames-2425791": .init(latitude: 9.14555, longitude: 18.38331), // TD/Moyen-Chari; GeoNames 2425791
        "geonames-2295458": .init(latitude: 4.92678, longitude: -1.75773), // GH/Western; GeoNames 2295458
        "geonames-2472706": .init(latitude: 37.27442, longitude: 9.87391), // TN/Bizerte Governorate; GeoNames 2472706
        "geonames-2234359": .init(latitude: 4.57728, longitude: 13.68459), // CM/East; GeoNames 2234359
        "geonames-3723779": .init(latitude: 18.23569, longitude: -72.53686), // HT/Sud-Est; GeoNames 3723779
        "geonames-4566880": .init(latitude: 18.01031, longitude: -66.62398), // PR/Ponce; GeoNames 4566880
        "geonames-1019330": .init(latitude: -32.84721, longitude: 27.44218), // ZA/Eastern Cape; GeoNames 1019330
        "geonames-1069129": .init(latitude: -12.31732, longitude: 49.29188), // MG/Diana; GeoNames 1069129
        "geonames-1293625": .init(latitude: 14.0823, longitude: 98.19151), // MM/Tanintharyi Region; GeoNames 1293625
        "geonames-685948": .init(latitude: 46.56718, longitude: 26.91384), // RO/Bacău County; GeoNames 685948
        "geonames-2356157": .init(latitude: 12.37136, longitude: -1.41468), // BF/Centre; GeoNames 2356157
        "geonames-368277": .init(latitude: 13.18087, longitude: 32.73999), // SD/White Nile; GeoNames 368277
        "geonames-267008": .init(latitude: 33.27333, longitude: 35.19389), // LB/South Governorate; GeoNames 267008
        "geonames-613607": .init(latitude: 42.26791, longitude: 42.69459), // GE/Imereti; GeoNames 613607
        "geonames-3728474": .init(latitude: 19.75938, longitude: -72.19815), // HT/Nord; GeoNames 3728474
        "geonames-2491191": .init(latitude: 33.8, longitude: 2.86514), // DZ/Laghouat; GeoNames 2491191
        "geonames-667268": .init(latitude: 45.8, longitude: 24.15), // RO/Sibiu County; GeoNames 667268
        "geonames-630376": .init(latitude: 54.2279, longitude: 28.505), // BY/Minsk; GeoNames 630376
        "geonames-290247": .init(latitude: 26.11528, longitude: 50.50694), // BH/Northern; GeoNames 290247
        "geonames-3868707": .init(latitude: -39.81422, longitude: -73.24589), // CL/Los Ríos Region; GeoNames 3868707
        "geonames-2457163": .init(latitude: 16.27167, longitude: -0.04472), // ML/Gao; GeoNames 2457163
        "geonames-2486690": .init(latitude: 35.70889, longitude: 4.53722), // DZ/M'Sila; GeoNames 2486690
        "geonames-2400555": .init(latitude: -1.63333, longitude: 13.58357), // GA/Haut-Ogooué; GeoNames 2400555
        "geonames-1150515": .init(latitude: 9.14011, longitude: 99.33311), // TH/Surat Thani; GeoNames 1150515
        "geonames-89113": .init(latitude: 30.75545, longitude: 20.22625), // LY/Al Wahat; GeoNames 89113
        "geonames-2293549": .init(latitude: 6.72972, longitude: -3.49639), // CI/Comoé District; GeoNames 2293549
        "geonames-2300379": .init(latitude: 6.60084, longitude: 0.4713), // GH/Volta; GeoNames 2300379
        "geonames-1605239": .init(latitude: 17.41567, longitude: 102.78589), // TH/Udon Thani; GeoNames 1605239
        "geonames-282615": .init(latitude: 32.22111, longitude: 35.25444), // PS/West Bank; GeoNames 282615
        "geonames-13452524": .init(latitude: -31.58189, longitude: -68.54211), // AR/San Juan; GeoNames 13452524
        "geonames-2455558": .init(latitude: 12.74139, longitude: -8.06754), // ML/Koulikoro; GeoNames 2455558
        "geonames-602150": .init(latitude: 63.82842, longitude: 20.25972), // SE/Västerbotten; GeoNames 602150
        "geonames-3617723": .init(latitude: 11.97316, longitude: -86.09587), // NI/Masaya Department; GeoNames 3617723
        "geonames-280425": .init(latitude: 33.80528, longitude: 35.6), // LB/Mount Lebanon; GeoNames 280425
        "geonames-2743477": .init(latitude: 52.5125, longitude: 6.09444), // NL/Overijssel; GeoNames 2743477
        "geonames-64536": .init(latitude: 3.11383, longitude: 43.6498), // SO/Bay; GeoNames 64536
        "geonames-89055": .init(latitude: 32.76272, longitude: 21.75506), // LY/Al Jabal al Akhdar; GeoNames 89055
        "geonames-3052009": .init(latitude: 47.68333, longitude: 17.63512), // HU/Győr-Moson-Sopron; GeoNames 3052009
        "geonames-3893656": .init(latitude: -27.36737, longitude: -70.33219), // CL/Atacama; GeoNames 3893656
        "geonames-2548526": .init(latitude: 28.98696, longitude: -10.05738), // MA/Guelmim-Oued Noun; GeoNames 2548526
        "geonames-2387495": .init(latitude: 4.94273, longitude: 15.87735), // CF/Mambéré; GeoNames 2387495
        "geonames-169389": .init(latitude: 35.93062, longitude: 36.63393), // SY/Idlib; GeoNames 169389
        "geonames-2267095": .init(latitude: 39.74362, longitude: -8.80705), // PT/Leiria; GeoNames 2267095
        "geonames-3931276": .init(latitude: -15.84003, longitude: -70.02198), // PE/Puno; GeoNames 3931276
        "geonames-102527": .init(latitude: 29.96974, longitude: 40.20641), // SA/Al Jawf Region; GeoNames 102527
        "geonames-612287": .init(latitude: 41.56271, longitude: 44.9787), // GE/Kvemo Kartli; GeoNames 612287
        "geonames-2407656": .init(latitude: 8.64387, longitude: -10.9714), // SL/Eastern Province; GeoNames 2407656
        "geonames-2664454": .init(latitude: 59.61617, longitude: 16.55276), // SE/Västmanland; GeoNames 2664454
        "geonames-3090048": .init(latitude: 50.67119, longitude: 17.92604), // PL/Opole Voivodeship; GeoNames 3090048
        "geonames-584649": .init(latitude: 40.61832, longitude: 47.15014), // AZ/Yevlax City; GeoNames 584649
        "geonames-363885": .init(latitude: 7.70111, longitude: 27.98972), // SS/Western Bahr al Ghazal; GeoNames 363885
        "geonames-3540667": .init(latitude: 21.93429, longitude: -79.4398), // CU/Sancti Spíritus Province; GeoNames 3540667
        "geonames-1608529": .init(latitude: 14.97066, longitude: 102.10196), // TH/Nakhon Ratchasima; GeoNames 1608529
        "geonames-3620381": .init(latitude: 12.62951, longitude: -87.13133), // NI/Chinandega Department; GeoNames 3620381
        "geonames-281102": .init(latitude: 31.29722, longitude: 34.24357), // PS/Gaza Strip; GeoNames 281102
        "geonames-3629710": .init(latitude: 5.66049, longitude: -67.58343), // VE/Amazonas; GeoNames 3629710
        "geonames-3728097": .init(latitude: 18.19199, longitude: -73.74948), // HT/Sud; GeoNames 3728097
        "geonames-1653316": .init(latitude: 16.5703, longitude: 104.7622), // LA/Savannakhet Province; GeoNames 1653316
        "geonames-250799": .init(latitude: 32.33326, longitude: 35.75279), // JO/Ajloun; GeoNames 250799
        "geonames-650224": .init(latitude: 62.89238, longitude: 27.67703), // FI/North Savo; GeoNames 650224
        "geonames-618605": .init(latitude: 47.76291, longitude: 27.92854), // MD/Bălţi; GeoNames 618605
        "geonames-3493146": .init(latitude: 19.29377, longitude: -70.25285), // DO/Duarte Province; GeoNames 3493146
        "geonames-3584257": .init(latitude: 13.67741, longitude: -89.28335), // SV/La Libertad Department; GeoNames 3584257
        "geonames-2357043": .init(latitude: 13.5769, longitude: -2.41786), // BF/Nord; GeoNames 2357043
        "geonames-2751792": .init(latitude: 53.20271, longitude: 5.80973), // NL/Friesland; GeoNames 2751792
        "geonames-3493240": .init(latitude: 18.61501, longitude: -68.70798), // DO/La Altagracia Province; GeoNames 3493240
        "geonames-1528249": .init(latitude: 40.94498, longitude: 72.99313), // KG/Jalal-Abad Region; GeoNames 1528249
        "geonames-1605245": .init(latitude: 15.23844, longitude: 104.84866), // TH/Ubon Ratchathani; GeoNames 1605245
        "geonames-2751283": .init(latitude: 50.84833, longitude: 5.68889), // NL/Limburg; GeoNames 2751283
        "geonames-2359608": .init(latitude: 13.0883, longitude: -1.08368), // BF/Centre-Nord; GeoNames 2359608
        "geonames-649360": .init(latitude: 60.98267, longitude: 25.66151), // FI/Paijat-Hame; GeoNames 649360
        "geonames-726848": .init(latitude: 42.43205, longitude: 25.64262), // BG/Stara Zagora; GeoNames 726848
        "geonames-727523": .init(latitude: 43.84872, longitude: 25.9534), // BG/Ruse; GeoNames 727523
        "geonames-2258261": .init(latitude: -4.19834, longitude: 12.66664), // CG/Niari; GeoNames 2258261
        "geonames-3165243": .init(latitude: 46.06787, longitude: 11.12108), // IT/Trentino-Alto Adige; GeoNames 3165243
        "geonames-3171180": .init(latitude: 43.1122, longitude: 12.38878), // IT/Umbria; GeoNames 3171180
        "geonames-278913": .init(latitude: 33.37889, longitude: 35.48389), // LB/Nabatieh; GeoNames 278913
        "geonames-1831797": .init(latitude: 13.10271, longitude: 103.19822), // KH/Battambang; GeoNames 1831797
        "geonames-292878": .init(latitude: 25.11641, longitude: 56.34141), // AE/Fujairah; GeoNames 292878
        "geonames-3696378": .init(latitude: -9.52614, longitude: -77.52869), // PE/Ancash; GeoNames 3696378
        "geonames-923295": .init(latitude: -15.38596, longitude: 35.3188), // MW/Southern Region; GeoNames 923295
        "geonames-3080165": .init(latitude: 51.93548, longitude: 15.50643), // PL/Lubusz; GeoNames 3080165
        "geonames-2262963": .init(latitude: 38.5244, longitude: -8.8882), // PT/Setúbal; GeoNames 2262963
        "geonames-2395915": .init(latitude: 7.18286, longitude: 1.99119), // BJ/Zou; GeoNames 2395915
        "geonames-2364104": .init(latitude: 8.98333, longitude: 1.13333), // TG/Centrale; GeoNames 2364104
        "geonames-716935": .init(latitude: 47.95539, longitude: 21.71671), // HU/Szabolcs-Szatmár-Bereg; GeoNames 716935
        "geonames-2362909": .init(latitude: 10.64064, longitude: -4.75285), // BF/Cascades Region; GeoNames 2362909
        "geonames-3149318": .init(latitude: 58.14671, longitude: 7.9956), // NO/Agder; GeoNames 3149318
        "geonames-792078": .init(latitude: 43.89139, longitude: 20.34972), // RS/Central Serbia; GeoNames 792078
        "geonames-1518542": .init(latitude: 45.01556, longitude: 78.37389), // KZ/Zhetysu Region; GeoNames 1518542
        "geonames-2989317": .init(latitude: 47.90248, longitude: 1.90407), // FR/Centre-Val de Loire; GeoNames 2989317
        "geonames-2982652": .init(latitude: 49.44313, longitude: 1.09932), // FR/Normandy; GeoNames 2982652
        "geonames-385038": .init(latitude: 26.13, longitude: 50.555), // BH/Southern Governorate; GeoNames 385038
        "geonames-933945": .init(latitude: -20.29806, longitude: 57.47833), // MU/Plaines Wilhems; GeoNames 933945
        "geonames-3183719": .init(latitude: 40.4696, longitude: 19.48379), // AL/Vlorë County; GeoNames 3183719
        "geonames-187896": .init(latitude: 3.93726, longitude: 41.85688), // KE/Mandera County; GeoNames 187896
        "geonames-616635": .init(latitude: 40.79305, longitude: 43.84635), // AM/Shirak; GeoNames 616635
        "geonames-2473247": .init(latitude: 36.86012, longitude: 10.19337), // TN/Ariana Governorate; GeoNames 2473247
        "geonames-1609776": .init(latitude: 16.44671, longitude: 102.833), // TH/Khon Kaen; GeoNames 1609776
        "geonames-3440714": .init(latitude: -31.38811, longitude: -57.95983), // UY/Salto Department; GeoNames 3440714
        "geonames-2249222": .init(latitude: 15.61867, longitude: -16.22436), // SN/Louga; GeoNames 2249222
        "geonames-2702979": .init(latitude: 57.78145, longitude: 14.15618), // SE/Jönköping; GeoNames 2702979
        "geonames-667873": .init(latitude: 47.79926, longitude: 22.86255), // RO/Satu Mare County; GeoNames 667873
        "geonames-191299": .init(latitude: -0.68174, longitude: 34.76666), // KE/Kisii County; GeoNames 191299
        "geonames-1821263": .init(latitude: 22.15583, longitude: 113.55694), // MO/Our Lady of Carmo; GeoNames 1821263
        "geonames-3598465": .init(latitude: 14.8009, longitude: -89.54641), // GT/Chiquimula; GeoNames 3598465
        "geonames-906054": .init(latitude: -15.24835, longitude: 23.12741), // ZM/Western Province; GeoNames 906054
        "geonames-934765": .init(latitude: -20.23325, longitude: 57.46609), // MU/Plaines Wilhems; GeoNames 934765
        "geonames-2790471": .init(latitude: 50.4669, longitude: 4.86746), // BE/Wallonia; GeoNames 2790471
        "geonames-1220747": .init(latitude: 37.83654, longitude: 68.77762), // TJ/Khatlon Province; GeoNames 1220747
        "geonames-934995": .init(latitude: -26.49884, longitude: 31.38004), // SZ/Manzini Region; GeoNames 934995
        "geonames-6324733": .init(latitude: 47.56494, longitude: -52.70931), // CA/Newfoundland and Labrador; GeoNames 6324733
        "geonames-618577": .init(latitude: 46.83158, longitude: 29.47671), // MD/Bender Municipality; GeoNames 618577
        "geonames-2468369": .init(latitude: 33.88146, longitude: 10.0982), // TN/Gabès Governorate; GeoNames 2468369
        "geonames-3050434": .init(latitude: 46.90618, longitude: 19.69128), // HU/Bács-Kiskun; GeoNames 3050434
        "geonames-3617708": .init(latitude: 12.92795, longitude: -85.91906), // NI/Matagalpa Department; GeoNames 3617708
        "geonames-685826": .init(latitude: 47.65729, longitude: 23.56808), // RO/Maramureş; GeoNames 685826
        "geonames-1226260": .init(latitude: 8.5778, longitude: 81.2289), // LK/Eastern Province; GeoNames 1226260
        "geonames-286282": .init(latitude: 24.34745, longitude: 56.70937), // OM/Al Batinah North; GeoNames 286282
        "geonames-3191648": .init(latitude: 45.32673, longitude: 14.44241), // HR/Primorje-Gorski Kotar; GeoNames 3191648
        "geonames-250258": .init(latitude: 32.03917, longitude: 35.72722), // JO/Balqa; GeoNames 250258
        "geonames-789225": .init(latitude: 42.88333, longitude: 20.86667), // XK/Mitrovica; GeoNames 789225
        "geonames-2210554": .init(latitude: 31.20892, longitude: 16.58866), // LY/Surt; GeoNames 2210554
        "geonames-2447513": .init(latitude: 18.73694, longitude: 7.38528), // NE/Agadez; GeoNames 2447513
        "geonames-2463447": .init(latitude: 23.68477, longitude: -15.95798), // EH/no admin1 supplied; GeoNames 2463447
        "geonames-585514": .init(latitude: 40.76422, longitude: 47.06227), // AZ/Mingacevir City; GeoNames 585514
        "geonames-3159016": .init(latitude: 59.74389, longitude: 10.20449), // NO/Buskerud; GeoNames 3159016
        "geonames-6354908": .init(latitude: 46.1351, longitude: -60.1831), // CA/Nova Scotia; GeoNames 6354908
        "geonames-935221": .init(latitude: -21.00961, longitude: 55.27134), // RE/Reunion; GeoNames 935221
        "geonames-3194828": .init(latitude: 43.34333, longitude: 17.80806), // BA/Federation of B&H; GeoNames 3194828
        "geonames-1516589": .init(latitude: 47.79411, longitude: 67.70628), // KZ/Ulytau Region; GeoNames 1516589
        "geonames-2366152": .init(latitude: 9.55111, longitude: 1.18611), // TG/Kara; GeoNames 2366152
        "geonames-2596934": .init(latitude: 7.96111, longitude: -6.67306), // CI/Woroba; GeoNames 2596934
        "geonames-3588258": .init(latitude: 14.91188, longitude: -91.36054), // GT/Totonicapán; GeoNames 3588258
        "geonames-380173": .init(latitude: 17.59898, longitude: 33.97205), // SD/River Nile; GeoNames 380173
        "geonames-2389086": .init(latitude: 4.26116, longitude: 15.79216), // CF/Mambéré-Kadéï; GeoNames 2389086
        "geonames-1141857": .init(latitude: 33.59744, longitude: 69.22592), // AF/Paktia; GeoNames 1141857
        "geonames-2249782": .init(latitude: 12.8939, longitude: -14.94125), // SN/Kolda; GeoNames 2249782
        "geonames-2732265": .init(latitude: 40.66165, longitude: -7.90905), // PT/Viseu; GeoNames 2732265
        "geonames-933778": .init(latitude: -21.17, longitude: 27.50778), // BW/City of Francistown; GeoNames 933778
        "geonames-8521334": .init(latitude: -4.18396, longitude: 13.2859), // CG/Bouenza; GeoNames 8521334
        "geonames-3071961": .init(latitude: 50.76711, longitude: 15.05619), // CZ/Liberec Region; GeoNames 3071961
        "geonames-87205": .init(latitude: 32.76704, longitude: 22.63669), // LY/Darnah; GeoNames 87205
        "geonames-3509382": .init(latitude: 19.22031, longitude: -70.53101), // DO/La Vega; GeoNames 3509382
        "geonames-2962943": .init(latitude: 52.66472, longitude: -8.62306), // IE/Munster; GeoNames 2962943
        "geonames-3441894": .init(latitude: -34.89791, longitude: -54.95021), // UY/Maldonado; GeoNames 3441894
        "geonames-3044774": .init(latitude: 47.18995, longitude: 18.41034), // HU/Fejér; GeoNames 3044774
        "geonames-2232283": .init(latitude: 2.9, longitude: 11.15), // CM/South; GeoNames 2232283
        "geonames-783263": .init(latitude: 41.11138, longitude: 20.08224), // AL/Elbasan County; GeoNames 783263
        "geonames-3591062": .init(latitude: 15.72724, longitude: -88.59787), // GT/Izabal Department; GeoNames 3591062
        "geonames-2774326": .init(latitude: 46.62472, longitude: 14.30528), // AT/Carinthia; GeoNames 2774326
        "geonames-3069011": .init(latitude: 49.59552, longitude: 17.25175), // CZ/Olomouc Region; GeoNames 3069011
        "geonames-594739": .init(latitude: 55.93333, longitude: 23.31667), // LT/Siauliai; GeoNames 594739
        "geonames-63795": .init(latitude: 9.52213, longitude: 45.53363), // SO/Togdheer; GeoNames 63795
        "geonames-917748": .init(latitude: -16.80889, longitude: 26.9875), // ZM/Southern Province; GeoNames 917748
        "geonames-170905": .init(latitude: 32.61889, longitude: 36.10213), // SY/Daraa; GeoNames 170905
        "geonames-2031405": .init(latitude: 49.03333, longitude: 104.08333), // MN/Orhon; GeoNames 2031405
        "geonames-3723593": .init(latitude: 18.65, longitude: -74.11667), // HT/Grand'Anse; GeoNames 3723593
        "geonames-2413753": .init(latitude: 13.27136, longitude: -16.64944), // GM/Western; GeoNames 2413753
        "geonames-147429": .init(latitude: 39.20889, longitude: 45.41222), // AZ/Nakhchivan; GeoNames 147429
        "geonames-3598572": .init(latitude: 14.65881, longitude: -90.8216), // GT/Chimaltenango; GeoNames 3598572
        "geonames-1312609": .init(latitude: 20.14956, longitude: 94.93246), // MM/Magway; GeoNames 1312609
        "geonames-3619194": .init(latitude: 13.09291, longitude: -86.35589), // NI/Estelí Department; GeoNames 3619194
        "geonames-3195506": .init(latitude: 46.55583, longitude: 15.64593), // SI/Urban Municipality of Maribor; GeoNames 3195506
        "geonames-1136469": .init(latitude: 33.33951, longitude: 69.92041), // AF/Khowst; GeoNames 1136469
        "geonames-3838859": .init(latitude: -51.6253, longitude: -69.25229), // AR/Santa Cruz; GeoNames 3838859
        "geonames-3184081": .init(latitude: 42.06828, longitude: 19.51258), // AL/Shkodër County; GeoNames 3184081
        "geonames-1045114": .init(latitude: -23.865, longitude: 35.38333), // MZ/Inhambane Province; GeoNames 1045114
        "geonames-2468353": .init(latitude: 34.425, longitude: 8.78417), // TN/Gafsa; GeoNames 2468353
        "geonames-2394560": .init(latitude: 9.70853, longitude: 1.66598), // BJ/Donga; GeoNames 2394560
        "geonames-791646": .init(latitude: 42.38028, longitude: 20.43083), // XK/Gjakova; GeoNames 791646
        "geonames-3077916": .init(latitude: 48.97447, longitude: 14.47434), // CZ/South Bohemian Region; GeoNames 3077916
        "geonames-2473493": .init(latitude: 35.77799, longitude: 10.82617), // TN/Monastir Governorate; GeoNames 2473493
        "geonames-233114": .init(latitude: 0.43902, longitude: 33.20317), // UG/Eastern Region; GeoNames 233114
        "geonames-2295021": .init(latitude: 7.33991, longitude: -2.32676), // GH/Bono; GeoNames 2295021
        "geonames-2123628": .init(latitude: 59.56274, longitude: 150.80211), // RU/Magadan Oblast; GeoNames 2123628
        "geonames-8740209": .init(latitude: -18.07051, longitude: 178.51313), // FJ/Central; GeoNames 8740209
        "geonames-588335": .init(latitude: 58.38062, longitude: 26.72509), // EE/Tartu; GeoNames 588335
        "geonames-893697": .init(latitude: -17.36667, longitude: 30.2), // ZW/Mashonaland West; GeoNames 893697
        "geonames-1655199": .init(latitude: 17.41027, longitude: 104.83068), // LA/Khammouane Province; GeoNames 1655199
        "geonames-78428": .init(latitude: 15.6594, longitude: 43.94385), // YE/Omran; GeoNames 78428
        "geonames-3074967": .init(latitude: 50.20923, longitude: 15.83277), // CZ/Hradec Králové Region; GeoNames 3074967
        "geonames-2185018": .init(latitude: -40.35636, longitude: 175.61113), // NZ/Manawatu-Wanganui; GeoNames 2185018
        "geonames-3063548": .init(latitude: 50.6607, longitude: 14.03227), // CZ/Ústí nad Labem Region; GeoNames 3063548
        "geonames-886763": .init(latitude: -20.06373, longitude: 30.82766), // ZW/Masvingo Province; GeoNames 886763
        "geonames-728203": .init(latitude: 43.41791, longitude: 24.61666), // BG/Pleven; GeoNames 728203
        "geonames-3619136": .init(latitude: 11.93062, longitude: -85.95368), // NI/Granada Department; GeoNames 3619136
        "geonames-147622": .init(latitude: 38.75428, longitude: 48.85062), // AZ/Lənkəran; GeoNames 147622
        "geonames-1056899": .init(latitude: -14.26667, longitude: 50.16667), // MG/Sava; GeoNames 1056899
        "geonames-3068582": .init(latitude: 50.04075, longitude: 15.77659), // CZ/Pardubice Region; GeoNames 3068582
        "geonames-2472479": .init(latitude: 36.75452, longitude: 10.22167), // TN/Ben Arous Governorate; GeoNames 2472479
        "geonames-161616": .init(latitude: 39.51075, longitude: 54.36713), // TM/Balkan; GeoNames 161616
        "geonames-4562635": .init(latitude: 18.47245, longitude: -66.71573), // PR/Arecibo; GeoNames 4562635
        "geonames-202217": .init(latitude: -2.07444, longitude: 29.75667), // RW/Southern Province; GeoNames 202217
        "geonames-147611": .init(latitude: 38.77388, longitude: 48.41497), // AZ/Lerik District; GeoNames 147611
        "geonames-4563008": .init(latitude: 18.23412, longitude: -66.0485), // PR/Caguas; GeoNames 4563008
        "geonames-285815": .init(latitude: 29.2775, longitude: 47.95861), // KW/Al Farwaniyah; GeoNames 285815
        "geonames-3058531": .init(latitude: 48.30763, longitude: 18.08453), // SK/Nitra Region; GeoNames 3058531
        "geonames-6076211": .init(latitude: 46.09454, longitude: -64.7965), // CA/New Brunswick; GeoNames 6076211
        "geonames-2277060": .init(latitude: 6.99543, longitude: -9.47122), // LR/Bong County; GeoNames 2277060
        "geonames-2513947": .init(latitude: 35.29369, longitude: -2.93833), // ES/Melilla; GeoNames 2513947
        "geonames-596128": .init(latitude: 55.73186, longitude: 24.35983), // LT/Panevėžys; GeoNames 596128
        "geonames-2406407": .init(latitude: 8.88605, longitude: -12.04417), // SL/Northern Province; GeoNames 2406407
        "geonames-3440781": .init(latitude: -30.90534, longitude: -55.55076), // UY/Rivera Department; GeoNames 3440781
        "geonames-2473457": .init(latitude: 35.16758, longitude: 8.83651), // TN/Kasserine Governorate; GeoNames 2473457
        "geonames-3902377": .init(latitude: -14.83223, longitude: -64.90335), // BO/Beni Department; GeoNames 3902377
        "geonames-2449067": .init(latitude: 16.77348, longitude: -3.00742), // ML/Tombouctou; GeoNames 2449067
        "geonames-2031964": .init(latitude: 49.48667, longitude: 105.92278), // MN/Darhan Uul; GeoNames 2031964
        "geonames-727079": .init(latitude: 42.68607, longitude: 26.32558), // BG/Sliven; GeoNames 727079
        "geonames-240604": .init(latitude: 5.76795, longitude: 20.67565), // CF/Ouaka; GeoNames 240604
        "geonames-723819": .init(latitude: 48.99923, longitude: 21.2355), // SK/Prešov Region; GeoNames 723819
        "geonames-728330": .init(latitude: 42.59671, longitude: 23.03318), // BG/Pernik; GeoNames 728330
        "geonames-3441243": .init(latitude: -32.3171, longitude: -58.08072), // UY/Paysandú Department; GeoNames 3441243
        "geonames-4565119": .init(latitude: 18.35745, longitude: -66.111), // PR/Guaynabo; GeoNames 4565119
        "geonames-3056508": .init(latitude: 49.22315, longitude: 18.73941), // SK/Žilina Region; GeoNames 3056508
        "geonames-2367886": .init(latitude: 7.53333, longitude: 1.13333), // TG/Plateaux; GeoNames 2367886
        "geonames-2445488": .init(latitude: 13.049, longitude: 3.1937), // NE/Dosso Region; GeoNames 2445488
        "geonames-2417833": .init(latitude: 10.37546, longitude: -12.09148), // GN/Mamou Region; GeoNames 2417833
        "geonames-655808": .init(latitude: 62.60118, longitude: 29.76316), // FI/North Karelia; GeoNames 655808
        "geonames-266045": .init(latitude: 33.84675, longitude: 35.90203), // LB/Bekaa; GeoNames 266045
        "geonames-460413": .init(latitude: 55.88333, longitude: 26.53333), // LV/Daugavpils; GeoNames 460413
        "geonames-616530": .init(latitude: 40.8074, longitude: 44.49704), // AM/Lori; GeoNames 616530
        "geonames-371712": .init(latitude: 8.30278, longitude: 27.98), // SS/Warrap; GeoNames 371712
        "geonames-3712076": .init(latitude: 9.36025, longitude: -79.90019), // PA/Colón; GeoNames 3712076
        "geonames-1654379": .init(latitude: 15.12022, longitude: 105.79898), // LA/Champasak Province; GeoNames 1654379
        "geonames-604490": .init(latitude: 65.58415, longitude: 22.15465), // SE/Norrbotten; GeoNames 604490
        "geonames-2092740": .init(latitude: -6.72333, longitude: 146.99611), // PG/Morobe Province; GeoNames 2092740
        "geonames-3613528": .init(latitude: 13.30569, longitude: -87.17882), // HN/Choluteca Department; GeoNames 3613528
        "geonames-2278158": .init(latitude: 5.87693, longitude: -10.04964), // LR/Grand Bassa County; GeoNames 2278158
        "geonames-3193935": .init(latitude: 45.55066, longitude: 18.6942), // HR/County of Osijek-Baranja; GeoNames 3193935
        "geonames-1831167": .init(latitude: 12.25, longitude: 104.66667), // KH/Kampong Chhnang; GeoNames 1831167
        "geonames-3353383": .init(latitude: -17.91796, longitude: 19.77314), // NA/Kavango East; GeoNames 3353383
        "geonames-3437547": .init(latitude: -22.54925, longitude: -55.7387), // PY/Amambay Department; GeoNames 3437547
        "geonames-788886": .init(latitude: 42.13279, longitude: 21.71585), // MK/Kumanovo; GeoNames 788886
        "geonames-3438735": .init(latitude: -27.33176, longitude: -55.86662), // PY/Itapúa; GeoNames 3438735
        "geonames-933305": .init(latitude: -24.40659, longitude: 25.49508), // BW/Kweneng; GeoNames 933305
        "geonames-333287": .init(latitude: 15.77792, longitude: 38.45107), // ER/Anseba; GeoNames 333287
        "geonames-245338": .init(latitude: 11.0433, longitude: 20.28342), // TD/Salamat; GeoNames 245338
        "geonames-3061186": .init(latitude: 48.73947, longitude: 19.14932), // SK/Banská Bystrica Region; GeoNames 3061186
        "geonames-64013": .init(latitude: 11.28421, longitude: 49.18158), // SO/Bari; GeoNames 64013
        "geonames-786735": .init(latitude: 41.34558, longitude: 21.5537), // MK/Prilep; GeoNames 786735
        "geonames-4566385": .init(latitude: 18.20107, longitude: -67.13962), // PR/Mayagüez; GeoNames 4566385
        "geonames-1831142": .init(latitude: 10.60932, longitude: 103.52958), // KH/Preah Sihanouk; GeoNames 1831142
        "geonames-2396646": .init(latitude: 1.5995, longitude: 11.57933), // GA/Woleu-Ntem; GeoNames 2396646
        "geonames-286987": .init(latitude: 22.93333, longitude: 57.53333), // OM/Ad Dakhiliyah; GeoNames 286987
        "geonames-146400": .init(latitude: 34.9221, longitude: 33.62794), // CY/Larnaka; GeoNames 146400
        "geonames-2387926": .init(latitude: 5.93404, longitude: 15.59599), // CF/Nana-Mambéré; GeoNames 2387926
        "geonames-1055433": .init(latitude: -25.03249, longitude: 46.98329), // MG/Anosy; GeoNames 1055433
        "geonames-286245": .init(latitude: 22.56667, longitude: 59.52889), // OM/Southeastern Governorate; GeoNames 286245
        "geonames-2433437": .init(latitude: 8.66389, longitude: 16.85324), // TD/Logone Oriental; GeoNames 2433437
        "geonames-2426240": .init(latitude: 9.3646, longitude: 14.90725), // TD/Mayo-Kebbi Ouest; GeoNames 2426240
        "geonames-792578": .init(latitude: 41.03226, longitude: 21.33553), // MK/Bitola; GeoNames 792578
        "geonames-3374462": .init(latitude: 16.89014, longitude: -24.98042), // CV/São Vicente; GeoNames 3374462
        "geonames-3574810": .init(latitude: 10.51667, longitude: -61.41667), // TT/Chaguanas; GeoNames 3574810
        "geonames-457954": .init(latitude: 56.50474, longitude: 21.01085), // LV/Liepaja; GeoNames 457954
        "geonames-3186952": .init(latitude: 44.11578, longitude: 15.22514), // HR/Zadar; GeoNames 3186952
        "geonames-611847": .init(latitude: 43.00697, longitude: 40.9893), // GE/Abkhazia; GeoNames 611847
        "geonames-3582677": .init(latitude: 17.49952, longitude: -88.19756), // BZ/Belize District; GeoNames 3582677
        "geonames-785082": .init(latitude: 42.00989, longitude: 20.97138), // MK/Tetovo; GeoNames 785082
        "geonames-3622247": .init(latitude: 9.99074, longitude: -83.03596), // CR/Limón Province; GeoNames 3622247
        "geonames-2378538": .init(latitude: 16.62073, longitude: -11.40208), // MR/Assaba; GeoNames 2378538
        "geonames-430569": .init(latitude: -2.9075, longitude: 29.8306), // BI/Ngozi; GeoNames 430569
        "geonames-3707961": .init(latitude: 8.87763, longitude: -79.78007), // PA/Panamá Oeste Province; GeoNames 3707961
        "geonames-11496397": .init(latitude: 18.10808, longitude: -15.92666), // MR/Nouakchott North; GeoNames 11496397
        "geonames-2610613": .init(latitude: 55.70927, longitude: 9.5357), // DK/South Denmark; GeoNames 2610613
        "geonames-784759": .init(latitude: 42.37056, longitude: 21.15528), // XK/Ferizaj; GeoNames 784759
        "geonames-3194494": .init(latitude: 42.7731, longitude: 18.94446), // ME/Opština Nikšić; GeoNames 3194494
        "geonames-2378736": .init(latitude: 16.15071, longitude: -13.50582), // MR/Gorgol; GeoNames 2378736
        "geonames-933088": .init(latitude: -22.38754, longitude: 26.71077), // BW/Central; GeoNames 933088
        "geonames-423549": .init(latitude: -3.9736, longitude: 29.4386), // BI/Rumonge; GeoNames 423549
        "geonames-3573738": .init(latitude: 10.27969, longitude: -61.46835), // TT/San Fernando; GeoNames 3573738
        "geonames-459279": .init(latitude: 56.65, longitude: 23.71278), // LV/Jelgava; GeoNames 459279
        "geonames-289847": .init(latitude: 25.57744, longitude: 51.48306), // QA/Al Daayen; GeoNames 289847
        "geonames-3578959": .init(latitude: 16.273, longitude: -61.50507), // GP/Guadeloupe; GeoNames 3578959
        "geonames-4796512": .init(latitude: 17.72751, longitude: -64.74698), // VI/Saint Croix Island; GeoNames 4796512
        "geonames-225284": .init(latitude: 11.15583, longitude: 42.7125), // DJ/Ali Sabieh; GeoNames 225284
        "geonames-2372532": .init(latitude: 12.28, longitude: -14.22222), // GW/Gabú; GeoNames 2372532
        "geonames-3894426": .init(latitude: -45.57524, longitude: -72.06619), // CL/Aysén; GeoNames 3894426
        "geonames-932614": .init(latitude: -29.82299, longitude: 27.23744), // LS/Mafeteng District; GeoNames 932614
        "geonames-4043909": .init(latitude: 13.51777, longitude: 144.8391), // GU/Dededo; GeoNames 4043909
        "geonames-3377408": .init(latitude: 6.00815, longitude: -58.30724), // GY/Upper Demerara-Berbice; GeoNames 3377408
        "geonames-3665016": .init(latitude: -4.37555, longitude: -70.03179), // BR/Amazonas; GeoNames 3665016
        "geonames-146617": .init(latitude: 35.12489, longitude: 33.94135), // CY/Ammochostos; GeoNames 146617
        "geonames-2100633": .init(latitude: -6.22977, longitude: 155.56598), // PG/Bougainville; GeoNames 2100633
        "geonames-2562541": .init(latitude: 35.95064, longitude: 14.41561), // MT/Saint Paul’s Bay; GeoNames 2562541
        "geonames-1515029": .init(latitude: 49.98111, longitude: 92.06667), // MN/Uvs Province; GeoNames 1515029
        "geonames-4034561": .init(latitude: -17.55933, longitude: -149.60352), // PF/Îles du Vent; GeoNames 4034561
        "geonames-3994469": .init(latitude: 29.56689, longitude: -104.54487), // MX/Chihuahua; GeoNames 3994469
        "geonames-3576686": .init(latitude: 14.06667, longitude: -60.95), // LC/Gros-Islet; GeoNames 3576686
        "geonames-11703857": .init(latitude: 21.78254, longitude: -72.25206), // TC/no admin1 supplied; GeoNames 11703857
        "geonames-5955960": .init(latitude: 56.24988, longitude: -120.85292), // CA/British Columbia; GeoNames 5955960
        "geonames-5690366": .init(latitude: 46.82666, longitude: -100.88958), // US/North Dakota; GeoNames 5690366
        "geonames-3996030": .init(latitude: 20.73039, longitude: -105.283), // MX/Nayarit; GeoNames 3996030
        "geonames-2173911": .init(latitude: -31.9652, longitude: 141.4512), // AU/New South Wales; GeoNames 2173911
        "geonames-6160603": .init(latitude: 50.28337, longitude: -107.80135), // CA/Saskatchewan; GeoNames 6160603
        "geonames-2127202": .init(latitude: 64.73424, longitude: 177.5103), // RU/Chukotka; GeoNames 2127202
        "geonames-4259640": .init(latitude: 38.39144, longitude: -86.93111), // US/Indiana; GeoNames 4259640
        "geonames-7304467": .init(latitude: 8.77479, longitude: 167.73919), // MH/Kwajalein Atoll; GeoNames 7304467
        "geonames-1559446": .init(latitude: 7.33978, longitude: 134.47326), // PW/Koror; GeoNames 1559446
        "geonames-2081114": .init(latitude: 7.44648, longitude: 151.84135), // FM/Chuuk; GeoNames 2081114
        "geonames-2081342": .init(latitude: 5.32479, longitude: 163.00781), // FM/Kosrae; GeoNames 2081342
        "geonames-3166645": .init(latitude: 43.96897, longitude: 12.48167), // SM/Serravalle; GeoNames 3166645
        "geonames-5557293": .init(latitude: 57.05315, longitude: -135.33088), // US/Alaska; GeoNames 5557293
        "geonames-5001669": .init(latitude: 45.10776, longitude: -87.61427), // US/Michigan; GeoNames 5001669
        "geonames-3513522": .init(latitude: 18.04987, longitude: -63.03789), // SX/no admin1 supplied; GeoNames 3513522
        "geonames-5970458": .init(latitude: 53.3038, longitude: -60.32576), // CA/Newfoundland and Labrador; GeoNames 5970458
        "geonames-4030754": .init(latitude: -27.15253, longitude: -109.42438), // CL/Valparaiso; GeoNames 4030754
        "geonames-4265717": .init(latitude: 37.95144, longitude: -86.76777), // US/Indiana; GeoNames 4265717
        "geonames-6984577": .init(latitude: 18.06489, longitude: -63.07794), // MF/no admin1 supplied; GeoNames 6984577
        "geonames-4301224": .init(latitude: 36.82979, longitude: -84.84911), // US/Kentucky; GeoNames 4301224
        "geonames-3042041": .init(latitude: 47.16498, longitude: 9.50867), // LI/Schaan; GeoNames 3042041
        "geonames-5932311": .init(latitude: 49.09987, longitude: -116.50211), // CA/British Columbia; GeoNames 5932311
        "geonames-2411397": .init(latitude: -7.92861, longitude: -14.41194), // SH/Ascension; GeoNames 2411397
        "geonames-13631316": .init(latitude: -36.73966, longitude: 174.7423), // NZ/Auckland; GeoNames 13631316
        "geonames-6137462": .init(latitude: 51.22602, longitude: -58.65017), // CA/Quebec; GeoNames 6137462
        "geonames-5870133": .init(latitude: 64.50111, longitude: -165.40639), // US/Alaska; GeoNames 5870133
        "geonames-4922418": .init(latitude: 41.29588, longitude: -86.62501), // US/Indiana; GeoNames 4922418
        "geonames-5688003": .init(latitude: 47.26334, longitude: -101.77795), // US/North Dakota; GeoNames 5688003
        "geonames-5983607": .init(latitude: 68.36166, longitude: -133.72817), // CA/Northwest Territories; GeoNames 5983607
        "geonames-3385075": .init(latitude: -3.84205, longitude: -32.4107), // BR/Pernambuco; GeoNames 3385075
        "geonames-5888001": .init(latitude: 48.75667, longitude: -91.62409), // CA/Ontario; GeoNames 5888001
        "geonames-5955902": .init(latitude: 58.80533, longitude: -122.7002), // CA/British Columbia; GeoNames 5955902
        "geonames-4928313": .init(latitude: 41.05143, longitude: -86.60306), // US/Indiana; GeoNames 4928313
        "geonames-7626485": .init(latitude: -0.52545, longitude: 166.91247), // NR/Aiwo District; GeoNames 7626485
        "geonames-4262968": .init(latitude: 38.49199, longitude: -87.27862), // US/Indiana; GeoNames 4262968
        "geonames-3573061": .init(latitude: 32.38167, longitude: -64.67806), // BM/Saint George; GeoNames 3573061
        "geonames-7521902": .init(latitude: 2.01643, longitude: -157.48773), // KI/Line Islands; GeoNames 7521902
        "geonames-4020109": .init(latitude: -9.80342, longitude: -139.04202), // PF/Marquesas Islands; GeoNames 4020109
        "geonames-4266278": .init(latitude: 38.74784, longitude: -85.06717), // US/Indiana; GeoNames 4266278
        "geonames-2940715": .init(latitude: 47.69638, longitude: 8.68759), // DE/Baden-Wurttemberg; GeoNames 2940715
        "geonames-5555695": .init(latitude: 55.12905, longitude: -131.57698), // US/Alaska; GeoNames 5555695
        "geonames-6943713": .init(latitude: 64.06013, longitude: -139.43328), // CA/Yukon; GeoNames 6943713
        "geonames-4030556": .init(latitude: -23.12322, longitude: -134.96858), // PF/Tuamotu-Gambier Islands; GeoNames 4030556
        "geonames-7266440": .init(latitude: 16.79183, longitude: -62.21058), // MS/Saint Peter; GeoNames 7266440
        "geonames-7522181": .init(latitude: -9.20045, longitude: -171.84804), // TK/Nukunonu; GeoNames 7522181
    ]
}
