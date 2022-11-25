"""
    Actions

Logic for all the actions a player can carry out on their turn.

Unless otherwise specified, the functions in this module ***do not*** check if:

- the player has enough actions remaining to perform the action
- the correct player's turn is currently in progress
- the game has ended
"""
module Actions

# TODO: tests
# TODO: @debug and other logging

using Match
using Pandemic:
    stationcount, MAX_STATIONS, Game, Disease, CARDS_TO_CURE, getcity, discard!, cityindex
using Graphs

"""
    move_one!(game, player, city)

Perform a regular move for `player` to `city`.

Throws an error if `player` is not in an adjacent city.
"""
function move_one!(g::Game, p, dest)
    source = g.playerlocs[p]
    dest, destc = getcity(g.world, dest)
    @assert dest in neighbors(g.world.graph, source) "Player $(p) is not in a city adjacent to '$(destc)'"

    g.playerlocs[p] = dest
end
export move_one!

"""
    move_direct!(game, player, city)

Perform a "direct flight" move for `player` to `city`.

Discards the card for `city` from `player`'s hand.
Throws an error if `player` is not holding the `city` card.
"""
function move_direct!(g::Game, p, dest)
    source = g.playerlocs[p]
    dest, destc = getcity(g.world, dest)

    handloc = findfirst(x -> x == dest, g.hands[p])
    @assert handloc != nothing "Player $(p) does not have the card for '$(destc)' in their hand"

    # TODO: above assert is irrelevant? `discard` will error if they don't have it
    discard!(g, p, handloc)
    g.playerlocs[p] = dest
end
export move_direct!

"""
    move_chartered!(game, player, city)

Perform a "chartered flight" move for `player` to `city`.

Discards the card for `player`'s current location from their hand.
Throws an error if `player` is not holding their current location.
"""
function move_chartered!(g::Game, p, dest)
    source = g.playerlocs[p]
    dest = cityindex(g.world, dest)

    handloc = findfirst(x -> x == source, g.hands[p])
    @assert handloc != nothing "Player $(p) does not have the '$(source)' card"

    discard!(g, p, handloc)
    g.playerlocs[p] = dest
end
export move_chartered!

"""
    move_station!(game, player, dest)

Move `player` from a city with a research station to `dest`.

Throws an error if either city doesn't have a research station.
"""
function move_station!(g::Game, p, dest)
    source = g.playerlocs[p]
    dest = cityindex(g.world, dest)

    @assert g.stations[source] "Source doesn't have a research station"
    @assert g.stations[dest] "Dest doesn't have a research station"

    g.playerlocs[p] = dest
end
export move_station!

"""
    buildstation!(game, player, city[, move_from])

Build a research station in `city` with the relevant card from `player`.

If there are already [`MAX_STATIONS`](@ref) in the game, `move_from` will determine which city loses a station to build this one.
Throws errors if:

- `player` isn't in the right city
- `player` doesn't have the relevant card
- [`MAX_STATIONS`](@ref) are in play and `move_from` is not passed
"""
function buildstation!(g::Game, p, city, move_from = nothing)
    c, city = getcity(g.world, city)

    @assert g.playerlocs[p] == c "Player $(p) is not in $(city)"

    if stationcount(g) == MAX_STATIONS
        @assert move_from != nothing "Max stations reached ($(MAX_STATIONS)) but move_from is empty!"

        move_from = cityindex(g.world, move_from)
        g.stations[move_from] = false
    end

    handi = findfirst(x -> x == c, g.hands[player])
    @assert handi != nothing "Player $(p) doesn't have $(city) in their hand"

    discard!(g, p, handi)
    g.stations[city] = true
end
export buildstation!

"""
    treatdisease!(game, player, city, colour)

Treat a `colour` disease according to the game rules.

Throws errors if:

- there are no disease cubes of `colour` on `city`
- `player` is not in `city`
"""
function treatdisease!(g::Game, p, city, colour::Disease)
    c, city = getcity(g.world, city)
    d = Int(colour)
    @assert g.playerlocs[p] == c "Player $(p) is not in '$(city)'"
    @assert g.cubes[c, d] != 0 "City '$(city)' has no $(colour) disease cubes"

    @match g.diseasestate[d] begin
        Spreading => (g.cubes[c, d] -= 1)
        Cured => (g.cubes[c, d] = 0) # TODO: check if eradicated
        Eradicated => throw(error("unreachable"))
    end
end
export treatdisease!

"""
    shareknowledge!(game, player1, player2, city)

Move the `city` card from `player1`'s hand to `player2`'s hand.

Throws if either player isn't in `city`.
"""
function shareknowledge!(g::Game, p1, p2, city)
    c, city = getcity(g.world, city)
    @assert g.playerlocs[p1] == c && g.playerlocs[p2] == c "Players $(p1) and $(p2) are not in '$(city)'"

    handi = findfirst(x -> x == card, g.hands[p1])
    @assert handi != nothing "$(p1) does not have $(card) in their hand"
    push!(g.hands[p2], popat!(g.hands[p1], handi))
end
export shareknowledge!

"""
    findcure!(game, player, colour[, cards])

Cures the `colour` disease using `cards` from `player`'s hand.

If the `cards` parameter isn't passed, the first 5 cards which match `colour` are used.
Throws an error if:

- The city that the player is in doesn't have a research station
- `cards`, if given, is the wrong length
- The player doesn't have the correct cards
"""
function findcure!(g::Game, p, d::Disease)
    eligiblecards = filter(x -> g.world.cities[x].colour == d, g.hands[p])
    @assert length(eligiblecards) >= CARDS_TO_CURE "Player $(p) does not have enough $(d) cards"
    _findcure!(g, p, d, eligiblecards[begin:5])
end
function findcure!(g::Game, p, d::Disease, cards)
    @assert length(cards) == CARDS_TO_CURE
    @assert all(c -> g.world.cities[c].colour == d, cards) "Card colours differ"
    @assert cards ⊆ g.hands[p] "Player does not have the requested cards"
    _findcure!(g, p, d, cards)
end
export findcure!

"""
    _findcure!(game, player, disease, cards)

Internal function for curing diseases.

Doesn't make many assertions about the arguments.
"""
function _findcure!(g::Game, p, d::Disease, cards)
    # We know `cards` is entirely valid at this point
    @assert g.stations[g.playerlocs[p]] "No station at player's location"

    g.diseases[d] = if cubesinplay(g, d) == 0
        Eradicated
    else
        Cured
    end

    for card in cards
        # Find and delete the card from the player's hand
        i = findfirst(c -> c == card, g.hands[p])
        discard!(g, p, i)
    end
end

end
