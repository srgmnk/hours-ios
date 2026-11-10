/// Reviewed geographic composition, not a population ranking or search catalog.
/// All keys come from OriginalDecorativeCityIDs; order is stable and intentional.
/// See docs/HOURS_MAP_VISUAL_REDESIGN.md for the selection and regional rationale.
nonisolated enum DecorativeCityIDs {
    static let catalogIDs: [String] = [
        // North America — 8; Pacific, interior, Atlantic, Mexico and Caribbean coast.
        "vancouver-ca", "los-angeles-us", "denver-us", "chicago-us",
        "toronto-ca", "new-york-us", "miami-us", "mexico-city-mx",
        // South America — 6; northern Andes, Pacific, Brazil and Southern Cone.
        "bogota-co", "lima-pe", "sao-paulo-br", "rio-br", "buenos-aires-ar", "santiago-cl",
        // Europe — 7; west, Mediterranean, central/east and the Bosporus.
        "london-gb", "paris-fr", "madrid-es", "rome-it", "berlin-de", "moscow-ru", "istanbul-tr",
        // Africa — 7; northwest, west, northeast, east and south.
        "casablanca-ma", "lagos-ng", "cairo-eg", "addis-ababa-et", "nairobi-ke",
        "johannesburg-za", "cape-town-za",
        // Asia — 17; west/south/southeast/east plus Siberia and the Russian Far East.
        "dubai-ae", "tehran-ir", "karachi-pk", "mumbai-in", "delhi-in", "dhaka-bd",
        "bangkok-th", "singapore-sg", "jakarta-id", "manila-ph", "hong-kong-hk",
        "shanghai-cn", "beijing-cn", "seoul-kr", "tokyo-jp", "novosibirsk-ru", "vladivostok-ru",
        // Oceania — 5; western/eastern Australia, New Zealand and the Pacific.
        "perth-au", "melbourne-au", "sydney-au", "auckland-nz", "suva-fj",
    ]
}
