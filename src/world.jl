using Graphs

"""
    City{I}

A city in the game world.

`id` cannot be of type `Int`.
"""
struct City
    id::Any
    colour::Disease
end
export City

"""
    World

The cities and transit links on the world map.
"""
mutable struct World
    cities::Vector{City}
    graph::SimpleGraph{Int64}
    start::Int
end
export World

Base.length(w::World) = length(w.cities)

"""
    World(city)

Construct a [`World`](@ref) with one [`City`](@ref).
"""
function World(city::City)
    graph = SimpleGraph()
    add_vertex!(graph)
    return World([city], graph, 1)
end

"""
    startcity!(world, city)

Set the starting location of `world` to be `city`.
"""
function startcity!(world, i::Int)
    world.start = i
end
function startcity!(world, c)
    world.start = cityindex(world, c)
end

"""
    cityindexunchecked(world, id)

Get the index of a [`City`](@ref) into `world.cities` and `world.graph`.

Returns `nothing` if the city isn't found.
"""
function cityindexunchecked(world::World, id)
    findfirst(c -> c.id == id, world.cities)
end
function cityindexunchecked(world::World, city::City)
    findfirst(c -> c.id == city.id, world.cities)
end

"""
    cityindex(world, city[, error])

Get the index of a [`City`](@ref) into `world.cities` and `world.graph`.

Throws an error if the city isn't found.
Pass the parameter `error` to override the error text.
"""
function cityindex(world::World, c, e = "City $(c) not found")
    i = cityindexunchecked(world, c)
    @assert i != nothing e
    return i
end
# Convenience method:
# integers are not valid ids so we assume c is the index and return it
cityindex(w::World, c::Int, e = "") = c
export cityindex

"""
    getcity(world, city)
    getcity(world, id)

Gets a tuple of `(index, city)` from a `city` or `id` object.

Uses [`cityindex`](@ref) under the hood.
"""
function getcity(world::World, city)::Tuple{Int,City}
    c = cityindex(world, city)
    city = world.cities[c]
    return (c, city)
end
export getcity

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
# TODO: check if ID is already in use?
function addcity!(world::World, city::City, links_to = [])
    # Check if city already exists
    if cityindexunchecked(world, city) != nothing
        throw(error("City '$(city.id)' already placed in the world"))
    end

    if !(add_vertex!(world.graph))
        throw(error("Graph.jl error adding '$(city.id)'"))
    end
    push!(world.cities, city)
    my_id = length(world.cities)

    for link in links_to
        other_id = cityindex(world, link, "Can't link to '$(link.id)' which doesn't exist")

        if my_id == other_id
            @warn("City '$(city.id)' tried to link to itself")
            continue
        end
        add_edge!(world.graph, my_id, other_id)
    end

    return my_id
end
export addcity!
