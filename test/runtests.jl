using Test

using Pandemic

WORLD1 = begin
    city1 = City("city1", Pandemic.Blue)
    city2 = City("city2", Pandemic.Black)
    city3 = City("city3", Pandemic.Blue)

    b = Pandemic.WorldBuilder()
    Pandemic.addcity!(b, city1)
    Pandemic.addcity!(b, city2, ["city1"])
    Pandemic.addcity!(b, city3, ["city1"])
    b.start = 1
    Pandemic.finaliseworld(b)
end

testgame() = Game(world = WORLD1, settings = Pandemic.Settings(2, Introductory))
testgamesetup(;world=WORLD1) = newgame(world, Pandemic.Settings(2, Introductory))

include("./Pandemic.jl")
include("./Actions.jl")
include("./Formatting.jl")
