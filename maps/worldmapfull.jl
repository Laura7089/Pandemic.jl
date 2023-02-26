World([
	# Blue
	# North America
	("San Francisco", "blue", ["Chicago", "Los Angeles", "Tokyo", "Manila"]),
	("Chicago", "blue", ["San Francisco", "Los Angeles", "Mexico City", "Atlanta", "Montreal"]),
	("Montreal", "blue", ["Chicago", "Washington", "New York"]),
	("New York", "blue", ["Montreal", "Washington", "London", "Madrid"]),
	("Washington", "blue", ["Montreal", "New York", "Miami", "Atlanta"]),
	("Atlanta", "blue", ["Chicago", "Washington", "Miami"]),
	# Europe
	("London", "blue", ["New York", "Madrid", "Paris", "London", "Essen"]),
	("Madrid", "blue", ["New York", "London", "Paris", "Algiers", "Sao Paulo"]),
	("Paris", "blue", ["London", "Essen", "Milan", "Algiers", "Madrid"]),
	("Essen", "blue", ["London", "St. Petersburg", "Milan", "Paris"]),
	("St Petersburg", "blue", ["Essen", "Moscow", "Istanbul"]),

	# Yellow
	# North America
	("Los Angeles", "yellow", ["San Francisco", "Chicago", "Mexico City", "Sydney"]),
	("Mexico City", "yellow", ["Los Angeles", "Chicago", "Miami", "Bogota", "Lima"]),
	("Miami", "yellow", ["Atlanta", "Washington", "Bogota", "Mexico City"]),
	# South America
	("Bogota", "yellow", ["Los Angeles", "Mexico City", "Sao Paulo", "Buenos Aires", "Lima"]),
	("Sao Paulo", "yellow", ["Madrid", "Lagos", "Buenos Aires", "Bogota"]),
	("Lima", "yellow", ["Mexico City", "Bogota", "Santiago"]),
	("Santiago", "yellow", ["Lima"]),
	# Africa
	("Lagos", "yellow", ["Sao Paulo", "Khartoum", "Kinshasa"]),
	("Khartoum", "yellow", ["Cairo", "Johannesburg", "Kimshasa", "Lagos"]),
	("Kinshasa", "yellow", ["Lagos", "Khartoum", "Johannesburg"]),
	("Johannesburg", "yellow", ["Kinshasa", "Khartoum"]),

	# Black
	# Middle East
	("Istanbul", "black", ["Algiers", "Milan", "St Petersburg", "Moscow", "Baghdad"]),
	("Moscow", "black", ["St Petersburg", "Tehran", "Istanbul"]),
	("Baghdad", "black", ["Istanbul", "Tehran", "Karachi", "Riyadh", "Cairo"]),
	("Riyadh", "black", ["Cairo", "Baghdad", "Karachi"]),
	("Tehran", "black", ["Moscow", "Delhi", "Karachi", "Baghdad"]),
	("Karachi", "black", ["Tehran", "Delhi", "Mumbai", "Baghdad"]),
	# Asia
	("Mumbai", "black", ["Karachi", "Delhi", "Chennai"]),
	("Delhi", "black", ["Tehran", "Kolkata", "Chennai", "Mumbai", "Karachi", "Tehran"]),
	("Kolkata", "black", ["Delhi", "Hong Kong", "Bangkok", "Chennai"]),
	("Chennai", "black", ["Delhi", "Kolkata", "Bangkok", "Jakarta", "Mumbai"]),
	# Africa
	("Algiers", "black", ["Madrid", "Paris", "Cairo", "Istanbul"]),
	("Cairo", "black", ["Algiers", "Istanbul", "Baghdad", "Riyadh", "Khartoum"]),

	# Red
	# Asia
	("Beijing", "red", ["Seoul", "Shanghai"]),
	("Seoul", "red", ["Beijing", "Tokyo", "Shanghai"]),
	("Shanghai", "red", ["Beijing", "Seoul", "Tokyo", "Taipei", "Hong Kong"]),
	("Hong Kong", "red", ["Shanghai", "Taipei", "Manila", "Ho Chi Minh City", "Bangkok", "Kolkata"]),
	("Tokyo", "red", ["Seoul", "San Francisco", "Osaka", "Shanghai"]),
	("Osaka", "red", ["Tokyo", "Taipei"]),
	("Taipei", "red", ["Osaka", "Manila", "Hong Kong", "Shanghai"]),
	("Bangkok", "red", ["Kolkata", "Hong Kong", "Ho Chi Minh City", "Jakarta", "Chennai"]),
	("Ho Chi Minh City", "red", ["Hong Kong", "Manila", "Jakarta", "Bangkok"]),
	# Oceania
	("Jakarta", "red", ["Chennai", "Bangkok", "Ho Chi Minh City", "Sydney"]),
	("Manila", "red", ["Hong Kong", "Taipei", "San Francisco", "Sydney", "Ho Chi Minh City"]),
	("Sydney", "red", ["Manila", "Los Angeles", "Jakarta"]),
], 6)
