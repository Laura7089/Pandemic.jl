"""
    Pandemic

A simple implementation of the logic for the cooperative board game [Pandemic](https://en.wikipedia.org/wiki/Pandemic_(board_game)).
"""
module Pandemic

# TODO: tests
# TODO: event cards?

"""
    assert(cond[, errortext])

Throw an [`AssertionError`](@ref) with the `errortext` message if `cond` does not hold.
"""
function assert(cond, errortext = "Assertion failed")
    if !cond
        throw(AssertionError(errortext))
    end
end

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

"""
    Disease(lit)

Creates a [`Disease`](@ref) from the string `lit`.

`lit` must be an [`AbstractString`](@ref).
"""
function Disease(s::AbstractString)::Disease
    sl = lowercase(s)
    for i in instances(Disease)
        if lowercase(string(Symbol(i))) == sl
            return i
        end
    end

    throw(error("Disease '$s' not found"))
end
Disease(d::Disease) = d

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

See also [`newgame`](@ref), [`setupgame!`](@ref).
"""
@with_kw mutable struct Game{R<:AbstractRNG}
    world::World
    difficulty::Difficulty
    numplayers::Int

    # TODO: it might be worth replacing this with Xoshiro for performance
    # (according to the Random docs)
    rng::R = MersenneTwister()

    # Map objects
    cubes::Matrix{Int} = zeros(Int, (length(world), length(instances(Disease))))
    stations::Vector{Bool} = [i == world.start for i = 1:length(world)]
    playerlocs::Vector{Int} = [world.start for _ = 1:numplayers]

    # Cards
    hands::Vector{Vector{Int}} = [[] for _ = 1:numplayers]
    infectiondeck::Vector{Int} = collect(1:length(world))
    infectiondiscard::Vector{Int} = Int[]
    # NOTE: a 0 denotes an epidemic card
    drawpile::Vector{Int} = Int[]
    discardpile::Vector{Int} = Int[]

    # Global state
    diseases::Vector{DiseaseState} = [Spreading for _ = 1:length(instances(Disease))]
    infectionrateindex::Int = 1
    outbreaks::Int = 0

    playerturn::Int = 1
    actionsleft::Int = ACTIONS_PER_TURN
    round::Int = 1
    state::GameState = Playing
end
export Game

"""
    setupgame!(game)

(Re-)Run setup on an existing [`Game`](@ref).

If the game is already in an end state once this has finished, this function will emit a warning then set the state of the game back to `Playing` for setup convenience.

See also [`newgame`](@ref).
"""
function setupgame!(game::Game)::Game
    @debug "Dealing hands"
    playercards = collect(1:length(game.world))
    shuffle!(game.rng, playercards)
    handsize = STARTING_HAND_OFFSET - game.numplayers
    for p = 1:game.numplayers
        game.hands[p] = collect(popmany!(playercards, handsize))
    end

    @debug "Placing disease cubes"
    shuffle!(game.rng, game.infectiondeck)
    for (numcards, numcubes) in INITIAL_INFECTIONS
        for c in popmany!(game.infectiondeck, numcards)
            _, city = getcity(game.world, c)
            game.cubes[c, Int(city.colour)] += numcubes
            push!(game.infectiondiscard, c)
        end
    end
    assert(cubeslegal(game), "Too many cubes dealt out in setup")

    @debug "Preparing draw pile"
    numpiles = Int(game.difficulty)
    subpilesize = round(length(playercards) / numpiles, RoundUp) |> Int
    for _ = 1:numpiles
        pile = collect(popmany!(playercards, subpilesize))
        push!(pile, 0)
        # TODO: faster to insert at a given point instead?
        shuffle!(game.rng, pile)
        game.drawpile = vcat(game.drawpile, pile)
    end
    assert(length(playercards) == 0) # Make sure we used up all the player cards

    state = checkstate!(game)
    if state != Playing
        @warn "Bad state after init, setting back to Playing" state
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

Effectively constructs a [`Game`](@ref) then calls [`Pandemic.setupgame!`](@ref) on it.
"""
function newgame(world, difficulty, numplayers, rng = MersenneTwister())::Game
    game = Game(world = world, difficulty = difficulty, numplayers = numplayers, rng = rng)
    setupgame!(game)
    return game
end
export newgame

