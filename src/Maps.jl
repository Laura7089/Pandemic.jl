module Maps

using Logging
using Pandemic: World, Blue, Yellow, Black, Red

"""
    circle12()

A simple world with 12 cities arranged in a 2-row concentric ring, with quadrants of each disease.
"""
function circle12()::World
    # Disable logs since we know this map is ok
    with_logger(NullLogger()) do
        World([
            # Blue
            ("blue1", Blue, ["blue2", "blue3", "red2"]),
            ("blue2", Blue, ["blue1", "blue3", "yellow1"]),
            ("blue3", Blue, ["blue1", "blue2", "yellow3", "red3"]),

            # Yellow
            ("yellow1", Yellow, ["yellow2", "yellow3", "blue2"]),
            ("yellow2", Yellow, ["yellow1", "yellow3", "black1"]),
            ("yellow3", Yellow, ["yellow1", "yellow2", "black3", "blue3"]),

            # Black
            ("black1", Black, ["black2", "black3", "yellow2"]),
            ("black2", Black, ["black1", "black3", "red1"]),
            ("black3", Black, ["black1", "black2", "red3", "yellow3"]),

            # Red
            ("red1", Red, ["red2", "red3", "black2"]),
            ("red2", Red, ["red1", "red3", "blue1"]),
            ("red3", Red, ["red1", "red2", "blue3", "black3"]),
        ], 6)
    end
end

"""
    vanillamap()

The default map layout of the official Pandemic board game, representing all of Earth.
"""
function vanillamap()::World
    # Disable logs since we know this map is ok
    with_logger(NullLogger()) do
        World([
            # Blue
            # North America
            ("San Francisco", Blue, ["Chicago", "Los Angeles", "Tokyo", "Manila"]),
            ("Chicago", Blue, ["San Francisco", "Los Angeles", "Mexico City", "Atlanta", "Montreal"]),
            ("Montreal", Blue, ["Chicago", "Washington", "New York"]),
            ("New York", Blue, ["Montreal", "Washington", "London", "Madrid"]),
            ("Washington", Blue, ["Montreal", "New York", "Miami", "Atlanta"]),
            ("Atlanta", Blue, ["Chicago", "Washington", "Miami"]),
            # Europe
            ("London", Blue, ["New York", "Madrid", "Paris", "London", "Essen"]),
            ("Madrid", Blue, ["New York", "London", "Paris", "Algiers", "Sao Paulo"]),
            ("Paris", Blue, ["London", "Essen", "Milan", "Algiers", "Madrid"]),
            ("Essen", Blue, ["London", "St. Petersburg", "Milan", "Paris"]),
            ("St Petersburg", Blue, ["Essen", "Moscow", "Istanbul"]),

            # Yellow
            # North America
            ("Los Angeles", Yellow, ["San Francisco", "Chicago", "Mexico City", "Sydney"]),
            ("Mexico City", Yellow, ["Los Angeles", "Chicago", "Miami", "Bogota", "Lima"]),
            ("Miami", Yellow, ["Atlanta", "Washington", "Bogota", "Mexico City"]),
            # South America
            ("Bogota", Yellow, ["Los Angeles", "Mexico City", "Sao Paulo", "Buenos Aires", "Lima"]),
            ("Sao Paulo", Yellow, ["Madrid", "Lagos", "Buenos Aires", "Bogota"]),
            ("Lima", Yellow, ["Mexico City", "Bogota", "Santiago"]),
            ("Santiago", Yellow, ["Lima"]),
            # Africa
            ("Lagos", Yellow, ["Sao Paulo", "Khartoum", "Kinshasa"]),
            ("Khartoum", Yellow, ["Cairo", "Johannesburg", "Kimshasa", "Lagos"]),
            ("Kinshasa", Yellow, ["Lagos", "Khartoum", "Johannesburg"]),
            ("Johannesburg", Yellow, ["Kinshasa", "Khartoum"]),

            # Black
            # Middle East
            ("Istanbul", Black, ["Algiers", "Milan", "St Petersburg", "Moscow", "Baghdad"]),
            ("Moscow", Black, ["St Petersburg", "Tehran", "Istanbul"]),
            ("Baghdad", Black, ["Istanbul", "Tehran", "Karachi", "Riyadh", "Cairo"]),
            ("Riyadh", Black, ["Cairo", "Baghdad", "Karachi"]),
            ("Tehran", Black, ["Moscow", "Delhi", "Karachi", "Baghdad"]),
            ("Karachi", Black, ["Tehran", "Delhi", "Mumbai", "Baghdad"]),
            # Asia
            ("Mumbai", Black, ["Karachi", "Delhi", "Chennai"]),
            ("Delhi", Black, ["Tehran", "Kolkata", "Chennai", "Mumbai", "Karachi", "Tehran"]),
            ("Kolkata", Black, ["Delhi", "Hong Kong", "Bangkok", "Chennai"]),
            ("Chennai", Black, ["Delhi", "Kolkata", "Bangkok", "Jakarta", "Mumbai"]),
            # Africa
            ("Algiers", Black, ["Madrid", "Paris", "Cairo", "Istanbul"]),
            ("Cairo", Black, ["Algiers", "Istanbul", "Baghdad", "Riyadh", "Khartoum"]),

            # Red
            # Asia
            ("Beijing", Red, ["Seoul", "Shanghai"]),
            ("Seoul", Red, ["Beijing", "Tokyo", "Shanghai"]),
            ("Shanghai", Red, ["Beijing", "Seoul", "Tokyo", "Taipei", "Hong Kong"]),
            ("Hong Kong", Red, ["Shanghai", "Taipei", "Manila", "Ho Chi Minh City", "Bangkok", "Kolkata"]),
            ("Tokyo", Red, ["Seoul", "San Francisco", "Osaka", "Shanghai"]),
            ("Osaka", Red, ["Tokyo", "Taipei"]),
            ("Taipei", Red, ["Osaka", "Manila", "Hong Kong", "Shanghai"]),
            ("Bangkok", Red, ["Kolkata", "Hong Kong", "Ho Chi Minh City", "Jakarta", "Chennai"]),
            ("Ho Chi Minh City", Red, ["Hong Kong", "Manila", "Jakarta", "Bangkok"]),
            # Oceania
            ("Jakarta", Red, ["Chennai", "Bangkok", "Ho Chi Minh City", "Sydney"]),
            ("Manila", Red, ["Hong Kong", "Taipei", "San Francisco", "Sydney", "Ho Chi Minh City"]),
            ("Sydney", Red, ["Manila", "Los Angeles", "Jakarta"]),
        ], 6)
    end
end

end
