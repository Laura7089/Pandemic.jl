using Parameters

"""
    Disease

An [`@enum`](@ref) of all diseases in the game.

Int values must ascend from 1.
"""
@enum Disease begin
    Black = 1
    Blue
    Red
    Yellow
end
const global CUBE_CHARS = Dict(
    Pandemic.Blue => "🟦",
    Pandemic.Black => "◼️",
    Pandemic.Red => "🟥",
    Pandemic.Yellow => "🟨",
)
function Base.show(io::IO, dis::Disease)
    if dis == Black
        write(io, "Black")
    elseif dis == Blue
        write(io, "Blue")
    elseif dis == Red
        write(io, "Red")
    elseif dis == Yellow
        write(io, "Yellow")
    end
end

"""
    Difficulty

An [`@enum`](@ref) of difficulties available in the game.

Int values describe how many epidemic cards they add.
"""
@enum Difficulty begin
    Introductory = 4
    Normal = 5
    Heroic = 6
end
export Introductory, Normal, Heroic

"""
    Settings(difficulty, num_players; kwargs)

Immutable struct containing parameters for [`Pandemic.Game`](@ref).

# Args

Available `kwargs` values, their defaults and meanings:

- `actions_per_turn` [4]: actions available to each player per turn
- `cards_to_cure` [5]: number of cards (of the correct colour) needed to cure a disease
- `cubes_per_disease` [24]: number of cubes available per disease ie. loss threshold for cubes in play
- `infection_rates` [[2, 2, 2, 3, 3, 4, 4]]: infection rate tracker for epidemics, should be an indexable collection
- `initial_infections` [[(3, 3), (3, 2), (3, 1)]]: numbers of initial infections, iterable of tuples `(ca, cu)` where `cu` cubes will be placed on `ca` randomly drawn cities
- `max_cubes_per_city` [3]: maximum number of cubes a city can hold ie. the outbreak threshold
- `max_hand` [7]: maximum cards a player can hold before they need to discard
- `max_outbreaks` [8]: number of outbreaks which signals game over
- `max_stations` [6]: maximum number of stations the map can hold
- `player_draw` [2]: number of player cards each player draws at the end of their turn
- `starting_hand` [6 - num_players]: number of cards each player starts with
"""
@with_kw struct Settings
    num_players::Any
    difficulty::Difficulty
    actions_per_turn = 4
    cards_to_cure = 5
    cubes_per_disease = 24
    infection_rates = [2, 2, 2, 3, 3, 4, 4]
    initial_infections = [(3, 3), (3, 2), (3, 1)]
    max_cubes_per_city = 3
    max_hand = 7
    max_outbreaks = 8
    max_stations = 6
    player_draw = 2
    starting_hand = 6 - num_players
end
Settings(np, d; kwargs...) = Settings(num_players = np, difficulty = d; kwargs...)
