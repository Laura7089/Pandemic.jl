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

@with_kw mutable struct Game{R<:AbstractRNG}
    world::World
    difficulty::Difficulty
    numplayers::Int

    rng::R = MersenneTwister()

    # Map objects
    cubes::Vector{Int} = zeros(Int, length(world))
    stations::Vector{Bool} = [i == world.start for i = 1:length(world)]
    playerlocs::Vector{Int} = [world.start for _ = 1:numplayers]

    # Cards
    hands::Vector{Vector{Int}} = Int[]
    infectiondeck::Vector{Int} = collect(1:length(world))
    infectiondiscard::Vector{Int} = Int[]
    # NOTE: a 0 denotes an epidemic card
    drawpile::Vector{Int} = Int[]

    # Global state
    infectionrate_index::Int = 1
    outbreaks::Int = 0
    cured::Dict{Disease,Bool} = Dict()
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
            game.cubes[city] += level
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
export setupgame

"""
    validatecubes(game)

Assert that the cube totals in `game` are valid.

Throw an error if not.
"""
function validatecubes(game)
    for disease in instances(Disease)
        indices = findall(c -> c.colour == disease, game.world.cities)
        @assert(sum(getindex.(Ref(game.cubes), indices)) <= CUBES_PER_DISEASE)
    end
end

end
