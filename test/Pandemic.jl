using Pandemic

city1 = City("city1", Pandemic.Blue)
city2 = City("city2", Pandemic.Black)

world1 = World(city1)
addcity!(world1, city2, [city1])

game() = Game(
    world = deepcopy(world1),
    numplayers = 2,
    difficulty = Introductory,
)

@testset "cubesinplay" begin
    testgame = game()
    testgame.cubes = [0 3 0 0; 2 2 0 0]

    @test Pandemic.cubesinplay(testgame, Pandemic.Blue) == 5
    @test Pandemic.cubesinplay(testgame, Pandemic.Black) == 2
    @test Pandemic.cubesinplay(testgame, Pandemic.Yellow) == 0
end

@testset "checkstate" begin
    testgame = game()
    testgame.cubes = [Pandemic.CUBES_PER_DISEASE 0 0 0; 0 0 0 0]
    @test Pandemic.checkstate!(testgame) == Pandemic.Lost

    testgame = game()
    testgame.outbreaks = Pandemic.MAX_OUTBREAKS
    @test Pandemic.checkstate!(testgame) == Pandemic.Lost

    testgame = game()
    testgame.outbreaks = Pandemic.MAX_OUTBREAKS - 1
    testgame.drawpile = collect(1:20)
    @test Pandemic.checkstate!(testgame) == Pandemic.Playing

    testgame = game()
    testgame.diseases = [Pandemic.Cured for _ in instances(Pandemic.Disease)]
    @test Pandemic.checkstate!(testgame) == Pandemic.Won
end