"""
    drawcards!(game, player[, predicate])

Draw [`PLAYER_DRAW`](@ref) cards and put them in `player`'s hand.

Epidemics are handled if they're drawn.

`predicate` is a callback function which takes `game` and returns a (priority-ordered) collection of cards to discard.
This collection must have at least as many cards as have to be discarded.
If the player's hand doesn't exceed `MAX_HAND`, `predicate` will not be called.

If called without `predicate`, the last cards in the hand will be discarded, ie. most recently-drawn cards are prioritised for discard.
"""
function drawcards!(game::Game, p, predicate)
    @debug "Drawing cards"
    drawn = collect(popmany!(game.drawpile, PLAYER_DRAW))

    # Resolve epidemics
    for _ in filter(x -> x == 0, drawn)
        epidemic!(game)
    end

    # Add cards to hand
    for c in filter(x -> x != 0, drawn)
        push!(game.hands[game.playerturn], c)
    end

    # Handle discards
    handsize = length(game.hands[game.playerturn])
    if handsize > MAX_HAND
        numtodiscard = MAX_HAND - handsize
        @info "Hand too big, discarding cards" game.playerturn handsize MAX_HAND

        discard = Iterators.take(predicate(game), numtodiscard)
        assert(
            length(discard) < numtodiscard,
            "Predicate didn't return enough cards to discard",
        )
        for c in discard
            i = findfirst(==(c), game.hands[game.playerturn])
            discard!(game, game.playerturn, i)
        end
    end
end
function drawcards!(game::Game)
    drawcards!(game, g -> g.hands[g.playerturn][MAX_HAND+1:end])
end

"""
    epidemic!(game[, city])

Perform an epidemic outbreak at `city`.

1. Increase infection rate (`game.infectionrateindex`)
2. If there are any cards in `city`, trigger an [`outbreak!`](@ref) there
3. Set the cubes in `city` to [`MAX_CUBES_PER_CITY`](@ref)
4. Put `city` on the infection discard pile
5. Shuffle the infection discard pile and put it back on the draw pile

If `city` isn't passed, pop the bottom card from the infection draw pile and trigger the epidemic there.
"""
function epidemic!(game::Game)
    c = popat!(game.infectiondeck, 1) # "bottom" card
    epidemic!(game, c)
end
function epidemic!(game::Game, city)
    # Step 1
    game.infectionrateindex += 1

    c, city = getcity(game.world, city)
    @info "Epidemic" city

    # Step 2
    if game.cubes[c, city.colour] != 0
        outbreak!(game, c, [c])
    end

    # Step 3
    game.cubes[c] = MAX_CUBES_PER_CITY

    # Step 4
    push!(game.infectiondiscard, c)

    # Step 5
    shuffle!(game.rng, game.infectiondiscard)
    game.infectiondeck = vcat(game.infectiondeck, game.infectiondiscard)
    game.infectiondiscard = []
end

"""
    discard!(game, player, i)

Discards the card at position `i` in `player`'s hand.

Throws [`BoundsError`](@ref) if `player` doesn't have a card at that location.
"""
function discard!(game::Game, p, handi)
    push!(game.discardpile, popat!(game.hands[p], handi))
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
    @debug "Infecting city" city disease = colour
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
    @info "Outbreak" city
    colour = city.colour
    for neighbour in Graphs.neighbors(g.world.graph, c)
        if neighbour in ignore
            @debug "Ignoring city in outbreak chain" source = city neighbour
        else
            # TODO: push `c` to `ignore` here?
            infectcity!(g, neighbour, colour, ignore)
        end
    end
end

"""
    checkstate!(game)

Check if `game` is won, lost or still in progress.

Updates `game.state` if it has changed.
"""
function checkstate!(g::Game)::GameState
    # Game is already over
    if g.state != Playing
        @info "Game already ended"
        return g.state
    end

    # All cures have been found
    if all(x -> x in (Cured, Eradicated), values(g.diseases))
        @info "Game won"
        return g.state = Won
    end

    # Cube state is not legal
    if !cubeslegal(g)
        @info "Game lost; cubes illegal" g.cubes
        return g.state = Lost
    end

    # Draw deck is too low
    # TODO: is this the right way to do this condition?
    # should it be called on it's own?
    if length(g.drawpile) < PLAYER_DRAW
        @info "Game lost; draw deck too small" g.drawpile threshold = PLAYER_DRAW
        return g.state = Lost
    end

    # Outbreaks count is at or past limit
    if g.outbreaks >= MAX_OUTBREAKS
        @info "Game lost; too many outbreaks" g.outbreaks MAX_OUTBREAKS
        return g.state = Lost
    end

    return Playing
end

"""
    cubeslegal(game)

Test that the cube totals in `game` are valid, returns `true` or `false`.
"""
function cubeslegal(game::Game)::Bool
    legal = true
    for disease in instances(Disease)
        if cubesinplay(game, disease) >= CUBES_PER_DISEASE
            @info "All cubes are in play, cube state is not legal" disease
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
export Actions

include("./Formatting.jl")

include("./Maps.jl")

using PrecompileTools

# Precompilation for speedup
@compile_workload begin
    map = Pandemic.Maps.circle12()
    g = Pandemic.newgame(map, Pandemic.Introductory, 4)
    checkstate!(g)
end

end
