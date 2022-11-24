module Pandemic

# TODO: write tests

include("./parameters.jl")
include("./world.jl")

using Random
using Parameters

# Thanks to https://stackoverflow.com/questions/68997862/pop-multiple-items-from-julia-vector
"""
    popmany!(c, n)

[`pop!`](@ref)s `n` elements from collection `c`.

If `c` is too small, this function will [`pop!`](@ref) as many elements as it can.
"""
popmany!(c, n) = (pop!(c) for _ = 1:min(n, length(c)))

@enum PlayerAction begin
    # Movement
    DriveSail
    DirectFlight
    CharterFlight
    ShuttleFlight
    # Other actions
    BuildStation
    TreatDisease
    ShareKnowledge
    DiscoverCure
end

"""
    DiseaseState

The status of a particular disease in the game.

Can be `Spreading`, `Cured` or `Eradicated`.
"""
@enum DiseaseState begin
    Spreading
    Cured
    Eradicated
end

"""
    GameState

The win/loss status of a game.

Can be `Playing`, `Won` or `Lost`.
"""
@enum GameState begin
    Won
    Lost
    Playing
end
export GameState

"""
    Game{R<:AbstractRNG}

A complete state of an in-progress or finished game session.

Holds the hands, decks, cubes, research stations, settings, counters and RNG for a session.
"""
@with_kw mutable struct Game{R<:AbstractRNG}
    world::World
    difficulty::Difficulty
    numplayers::Int

    rng::R = MersenneTwister()

    # Map objects
    cubes::Matrix{Int} = zeros(Int, (length(world), length(instances(Disease))))
    stations::Vector{Bool} = [i == world.start for i = 1:length(world)]
    playerlocs::Vector{Int} = [world.start for _ = 1:numplayers]

    # Cards
    # TODO: event cards?
    hands::Vector{Vector{Int}} = [[] for _ = 1:numplayers]
    infectiondeck::Vector{Int} = collect(1:length(world))
    infectiondiscard::Vector{Int} = Int[]
    # NOTE: a 0 denotes an epidemic card
    drawpile::Vector{Int} = Int[]

    # Global state
    diseases::Vector{DiseaseState} = [Spreading for _ = 1:length(instances(Disease))]
    infectionrateindex::Int = 1
    outbreaks::Int = 0

    playerturn::Int = 1
    round::Int = 1
    state::GameState = Playing
end
export Game

"""
    setupgame!(game)

(Re-)Run setup on an existing [`Game`](@ref).

If the game is already in an end state once this has finished, this function will emit a warning then set the state of the game back to `Playing` for setup convenience.
"""
function setupgame!(game::Game)::Game
    @debug("Dealing hands")
    playercards = collect(1:length(game.world))
    shuffle!(game.rng, playercards)
    handsize = STARTING_HAND_OFFSET - game.numplayers
    for p = 1:game.numplayers
        game.hands[p] = collect(popmany!(playercards, handsize))
    end

    @debug("Placing disease cubes")
    shuffle!(game.rng, game.infectiondeck)
    for (numcards, numcubes) in INITIAL_INFECTIONS
        for c in popmany!(game.infectiondeck, numcards)
            _, city = getcity(game.world, c)
            game.cubes[c, Int(city.colour)] += numcubes
            push!(game.infectiondiscard, c)
        end
    end
    @assert cubeslegal(game) "Too many cubes dealt out in setup"

    @debug("Preparing draw pile")
    numpiles = Int(game.difficulty)
    subpilesize = Int(round(length(playercards) / numpiles, RoundUp))
    for _ = 1:numpiles
        pile = collect(popmany!(playercards, subpilesize))
        push!(pile, 0)
        # TODO: faster to insert at a given point instead?
        shuffle!(game.rng, pile)
        game.drawpile = vcat(game.drawpile, pile)
    end
    @assert(length(playercards) == 0) # Make sure we used up all the player cards

    state = checkstate!(game)
    if state != Playing
        @warn "Game is already $(state), setting back to Playing"
        game.state = Playing
    end

    if isempty(game.infectiondeck)
        @error "The infection draw pile is empty after game setup"
    end
    return game
end

"""
    newgame(world, difficulty, numplayers[, rng])

Create a new [`Game`](@ref) and set it up for the first turn.

Effectively constructs a [`Game`](@ref) then calls [`setupgame!`](@ref) on it.
"""
function newgame(world, difficulty, numplayers, rng = MersenneTwister())::Game
    game = Game(world = world, difficulty = difficulty, numplayers = numplayers, rng = rng)
    setupgame!(game)
    return game
end
export newgame

