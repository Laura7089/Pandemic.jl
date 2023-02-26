World([
	# Blue
	("blue1", "blue", ["blue2", "blue3", "red2"]),
	("blue2", "blue", ["blue1", "blue3", "yellow1"]),
	("blue3", "blue", ["blue1", "blue2", "yellow3", "red3"]),

	# Yellow
	("yellow1", "yellow", ["yellow2", "yellow3", "blue2"]),
	("yellow2", "yellow", ["yellow1", "yellow3", "black1"]),
	("yellow3", "yellow", ["yellow1", "yellow2", "black3", "blue3"]),

	# Black
	("black1", "black", ["black2", "black3", "yellow2"]),
	("black2", "black", ["black1", "black3", "red1"]),
	("black3", "black", ["black1", "black2", "red3", "yellow3"]),

	# Red
	("red1", "red", ["red2", "red3", "black2"]),
	("red2", "red", ["red1", "red3", "blue1"]),
	("red3", "red", ["red1", "red2", "blue3", "black3"]),
], 6)
