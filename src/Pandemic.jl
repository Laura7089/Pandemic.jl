module Pandemic

include("./parameters.jl")
include("./world.jl")

using Random
using Parameters

"""
    popmany!(c, n)

`pop!`s `n` elements from collection `c`.

If `c` is too small, this function will `pop!` as many elements as it can.
"""
# Thanks to https://stackoverflow.com/questions/68997862/pop-multiple-items-from-julia-vector
popmany!(c, n) = (pop!(c) for _ = 1:min(n, length(c)))

@enum PlayerAction begin
    Move
    BuildStation
    TreatDisease
    ShareKnowledge
    DiscoverCure
end

@enum PlayerMove begin
    DriveSail
    DirectFlight
    CharterFlight
    ShuttleFlight
end

@enum DiseaseState begin
    Spreading
    Cured
    Eradicated
end

@enum GameState begin
    Won
    Lost
    Playing
end

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
    hands::Vector{Vector{Int}} = Int[]
    infectiondeck::Vector{Int} = collect(1:length(world))
    infectiondiscard::Vector{Int} = Int[]
    # NOTE: a 0 denotes an epidemic card
    drawpile::Vector{Int} = Int[]

    # Global state
    diseases::Vector{DiseaseState} = [Spreading for _ = 1:length(instances(Disease))]
    infectionrate_index::Int = 1
    outbreaks::Int = 0

    playerturn::Int = 1
    round::Int = 1
    state::GameState = Playing
end

function setupgame!(game)
    @debug("Dealing hands")
    playercards = collect(1:length(game.world))
    shuffle!(game.rng, playercards)
    handsize = 6 - game.numplayers
    for i = 1:game.numplayers
        push!(game.hands, collect(popmany!(playercards, handsize)))
    end

    @debug("Placing disease cubes")
    shuffle!(game.rng, game.infectiondeck)
    for level in reverse(1:3)
        for city in popmany!(game.infectiondeck, 3)
            game.cubes[city, Int(game.world.cities[city].colour)] += level
            push!(game.infectiondiscard, city)
        end
    end
    validatecubes(game)

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
    @assert(length(playercards) == 0)
end

"""
    newgame(world, difficulty, numplayers[, rng])

Create a new game and set it up for the first turn.
"""
function newgame(world, difficulty, numplayers, rng = MersenneTwister())
    game = Game(world = world, difficulty = difficulty, numplayers = numplayers, rng = rng)
    setupgame!(game)
    return game
end
export newgame

"""
    validatecubes(game)

Assert that the cube totals in `game` are valid.

Throw an error if not.
"""
function validatecubes(game::Game)
    for disease in instances(Disease)
        @assert cubesinplay(game, disease) <= CUBES_PER_DISEASE
    end
end

"""
    stationcount(game)

Count the number of stations in play.
"""
function stationcount(game::Game)::Int
    length(filter(x -> x, game.stations))
end

"""
    cubesinplay(game, colour)

Count the number of cubes of `colour` in play.
"""
function cubesinplay(game::Game, d::Disease)::Int
    sum(game.cubes[:, Int(disease)])
end

include("./Actions.jl")

end
