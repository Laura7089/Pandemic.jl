using Test
using Pandemic
using Pandemic: Formatting

@testset "formatting" begin
    Formatting.citycubes(testgame(), 1)
    Formatting.cityplayers(testgame(), 1)
    Formatting.city(testgame(), 1)
    Formatting.players(testgame())
    Formatting.summary(testgame())
end
