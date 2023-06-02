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
    # Building station in a new city
    begin
        testgame = game()
        move_one!(testgame, 1, city2)
        loc = testgame.playerlocs[1]
        prehand = deepcopy(testgame.hands[1])
        # Give the correct card to the player
        append!(testgame.hands[1], loc)

        buildstation!(testgame, 1, loc)
        @test testgame.stations[loc]
        @test Pandemic.stationcount(testgame) == 2
        @test testgame.hands[1] == prehand
    end

    # Building station in the starter city (it should already have one)
    begin
        testgame = game()
        loc = testgame.playerlocs[1]
        # Give the correct card to the player
        append!(testgame.hands[1], loc)

        @test_throws "" buildstation!(testgame, 1, loc)
    end

    # Building station without the right card
    begin
        testgame = game()
        move_one!(testgame, 1, city2)
        loc = testgame.playerlocs[1]
        # Take away the card if the player has it
        inhand = findfirst(==(loc), testgame.hands[1])
        if !isnothing(inhand)
            popat!(testgame.hands[1], inhand)
        end

        @test_throws "" buildstation!(testgame, 1, loc)
    end

    # TODO: test other error cases as well
end

@testset "findcure!" begin
    # Ideal conditions
    begin
        testgame = game()
        # Give player only the needed cards to cure
        c = Pandemic.cityindex(testgame.world, city1)
        testgame.hands[1] = fill(c, Pandemic.CARDS_TO_CURE)
        # Push an unrelated card
        c2 = Pandemic.cityindex(testgame.world, city2)
        push!(testgame.hands[1], c2)
        # Make sure there's at least one blue cube in play
        testgame.cubes[c, Int(Pandemic.Blue)] += 1

        findcure!(testgame, 1, Pandemic.Blue)
        @test testgame.diseases[Int(Pandemic.Blue)] == Pandemic.Cured
        @test testgame.hands[1] == [c2]
    end

    # Too few cards, should throw
    begin
        testgame = game()
        # Give player too few cards to cure
        c = Pandemic.cityindex(testgame.world, city1)
        testgame.hands[1] = fill(c, Pandemic.CARDS_TO_CURE - 1)
        prehand = deepcopy(testgame.hands[1])

        @test_throws "" findcure!(testgame, 1, Pandemic.Blue)
        @test testgame.diseases[Int(Pandemic.Blue)] != Pandemic.Cured
        @test testgame.hands[1] == prehand
    end
end

@testset "shareknowledge!" begin
end
@testset "treatdisease!" begin
end
@testset "advance!" begin
end
