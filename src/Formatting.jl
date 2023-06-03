"""
    Formatting

Human-readable string representations of various parts of the game.
"""
module Formatting

using Pandemic
using DataStructures: counter

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

Get a (multiline) [`String`](@ref) showing where each player is and a summary of their hand.
"""
function players(game::Game)::String
    function ch(hand)
        buckets = counter(map((c) -> game.world.cities[c].colour, hand))
        return join((d for d in buckets if d.second > 0), ", ")
    end
    city(p) = cityid(game.world, game.playerlocs[p])

    join(
        ("♟️ $p: $(city(p)), hand: $(ch(game.hands[p]))" for p = 1:game.numplayers),
        "\n",
    )
end

"""
    summary(game)

Get a simple human-readable summary of the state of `game`.
"""
function summary(game::Game)::String
    stationlocs = [cityid(game.world, c) for c in stations(game)]
    ps = string("\t", replace(players(game), "\n" => "\n\t"))
    diseases = [
        "\t$d is $(game.diseases[Int(d)]), $(cubesinplay(game, d)) cubes" for
        d in instances(Disease)
    ]

    return """Players:
    $(ps)
    Diseases:
    $(join(diseases, "\n"))
    Stations: $(join(stationlocs, ", "))
    Draw cards left: $(length(game.drawpile))
    Outbreaks: $(game.outbreaks)
    State: $(Pandemic.checkstate(game))"""
end

end
