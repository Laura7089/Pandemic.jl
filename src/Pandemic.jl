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

include("./settings.jl")
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
    poprandom!(S)

Pop a random element from collection `S` and return it.
"""
function poprandom!(S::Vector, rng)
    if isempty(S)
        throw(error("Empty vector passed to poprandom!"))
    end
    i = Random.rand(rng, 1:length(S))
    return popat!(S, i)
end

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
export Disease

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
function Base.show(io::IO, ds::DiseaseState)
    if ds == Spreading
        write(io, "Spreading")
    elseif ds == Cured
        write(io, "Cured")
    elseif ds == Eradicated
        write(io, "Eradicated")
    end
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
    settings::Settings

    # TODO: it might be worth replacing this with Xoshiro for performance
    # (according to the Random docs)
    rng::R = MersenneTwister()

    # Map objects
    cubes::Matrix{Int} = zeros(Int, (length(world), length(instances(Disease))))
    stations::Vector{Bool} = [i == world.start for i = 1:length(world)]
    playerlocs::Vector{Int} = [world.start for _ = 1:settings.num_players]

    # Cards
    hands::Vector{Vector{Int}} = [[] for _ = 1:settings.num_players]

    infectiondeck::Vector{Int} = collect(1:length(world))
    infectiondeckseen::Vector{Int} = Int[]
    infectiondiscard::Vector{Int} = Int[]
    # a 0 denotes an epidemic card
    drawpile::Vector{Vector{Int}} = Vector{Int}[]
    discardpile::Vector{Int} = Int[]

    # Global state
    diseases::Vector{DiseaseState} = [Spreading for _ = 1:length(instances(Disease))]
    infectionrateindex::Int = 1
    outbreaks::Int = 0

    playerturn::Int = 1
    actionsleft::Int = settings.actions_per_turn
    round::Int = 1
end
export Game

Base.show(io::IO, game::Game) = write(io, Formatting.summary(game))

"""
    setupgame!(game)

(Re-)Run setup on an existing [`Game`](@ref).

Pass `rng` as a kwarg to override `game.rng`.

See also [`newgame`](@ref).
"""
function setupgame!(game::Game; rng = game.rng)::Game
    @debug "Dealing hands"
    playercards = collect(1:length(game.world))
    shuffle!(rng, playercards)
    handsize = game.settings.starting_hand
    for p = 1:game.settings.num_players
        game.hands[p] = collect(popmany!(playercards, handsize))
    end

    @debug "Placing disease cubes"
    shuffle!(rng, game.infectiondeck)
    for (numcards, numcubes) in game.settings.initial_infections
        for c in popmany!(game.infectiondeck, numcards)
            _, city = getcity(game.world, c)
            game.cubes[c, Int(city.colour)] += numcubes
            push!(game.infectiondiscard, c)
        end
    end
    assert(cubeslegal(game), "Too many cubes dealt out in setup")

    @debug "Preparing draw pile"
    numpiles = Int(game.settings.difficulty)
    subpilesize = round(length(playercards) / numpiles, RoundUp) |> Int
    for _ = 1:numpiles
        subpile = collect(popmany!(playercards, subpilesize))
        push!(subpile, 0)
        shuffle!(rng, subpile)
        push!(game.drawpile, subpile)
    end
    assert(length(playercards) == 0) # Make sure we used up all the player cards

    state = checkstate(game)
    if state != Playing
        @warn "Bad state after init, ignoring" state
    end

    if isempty(game.infectiondeck)
        @error "The infection draw pile is empty after game setup"
    end
    return game
end

"""
    newgame(world, settings[, rng])

Create a new [`Game`](@ref) and set it up for the first turn.

`settings` should be a [`Settings`](@ref) object.
Effectively constructs a [`Game`](@ref) then calls [`Pandemic.setupgame!`](@ref) on it.
"""
function newgame(world, settings::Settings, rng = MersenneTwister())::Game
    game = Game(world = world, settings = settings, rng = rng)
    setupgame!(game)
    return game
end
export newgame

"""
    stations(game)

