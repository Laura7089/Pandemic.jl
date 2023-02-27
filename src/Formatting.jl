"""
    Formatting

Human-readable string representations of various parts of the game.
"""
module Formatting

using Pandemic: Game, Disease, CUBE_CHARS

"""
    citycubes(game, c[; reprs])

Get a [`String`](@ref) representation of a city's cubes.

`c` is the index of the city into `game.world.cities`.
`reprs` is a map from instances of [`Pandemic.Disease`](@ref) to strings representing each colour of cube; if not provided, uses [`Pandemic.CUBE_CHARS`](@ref).
```
"""
function citycubes(game::Game, c; reprs = CUBE_CHARS)::String
    join(reprs[d]^game.cubes[c, Int(d)] for d in instances(Disease))
end

"""
    cityplayers(game, c)

Get a [`String`](@ref) representation of the players in a city.

`c` is the index of the city into `game.world.cities`.
"""
function cityplayers(game::Game, c)::String
    to_ret = join(filter(o -> game.playerlocs[o] == c, 1:game.numplayers), ",")
    isempty(to_ret) ? "" : "♟️ $to_ret"
end

"""
    city(game, c)

Get a [`String`](@ref) representation of a city.

`c` is the index of the city into `game.world.cities`.
Shows all that is relevant:

- city name
- players in the city
- cubes in the city
"""
function city(game::Game, c)::String
    to_ret = game.world.cities[c].id
    if (p = cityplayers(game, c)) != ""
        to_ret *= " [$p]"
    end
    if (cu = citycubes(game, c)) != ""
        to_ret *= ": $cu"
    end
    to_ret
end

"""
    players(game)

Get a (multiline) [`String`](@ref) showing where each player is.
"""
function players(game::Game)::String
    city(p) = game.world.cities[game.playerlocs[p]].id
    join(("♟️ $p: $(city(p))" for p = 1:game.numplayers), "\n")
end

end