"""
    drawcards!(game[, predicate])

Perform the player deck draw, usually at the end of a turn.

`predicate` should be a callback function which takes the `game` object and returns a (priority-ordered) collection/iterator of cards to discard.
The returned collection must be at least as long as the number of cards that have to be discarded.
If the player's hand doesn't exceed `MAX_HAND`, `predicate` will not be called.

If `drawcards!` is called without `predicate`, the last cards in the hand will be discarded, ie. most recently-drawn cards are prioritised for discard.
"""
function drawcards!(game::Game, predicate)
    @debug "Drawing cards"
    drawn = collect(popmany!(game.drawpile, PLAYER_DRAW))

    # Resolve epidemics
    # TODO: special action if 2 epidemics drawn?
    for _ in filter(x -> x == 0, drawn)
        c = popat!(game.infectiondeck, 1) # "bottom" card
        city = game.world.cities[c]
        @info "Epidemic in $(city)"
        if game.cubes[c, city.colour] != 0
            outbreak!(game, c, [c])
        end
        game.cubes[c] = MAX_CUBES_PER_CITY
        push!(game.infectiondiscard, 0) # back into the infection deck
    end

    # Add cards to hand
    for c in filter(x -> x != 0, drawn)
        push!(game.hands[game.playerturn], c)
    end

    handsize = length(game.hands[game.playerturn])
    if handsize > MAX_HAND
        numtodiscard = MAX_HAND - handsize
        @info "Player hand too big, discarding cards with predicate" game.game.playerturn handsize MAX_HAND numtodiscard

        discard = Iterators.take(predicate(game), numtodiscard)
        @assert length(discard) < numtodiscard "Predicate didn't return enough cards to discard"
        for c in discard
            i = findfirst(x -> x == c, game.hands[game.playerturn])
            deleteat!(game.hands[game.playerturn], 1)
            push!(game.discardpile, c)
        end
    end
end
function drawcards!(game::Game)
    drawcards!(game, g -> g.hands[g.playerturn][MAX_HAND+1:end])
end

"""
    infectcities!(game)

Draw the appropriate amount of infection cards and call [`infectcity!`](@ref) with them.
"""
function infectcities!(game::Game)
    drawninfections = popmany!(game.infectiondeck, INFECTION_RATES[game.infectionrateindex])
    infectcity!.(Ref(game), drawinfections)
end

"""
    infectcity!(game, city[, colour][, outbreakignore])

Infect `city` with one cube of `colour`.

If `colour == nothing` then the default colour of `city` will be used.
Trigger an outbreak iff `city` has [`MAX_CUBES_PER_CITY`](@ref) cubes before infection.
Pass `outbreakignore = [..]` to whitelist given cities from outbreaks resulting from this infection.
"""
function infectcity!(g::Game, city, colour = nothing, outbreakignore::Vector{Int} = [])
    c, city = getcity(g.world, city)
    colour = colour == nothing ? city.colour : colour
    @debug "Infecting $(city) with $(colour)"
    if g.cubes[c, Int(colour)] == MAX_CUBES_PER_CITY
        outbreak!(g, c, vcat(outbreakignore, [c]))
    else
        g.cubes[c, Int(colour)] += 1
    end
end

"""
    outbreak!(game, city, ignore)

Trigger an outbreak around `city`.

Ignore any cities in `ignore` in chain outbreaks.
"""
function outbreak!(g::Game, city, ignore::Vector{Int})
    g.outbreaks += 1
    c, city = getcity(g.world, city)
    @info "Outbreak in $(city)!"
    colour = city.colour
    for neighbour in Graphs.neighbors(g.world.graph, c)
        if neighbour in ignore
            @debug "Ignoring $(neighbour) in outbreak chain from $(city)"
            continue
        end
        infectcity!(g, neighbour, colour, ignore)
    end
end

"""
    checkstate(game)

Check if `game` is won, lost or still in progress.

Updates `game.state` if it has changed.
"""
function checkstate!(g::Game)::GameState
    # Game is already over
    if g.state != Playing
        return g.state
    end

    # All cures have been found
    if all(x -> x in (Cured, Eradicated), values(g.diseases))
        g.state = Won
        return Won
    end

    # Cube state is not legal
    if !cubeslegal(g)
        g.state = Lost
        return Lost
    end

    # Draw deck is empty
    # TODO: is this the right way to do this condition?
    # should it be called on it's own?
    if length(g.drawpile) < PLAYER_DRAW
        g.state = Lost
        return Lost
    end

    # Outbreaks count is at or past limit
    if g.outbreaks >= MAX_OUTBREAKS
        g.state = Lost
        return Lost
    end

    return Playing
end

"""
    cubeslegal(game)

Test that the cube totals in `game` are valid, returns `true` or `false`.
"""
function cubeslegal(game::Game)::Bool
    legal = true
    for d in instances(Disease)
        if cubesinplay(game, d) >= CUBES_PER_DISEASE
            @info "All $(d) cubes are in play, cube state is not legal"
            legal = false
        end
    end
    legal
end

"""
    stationcount(game)

Count the number of stations in play.
"""
function stationcount(game::Game)::Int
    filter(identity, game.stations) |> length
end

"""
    cubesinplay(game, colour)

Count the number of cubes of `colour` in play.
"""
function cubesinplay(game::Game, d::Disease)::Int
    game.cubes[:, Int(d)] |> sum
end

include("./Actions.jl")

end