Get a [`Vector`](@ref) of research station locations in `game`.
"""
function stations(game)::Vector{Int}
    [c for (c, s) in enumerate(game.stations) if s]
end
export stations

function drawcard!(game::Game, rng=game.rng)
    if game.drawpile |> last |> isempty
        pop!(game.drawpile)
    end
    return poprandom!(last(game.drawpile), rng)
end

"""
    drawpilesize(game)

Get the number of cards in the draw pile.
"""
function drawpilesize(game::Game)
    if isempty(game.drawpile)
        return 0
    else
        return sum(length, game.drawpile)
    end
end
export drawpilesize

"""
    drawcards!(game, player[, predicate])

Draw `game.settings.player_draw` cards and put them in `player`'s hand.

Epidemics are handled if they're drawn.

`predicate` is a callback function which takes `game` and returns a (priority-ordered) collection of cards to discard.
This collection must have at least as many cards as have to be discarded.
If the player's hand doesn't exceed `game.settings.max_hand`, `predicate` will not be called.

If called without `predicate`, the last cards in the hand will be discarded, ie. most recently-drawn cards are prioritised for discard.

Pass the `rng` kwarg to override `game.rng`.
"""
function drawcards!(game::Game, p, predicate; rng = game.rng)
    @debug "Drawing cards"
    drawn = []
    for _ in game.settings.player_draw
        try
            push!(drawn, drawcard!(game, rng))
        catch
            @debug "No more cards to draw"
        end
    end

    # Resolve epidemics
    for _ in filter(x -> x == 0, drawn)
        epidemic!(game; rng = rng)
    end

    # Add cards to hand
    for c in filter(x -> x != 0, drawn)
        push!(game.hands[game.playerturn], c)
    end

    # Handle discards
    handsize = length(game.hands[game.playerturn])
    if handsize > game.settings.max_hand
        numtodiscard = handsize - game.settings.max_hand
        @debug "Hand too big, discarding cards" game.playerturn handsize game.settings.max_hand

        discard = Iterators.take(predicate(game), numtodiscard)
        assert(
            length(discard) == numtodiscard,
            "Predicate returned $(length(discard)) to return, needed $numtodiscard",
        )
        for c in discard
            i = findfirst(==(c), game.hands[game.playerturn])
            discard!(game, game.playerturn, i)
        end
    end
end
function drawcards!(game::Game, p; rng = nothing)
    drawcards!(game, p, g -> g.hands[g.playerturn][game.settings.max_hand+1:end]; rng = rng)
end
export drawcards!

"""
    epidemic!(game[, city])

Perform an epidemic outbreak at `city`.

1. Increase infection rate (`game.infectionrateindex`)
2. If there are any cubes in `city`, trigger an [`outbreak!`](@ref) there
3. Set the cubes in `city` to `game.settings.max_cubes_per_city`
4. Put `city` on the infection discard pile
5. Shuffle the infection discard pile and put it back on the draw pile

If `city` isn't passed, pop the bottom card from the infection draw pile and trigger the epidemic there.

Pass the `rng` kwarg to override `game.rng`.
"""
function epidemic!(game::Game; rng = game.rng)
    # TODO: what if the infection deck is empty?
    c = poprandom!(game.infectiondeck, rng) # a random UNSEEN card
    epidemic!(game, c; rng = rng)
end
function epidemic!(game::Game, city; rng = game.rng)
    # Step 1
    game.infectionrateindex += 1

    c, city = getcity(game.world, city)
    @debug "Epidemic" city

    # Step 2
    if game.cubes[c, Int(city.colour)] != 0
        outbreak!(game, c, [c])
    end

    # Step 3
    game.cubes[c, Int(city.colour)] = game.settings.max_cubes_per_city

    # Step 4
    push!(game.infectiondiscard, c)

    # Step 5
    game.infectiondeckseen = vcat(game.infectiondeckseen, game.infectiondiscard)
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
function infectcities!(game::Game, rng=game.rng)
    for _ in 1:game.settings.infection_rates[game.infectionrateindex]
        city = if !isempty(game.infectiondeckseen)
            poprandom!(game.infectiondeckseen, rng)
        else
            poprandom!(game.infectiondeck, rng)
        end
        infectcity!(game, city)
        push!(game.infectiondiscard, city)
    end
end
export infectcities!

"""
    infectcity!(game, city[, colour][, outbreakignore])

