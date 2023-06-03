using Pandemic
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

testgame() = Game(
    world = deepcopy(world1),
    settings = Pandemic.Settings(
        num_players = 2,
        difficulty = Introductory,
    ),
)

@testset "moving" begin
    game = testgame()
    move_one!(game, 1, city2)
    @test game.playerlocs[1] == 2
    @test_throws "" move_one!(game, 2, city3)

    game = testgame()
    push!(game.hands[1], 3)
    move_direct!(game, 1, 3)
    @test game.playerlocs[1] == 3 && game.hands[1] == []
    @test_throws "" move_direct!(game, 2, 3)

    game = testgame()
    push!(game.hands[1], 1)
    move_chartered!(game, 1, 3)
    @test game.playerlocs[1] == 3 && game.hands[1] == []
    push!(game.hands[2], 2)
    @test_throws "" move_chartered!(game, 2, 3)

    game = testgame()
    game.stations[1] = game.stations[3] = true
    move_station!(game, 1, 3)
    @test game.playerlocs[1] == 3
    game.playerlocs[2] = 2
    @test_throws "" move_station!(game, 2, 3)
end

@testset "buildstation!" begin
    # Building station in a new city
    begin
        game = testgame()
        move_one!(game, 1, city2)
        loc = game.playerlocs[1]
        prehand = deepcopy(game.hands[1])
        # Give the correct card to the player
        append!(game.hands[1], loc)

        buildstation!(game, 1, loc)
        @test game.stations[loc]
        @test Pandemic.stationcount(game) == 2
        @test game.hands[1] == prehand
    end

    # Building station in the starter city (it should already have one)
    begin
        game = testgame()
        loc = game.playerlocs[1]
        # Give the correct card to the player
        append!(game.hands[1], loc)

        @test_throws "" buildstation!(game, 1, loc)
    end

    # Building station without the right card
    begin
        game = testgame()
        move_one!(game, 1, city2)
        loc = game.playerlocs[1]
        # Take away the card if the player has it
        inhand = findfirst(==(loc), game.hands[1])
        if !isnothing(inhand)
            popat!(game.hands[1], inhand)
        end

        @test_throws "" buildstation!(game, 1, loc)
    end

    # TODO: test other error cases as well
end

@testset "findcure!" begin
    # Ideal conditions
    begin
        game = testgame()
        # Give player only the needed cards to cure
        c = Pandemic.cityindex(game.world, city1)
        game.hands[1] = fill(c, game.settings.cards_to_cure)
        # Push an unrelated card
        c2 = Pandemic.cityindex(game.world, city2)
        push!(game.hands[1], c2)
        # Make sure there's at least one blue cube in play
        game.cubes[c, Int(Pandemic.Blue)] += 1

        findcure!(game, 1, Pandemic.Blue)
        @test game.diseases[Int(Pandemic.Blue)] == Pandemic.Cured
        @test game.hands[1] == [c2]
    end

    # Too few cards, should throw
    begin
        game = testgame()
        # Give player too few cards to cure
        c = Pandemic.cityindex(game.world, city1)
        game.hands[1] = fill(c, game.settings.cards_to_cure - 1)
        prehand = deepcopy(game.hands[1])

        @test_throws "" findcure!(game, 1, Pandemic.Blue)
        @test game.diseases[Int(Pandemic.Blue)] != Pandemic.Cured
        @test game.hands[1] == prehand
    end
end

@testset "advanceaction!" begin
    # Do nothing for a whole turn
    begin
        game = testgame()
        precubes = sum(game.cubes)
        for _ in 1:game.settings.actions_per_turn
            advanceaction!(game)
        end
        @test game.playerturn == 2
        @test sum(game.cubes) == precubes + game.settings.infection_rates[1]
    end
end

@testset "shareknowledge!" begin
end
@testset "treatdisease!" begin
end
@testset "advanceaction!" begin
end
@testset "endturn!" begin
end
