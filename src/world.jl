using Graphs

"""
    City{I}

A city in the game world.

`id` cannot be of type `Int`.
If `id <: AbstractString`, then it is **case-insensitive**.
`City`s are considered to be equal iff their `id` fields are equal.
"""
struct City
    id::Any
    colour::Disease
end
export City

Base.:(==)(c1::City, c2::City) = c1.id == c2.id

"""
    World

The cities and transit links on the world map.
"""
struct World
    cities::Vector{City}
    graph::SimpleGraph{Int64}
    start::Int
end
export World

Base.length(w::World) = length(w.cities)

"""
    cityindexunchecked(world, id)

Get the index of a [`City`](@ref) into `world.cities` and `world.graph` from it's `id`.

Returns `nothing` if the city isn't found.
"""
function cityindexunchecked(world, id)
    findfirst(c -> c.id == id, world.cities)
end
function cityindexunchecked(world, id::AbstractString)
    findfirst(c -> lowercase(c.id) == lowercase(id), world.cities)
end
# Convenience method:"Los Angeles", ["San Francisco", "Chicago", "Mexico City", "Sydney"]),
# integers are not valid ids so we assume c is the index and return it
cityindexunchecked(world, id::Int) = id
cityindexunchecked(world, c::City) = cityindexunchecked(world, c.id)

"""
    cityindex(world, city[, error])

Get the index of a [`City`](@ref) into `world.cities` and `world.graph` from it's `id`.

Throws an error if the city isn't found.
Pass the parameter `error` to override the error text.
`id` may either be a [`City`](@ref) object or just some identifying object.
"""
function cityindex(world, c, e = "City $c not found")
    i = cityindexunchecked(world, c)
    @assert i != nothing e
    return i
end
export cityindex

"""
    getcity(world, city)
    getcity(world, id)

Gets a tuple of `(index, city)` from a `city` or `id` object.

Uses [`cityindex`](@ref) under the hood.
"""
function getcity(world, city)::Tuple{Int,City}
    c = cityindex(world, city)
    city = world.cities[c]
    return (c, city)
end
export getcity

"""
    WorldBuilder

Convenience struct to incrementally build a [`World`](@ref) (which is immutable).

Use the `start` field to set the index of the starting city.
Most other functions in this module which query [`World`](@ref) will work with this type too.

See also [`addcity!`](@ref).
"""
mutable struct WorldBuilder
    cities::Vector{City}
    graph::SimpleGraph{Int64}
    start::Int
end

"""
    WorldBuilder()

Get an empty [`WorldBuilder`](@ref) ready for use.
"""
function WorldBuilder()
    return WorldBuilder([], SimpleGraph(), 0)
end

"""
    finaliseworld(builder)

Consumes `builder` and produces an (immutable) [`World`](@ref) for use.

Throws an error if `builder.start` was never assigned to.
"""
function finaliseworld(builder)::World
    if builder.start == 0
        throw(error("`finaliseworld` called without setting a start city"))
    end
    return World(builder.cities, builder.graph, builder.start)
end

"""
    addcity!(builder, city[, links_to])

Add a [`City`](@ref) to the builder map, intended for human use.

The `links_to` parameter should be a list of [`City`](@ref) IDs.
Returns the numeric id given to the city.

Throws an error if:
- `city` is already in `builder`
- failure to add the city to the graph occurs
"""
# TODO: check if ID is already in use?
function addcity!(world::WorldBuilder, city::City, links_to = [])
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
        other_id = cityindexunchecked(world, link)

        if other_id == nothing
            @error "City tried to link to a non-existent city, skipping" city.id link
            continue
        end
        if my_id == other_id
            @error "City tried to link to itself, skipping" city.id
            continue
        end

        add_edge!(world.graph, my_id, other_id)
    end

    return my_id
end

# TODO: better type signature
"""
    World(cities, start = 1)

Construct a [`World`](@ref) with the given `cities`.

`cities` should be a collection of triples (city id, disease, linked cities).
`start` should be an index (into `cities`) or id of the city which players will start in.
Uses [`WorldBuilder`](@ref) under the hood.
"""
function World(cities, start = 1)::World
    builder = WorldBuilder()
    for (id, disease, links) in cities
        c = City(id, Disease(disease))
        addcity!(builder, c, links)
        @debug "City added" city = c builder.cities
    end
    builder.start = start
    return finaliseworld(builder)
end
Graphs.neighbors(world::World, c) = Graphs.neighbors(world.graph, c)
Graphs.neighbors(world::World, c::City) = Graphs.neighbors(world.graph, cityindex(world, c))