Infect `city` with one cube of `colour`.

If `colour == nothing` then the default colour of `city` will be used.
Trigger an outbreak iff `city` has `game.settings.max_cubes_per_city` cubes before infection.
Pass `outbreakignore = [..]` to whitelist given cities from outbreaks resulting from this infection.
"""
function infectcity!(g::Game, city; colour = nothing, outbreakignore = Int64[])
    c, city = getcity(g.world, city)
    colour = colour == nothing ? city.colour : colour
    @debug "Infecting city" city disease = colour
    if g.cubes[c, Int(colour)] == g.settings.max_cubes_per_city
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
    @debug "Outbreak" city
    colour = city.colour
    for neighbour in Graphs.neighbors(g.world.graph, c)
        if neighbour in ignore
            @debug "Ignoring city in outbreak chain" source = city neighbour
        else
            # TODO: push `c` to `ignore` here?
            infectcity!(g, neighbour, colour = colour, outbreakignore = ignore)
        end
    end
end

"""
    checkstate(game)

Check if `game` is won, lost or still in progress.
"""
function checkstate(g::Game)::GameState
    # All cures have been found
    if all(x -> x in (Cured, Eradicated), values(g.diseases))
        @debug "Game won"
        return Won
    end

    # Cube state is not legal
    if !cubeslegal(g)
        @debug "Game lost; cubes illegal" g.cubes
        return Lost
    end

    # Draw deck is too low
    # TODO: is this the right way to do this condition?
    # should it be called on it's own?
    if isempty(g.drawpile) || drawpilesize(g) < g.settings.player_draw
        @debug "Game lost; draw deck too small" g.drawpile threshold =
            g.settings.player_draw
        return Lost
    end

    # Outbreaks count is at or past limit
    if g.outbreaks >= g.settings.max_outbreaks
        @debug "Game lost; too many outbreaks" g.outbreaks g.settings.max_outbreaks
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
    for disease in instances(Disease)
        if cubesinplay(game, disease) >= game.settings.cubes_per_disease
            @debug "All cubes are in play, cube state is not legal" disease
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
export cubesinplay

"""
    endturn!(game[, discard])

End the turn of the current player.

Calls [`Pandemic.infectcities!`](@ref) and [`Pandemic.drawcards!`](@ref).
The `discard` argument will be passed to `drawcards!`.
Returns `true` if the "round" ticked over.

Pass `rng` kwarg to override `game.rng`.
"""
function endturn!(g::Game, discard = nothing; rng = nothing)::Bool
    if isnothing(discard)
        drawcards!(g, g.playerturn; rng = rng)
    else
        drawcards!(g, g.playerturn, discard; rng = rng)
    end
    infectcities!(g)

    g.actionsleft = g.settings.actions_per_turn
    if g.playerturn == g.settings.num_players
        g.playerturn = 1
        g.round += 1
        return true
    else
        g.playerturn += 1
        return false
    end
end
export endturn!

include("./Actions.jl")
export Actions

include("./Formatting.jl")

include("./Maps.jl")

using PrecompileTools

# Precompilation for speedup
@compile_workload begin
    map = Pandemic.Maps.circle12()
    set = Settings(4, Pandemic.Introductory)
    g = Pandemic.newgame(map, set)
    checkstate(g)
end

end
