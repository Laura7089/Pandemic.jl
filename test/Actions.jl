using Pandemic.Actions

city1 = City("city1", Pandemic.Blue)
city2 = City("city2", Pandemic.Black)
city3 = City("city3", Pandemic.Blue)

world1 = begin
    b = Pandemic.WorldBuilder()
    b.start = 1
    Pandemic.addcity!(b, city1)
    Pandemic.addcity!(b, city2, [city1])
    Pandemic.addcity!(b, city3, [city2])
    Pandemic.finaliseworld(b)
end

game() = Game(
    world = deepcopy(world1),
    numplayers = 2,
    difficulty = Introductory,
)

@testset "moving" begin
    testgame = game()
    move_one!(testgame, 1, city2)
    @test testgame.playerlocs[1] == 2
    @test_throws "" move_one!(testgame, 2, city3)

    testgame = game()
    push!(testgame.hands[1], 3)
    move_direct!(testgame, 1, 3)
    @test testgame.playerlocs[1] == 3 && testgame.hands[1] == []
    @test_throws "" move_direct!(testgame, 2, 3)

    testgame = game()
    push!(testgame.hands[1], 1)
    move_chartered!(testgame, 1, 3)
    @test testgame.playerlocs[1] == 3 && testgame.hands[1] == []
    push!(testgame.hands[2], 2)
    @test_throws "" move_chartered!(testgame, 2, 3)

    testgame = game()
    testgame.stations[1] = testgame.stations[3] = true
    move_station!(testgame, 1, 3)
    @test testgame.playerlocs[1] == 3
    testgame.playerlocs[2] = 2
    @test_throws "" move_station!(testgame, 2, 3)
end

@testset "buildstation!" begin
end
@testset "findcure!" begin
end
@testset "shareknowledge!" begin
end
@testset "treatdisease!" begin
end
