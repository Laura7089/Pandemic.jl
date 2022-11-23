"""
    Actions

Logic for all the actions a player can carry out on their turn.

Unless otherwise specified, the functions in this module ***do not*** check if:

- The player pawn is in the correct place to carry out an action
- The correct player's turn is currently in progress
- The game has ended
"""
module Actions

using Match
using Pandemic: stationcount, MAX_STATIONS, Game, Disease, CARDS_TO_CURE

"""
    buildstation!(game, city[, move_from])

Build a research station in `city`.

If there are already [`MAX_STATIONS`](@ref) in the game, the `move_from` parameter will determine which city loses a research station to build this one.
"""
function buildstation!(g::Game, city, move_from = nothing)
    city = cityindex(g.world, city)
    if stationcount(g) == MAX_STATIONS
        @assert move_from != nothing "Max stations reached ($(MAX_STATIONS)) but move_from is empty!"

        move_from = cityindex(g.world, move_from)
        g.stations[move_from] = false
    end
    g.stations[city] = true
end

"""
    treatdisease!(game, city, colour)

Treat a `colour` disease according to the game rules.

Throws an error if there are no disease cubes of `colour` on `city`.
"""
function treatdisease!(g::Game, city, colour::Disease)
    c = cityindex(g.world, city)
    d = Int(colour)
    @assert g.cubes[c, d] != 0 "City '$(g.world.cities[c].id)' has no $(colour) disease cubes"

    @match g.diseasestate[d] begin
        Spreading => (g.cubes[c, d] -= 1)
        Cured => (g.cubes[c, d] = 0) # TODO: check if eradicated
        Eradicated => throw(error("The $(colour) disease is eradicated"))
    end
end

"""
    shareknowledge!(game, player1, player2)

Move a card from `player1`'s hand to `player2`'s hand.

Checks if both players are in the correct city.
"""
function shareknowledge!(g::Game, player1, player2, card)
    if g.playerlocs[player1] != g.playerlocs[player2] != card
        throw(error("Players $(player1) and $(player2) are not in the correct city"))
    end

    handi = findfirst(x -> x == card, g.hands[player1])
    @assert handi != nothing "$(player1) does not have $(card) in their hand"
    push!(g.hands[player2], popat!(g.hands[player1], handi))
end

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
        deleteat!(g.hands[p], i)
    end
end

end
