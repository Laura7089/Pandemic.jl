module Pandemic

include("./parameters.jl")
include("./world.jl")

using Random

"""
    popmany!(c, n)

`pop!`s `n` elements from collection `c`.

If `c` is too small, this function will `pop!` as many elements as it can.
"""
# Thanks to https://stackoverflow.com/questions/68997862/pop-multiple-items-from-julia-vector
popmany!(c, n) = (pop!(c) for _ in 1:min(n, length(c)))

mutable struct Game{R<:AbstractRNG}
    rng::R
    world::World
    difficulty::Difficulty
    numplayers::Int

    # Map objects
    cubes::Vector{Int}
    stations::Vector{Bool}
    playerlocs::Vector{Int}

    # Cards
    hands::Vector{Vector{Int}}
    infectiondeck::Vector{Int}
    infectiondiscard::Vector{Int}
    # NOTE: a 0 denotes an epidemic card
    drawpile::Vector{Int}

    # Global state
    infectionrate_index::Int
    outbreaks::Int
    cures::Dict{Disease,Bool}
end

"""
    Game(world, difficulty, numplayers[, rng])

Create a new game, **not setup**.
"""
function Game(world, difficulty, numplayers, rng = MersenneTwister())
    n = length(world.cities)
    stations = [false for _ in 1:n]
    stations[world.startpoint] = true
    Game(
        rng,
        world,
        difficulty,
        numplayers,
        zeros(Int, n),
        stations,
        vec(repeat([world.startpoint], numplayers)),
        Vector{Vector{Int}}(undef, (0,)),
        collect(1:n),
        Vector{Int}(undef, (0,)),
        Vector{Int}(undef, (0,)),
        1,
        0,
        Dict{Disease, Bool}(),
    )
end

function setupgame!(game)
    numepidemics = Int(game.difficulty)
    shuffle!(game.infectiondeck)
    numcities = length(game.world)

    # deal hands
    playercards = collect(1:numcities)
    handsize = 6 - game.numplayers
    for i in 1:game.numplayers
        push!(game.hands, collect(popmany!(playercards, handsize)))
    end

    # place start cubes
    for level in reverse(1:3)
        for city in popmany!(game.infectiondeck, 3)
            game.cubes[city] += level
            push!(game.infectiondiscard, city)
        end
    end
    validatecubes(game)

    # prepare draw pile
    numpiles = Int(game.difficulty)
    subpilesize = Int(length(playercards) // numpiles)
    for _ in 1:numpiles
        pile = collect(popmany!(playercards, subpilesize))
        push!(pile, 0)
        shuffle!(pile)
        game.drawpile = vcat(game.drawpile, pile)
    end
    @assert(length(playercards) == 0)
end

"""
    setupgame(world, difficulty, numplayers[, rng])

Create a new game and set it up.
"""
function setupgame(world, difficulty, numplayers, rng = MersenneTwister())
    game = Game(world, difficulty, numplayers, rng)
    setupgame!(game)
    return game
end
export setupgame

"""
    validatecubes(game)

Assert that the cube totals are valid in `game`.

Throw an error if not.
"""
function validatecubes(game)
    for disease in instances(Disease)
        indices = findall(c -> c.colour == disease, game.world.cities)
        @assert(sum(getindex.(Ref(game.cubes), indices)) <= CUBES_PER_DISEASE)
    end
end

end
