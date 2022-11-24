using Pandemic

@testset "cubesinplay" begin
    city1 = City("city1", Pandemic.Blue)
    city2 = City("city2", Pandemic.Black)
    world1 = World(city1)
    addcity!(world1, city2, [city1])
    game1 = Game(
        world = deepcopy(world1),
        numplayers = 2,
        difficulty = Introductory,
        cubes = [0 3 0 0; 2 2 0 0],
    )

    @test Pandemic.cubesinplay(deepcopy(game1), Pandemic.Blue) == 5
    @test Pandemic.cubesinplay(deepcopy(game1), Pandemic.Black) == 2
    @test Pandemic.cubesinplay(deepcopy(game1), Pandemic.Yellow) == 0
end
