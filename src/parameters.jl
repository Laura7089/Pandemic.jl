"""
    Disease

An [`@enum`](@ref) of all diseases in the game.

Int values must ascend from 1.
"""
@enum Disease begin
    Black = 1
    Blue = 2
    Red = 3
    Yellow = 4
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

const global STARTING_CARDS = Dict(4 => 2, 3 => 3, 2 => 4)

const global CUBES_PER_DISEASE = 24
const global MAX_STATIONS = 6
const global INFECTION_RATES = [2, 2, 2, 3, 3, 4, 4]
const global OUTBREAK_THRESHOLD = 3
const global CARDS_TO_CURE = 5

"""
The number of outbreaks which signals game over.
"""
const global MAX_OUTBREAKS = 8
