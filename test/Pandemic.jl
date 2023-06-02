using Pandemic

world1 = begin
    city1 = City("city1", Pandemic.Blue)
    city2 = City("city2", Pandemic.Black)

    b = Pandemic.WorldBuilder()
    Pandemic.addcity!(b, city1)
    Pandemic.addcity!(b, city2, ["city1"])
    b.start = 1
    Pandemic.finaliseworld(b)
end

game() = Game(
    world = world1,
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

@testset "infectcity!" begin
    begin
        testgame = game()
        Pandemic.infectcity!(testgame, city1)
    end

    # TODO: *way* more different scenarios need testing for this
end
