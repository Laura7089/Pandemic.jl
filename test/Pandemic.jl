using Pandemic

world1 = begin
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

testgame() = Game(
    world = world1,
    numplayers = 2,
    difficulty = Introductory,
)

@testset "cubesinplay" begin
    game = testgame()
    game.cubes = [0 3 0 0; 2 2 0 0]

    @test Pandemic.cubesinplay(game, Pandemic.Blue) == 5
    @test Pandemic.cubesinplay(game, Pandemic.Black) == 2
    @test Pandemic.cubesinplay(game, Pandemic.Yellow) == 0
end

@testset "checkstate" begin
    game = testgame()
    game.cubes = [Pandemic.CUBES_PER_DISEASE 0 0 0; 0 0 0 0]
    @test Pandemic.checkstate!(game) == Pandemic.Lost

    game = testgame()
    game.outbreaks = Pandemic.MAX_OUTBREAKS
    @test Pandemic.checkstate!(game) == Pandemic.Lost

    game = testgame()
    game.outbreaks = Pandemic.MAX_OUTBREAKS - 1
    game.drawpile = collect(1:20)
    @test Pandemic.checkstate!(game) == Pandemic.Playing

    game = testgame()
    game.diseases = [Pandemic.Cured for _ in instances(Pandemic.Disease)]
    @test Pandemic.checkstate!(game) == Pandemic.Won
end

@testset "infectcity!" begin
    begin
        game = testgame()
        Pandemic.infectcity!(game, city1)
    end

    # TODO: *way* more different scenarios need testing for this
end

@testset "epidemic!" begin
    begin
        game = testgame()
        # Remove starting cubes from the board
        game.cubes .= 0
        c1 = cityindex(game.world, city1)
        c2 = cityindex(game.world, city2)
        c3 = cityindex(game.world, city3)
        Pandemic.outbreak!(game, city2, Int64[])

        # City 2 is the place where the outbreak occurred, so no additional cubes are placed
        @test all(==(0), game.cubes[c2, :])
        # City 3 is not connected to city 2
        @test all(==(0), game.cubes[c3, :])
        # City 1 should have been overflowed into and thus have one black cube
        @test game.cubes[c1, :] == [1, 0, 0, 0]
    end
end
