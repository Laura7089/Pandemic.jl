using Pandemic

@testset "cubesinplay" begin
    game = testgame()
    game.cubes = [0 3 0 0; 2 2 0 0]

    @test Pandemic.cubesinplay(game, Pandemic.Blue) == 5
    @test Pandemic.cubesinplay(game, Pandemic.Black) == 2
    @test Pandemic.cubesinplay(game, Pandemic.Yellow) == 0
end

@testset "checkstate" begin
    game = testgame()
    game.cubes = [game.settings.cubes_per_disease 0 0 0; 0 0 0 0]
    @test Pandemic.checkstate(game) == Pandemic.Lost

    game = testgame()
    game.outbreaks = game.settings.max_outbreaks
    @test Pandemic.checkstate(game) == Pandemic.Lost

    game = testgame()
    game.outbreaks = game.settings.max_outbreaks - 1
    game.drawpile = collect(1:20)
    @test Pandemic.checkstate(game) == Pandemic.Playing

    game = testgame()
    game.diseases = [Pandemic.Cured for _ in instances(Pandemic.Disease)]
    @test Pandemic.checkstate(game) == Pandemic.Won
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
