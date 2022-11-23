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
using Pandemic: stationcount, MAX_STATIONS

"""
    buildstation!(game, city[, move_from])

Build a research station in `city`.

If there are already [`MAX_STATIONS`](@ref) in the game, the `move_from` parameter will determine which city loses a research station to build this one.
"""
function buildstation!(g::Game, city, move_from = nothing)
    city = cityindex(g.world, city)
    if stationcount(g) == MAX_STATIONS
        if move_from == nothing
            throw(
                error(
                    "The maximum number of stations has been reached ($(MAX_STATIONS)), but the move_from parameter was empty!",
                ),
            )
        end

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

end
