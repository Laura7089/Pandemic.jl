using Graphs

"""
    City

A city in the game world.
"""
mutable struct City
    id::Any
    colour::Disease
    researchstation::Bool
    diseasecubes::Int
end
"""
    City(id, colour)

Create a new city with the given params, without a station or any disease cubes.
"""
City(id, colour) = City(id, colour, false, 0)
export City

"""
    World

Information about the cities (and their status) and transit links in the world.
"""
mutable struct World
    cities::Vector{City}
    graph::SimpleGraph{Int64}
    infectionrate_index::Int
    outbreaks::Int
end
export World

"""
    cityindex(world, id)

Get the index of a [`City`](@ref) into `world.cities` and `world.graph` by it's `id`.
"""
function cityindex(world::World, id)
    findfirst(c -> c.id == id, world.cities)
end
"""
    cityindex(world, city)

Get the index of a [`City`](@ref) into `world.cities` and `world.graph`.
"""
function cityindex(world::World, city::City)
    findfirst(c -> c.id == city.id, world.cities)
end
export cityindex

"""
    World()

Construct an Empty [`World`](@ref).
"""
function World()
    return World([], SimpleGraph())
end

"""
    addcity!(world, city[, links_to])

Add a [`City`](@ref) to the world map, intended for human use.

The `links_to` parameter should be a list of [`City`](@ref) IDs.
Returns the numeric id given to the city.

Throws an error if:
- `city` is already in `world`
- any item in `links_to` isn't in the world
- failure to add the city to the graph occurs
"""
function addcity!(world::World, city::City, links_to = [])
    # Check if city already exists
    if cityindex(world, city) != nothing
        throw(error("City '$(city.id)' already placed in the world"))
    end

    if !(add_vertex!(world.graph))
        throw(error("Graph.jl error adding '$(city.id)'"))
    end
    push!(world.cities, city)
    my_id = length(world.cities)

    for link in links_to
        other_id = cityindex(world, link)
        if other_id == nothing
            throw(error("Can't link to '$(link.id)' which doesn't exist"))
        end

        if my_id == other_id
            @warn("City '$(city.id)' tried to link to itself")
            continue
        end
        add_edge!(world.graph, my_id, cityindex(world, link))
    end

    return my_id
end
export addcity!
