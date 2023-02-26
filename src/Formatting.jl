module Formatting

import ..Game
import ..CUBE_CHARS

"""
    citycubes(game, c)

Get a [`String`](@ref) representation of a city's cubes.

`c` is the index of the city into `game.world.cities`.
Uses emoji from [`CUBE_CHARS`](@ref).

# Examples
```julia-repl
julia> Pandemic.Formatting.citycubes(game, 3)
"🟨🟨🟨"
```
"""
function citycubes(game::Game, c)::String
	city = game.world.cities[c]

	to_return = ""
	for (disease, emoji) in CUBE_CHARS
		if (numcubes = game.cubes[c, Int(disease)]) != 0
			to_return *= emoji ^ numcubes
		end
	end
	to_return
end

"""
    cityplayers(game, c)

Get a [`String`](@ref) representation of the players in a city.

`c` is the index of the city into `game.world.cities`.
"""
function cityplayers(game::Game, c)::String
	to_ret = ""
	for p in 1:game.numplayers
		if game.playerlocs[p] == c
			to_ret *= "$(p), "
		end
	end
	if to_ret != "" "[♟️ $(to_ret[1:end-2])]" else "" end
end

"""
    city(game, c)

Get a [`String`](@ref) representation of a city; ie. its name, players within and cubes contained.
"""
function city(game::Game, c)::String
	players = if (p = cityplayers(game, c)) != ""
		" $(p)"
	else "" end
	cubes = if (cu = cubes(game, c)) != ""
		": $(cu)"
	else "" end
	game.world.cities[c].id * players * cubes
end

end
