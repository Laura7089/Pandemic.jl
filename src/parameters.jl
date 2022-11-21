@enum Disease begin
    black
    blue
    red
    yellow
end

@enum Difficulty begin
    introductory = 4
    normal = 5
    heroic = 6
end

const global STARTING_CARDS = Dict(4 => 2, 3 => 3, 2 => 4)

const global CUBES_PER_DISEASE = 24
const global PLAYER_LIMITS = (2, 4)
const global MAX_RESEARCH_STATIONS = 6
const global INFECTION_RATES = [2, 2, 2, 3, 3, 4, 4]

"""
The number of outbreaks which signals game over.
"""
const global MAX_OUTBREAKS = 8
