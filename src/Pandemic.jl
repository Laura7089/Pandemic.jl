module Pandemic

include("./parameters.jl")
include("./world.jl")

using Random

mutable struct Game{R<:AbstractRNG}
    rng::R
    world::World
    diseasecubes::Vector{Int}
end

end
