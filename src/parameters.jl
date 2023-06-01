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

const global STARTING_HAND_OFFSET = 6

const global CUBES_PER_DISEASE = 24
const global MAX_STATIONS = 6
const global INFECTION_RATES = [2, 2, 2, 3, 3, 4, 4]
const global INITIAL_INFECTIONS = [(3, 3), (3, 2), (3, 1)]
const global CARDS_TO_CURE = 5
const global MAX_HAND = 7
const global ACTIONS_PER_TURN = 4
"""
    PLAYER_DRAW

The number of player cards each player draws at the end of their turn.
"""
const global PLAYER_DRAW = 2
"""
    MAX_CUBES_PER_CITY

The maximum number of cubes a city can hold and thus also the outbreak threshold.
"""
const global MAX_CUBES_PER_CITY = 3

"""
The number of outbreaks which signals game over.
"""
const global MAX_OUTBREAKS = 8
