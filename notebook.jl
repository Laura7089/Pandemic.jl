### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ c09c853d-2da1-41cd-b9dc-3c00d6a6c787
# ╠═╡ show_logs = false
begin
	# Note: this cell must be run first
	import Pkg
	Pkg.activate("./.notebook_env")
	Pkg.add("PlutoUI")
	Pkg.add("Glob")
	Pkg.add("WGLMakie")
	Pkg.add("JSServe")
	Pkg.add("GraphMakie")
	Pkg.add("Random")
	Pkg.add("NetworkLayout")
	Pkg.add(path=".")
	using Pandemic
	using Random, Serialization
	using PlutoUI
	using Glob
	using WGLMakie, GraphMakie, JSServe
	import NetworkLayout
	Page()
end

# ╔═╡ 4e99c094-397a-42a8-b2b0-658a1ac52a99
md"""
# Pandemic and AIs

This is a notebook intended to let one play with and test the Pandemic.jl library.
Functionality will be added to allow one to select different AIs and evaluate their characteristics.
"""

# ╔═╡ b30b68f9-82f3-4e83-9b79-863e872a19a1
md"""
$(@bind restartgame PlutoUI.Button("Rerun Setup/Map Scripts"))
$(@bind clearstate PlutoUI.Button("Reset to Defaults"))
"""

# ╔═╡ 2a1691ca-f4b5-412b-bdf8-96e94280934a
begin
	clearstate
	md"""
	## Setup
	
	Game state: $(@bind state FilePicker())
	"""
end

# ╔═╡ 503d0c6f-646c-4488-bd97-242805336f9f
if state == nothing
	restartgame
	maps_options = glob("maps/*.jl")
	md"""
	Select a map script to load:
	$(@bind mapfile Select(maps_options))

	Seed (integer, leave blank for random): $(@bind seed PlutoUI.TextField(default="111"))
	"""
else
	md"""
	*Saved game state provided, seed/map disabled*
	"""
end

# ╔═╡ 59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╠═╡ show_logs = false
game = if isnothing(state)
	worldmap = include(mapfile)
	rng = MersenneTwister(if seed == "" 
		nothing
	else
		parse(Int, seed)
	end)
	newgame(worldmap, Introductory, 1, rng)
else
	deserialize(IOBuffer(state["data"]))
end

# ╔═╡ 60beac5c-3b6e-49dc-ba02-639eed085c47
begin
	import Pandemic: Formatting
	function printextracityinfo(game::Game)
		for c in 1:length(game.world.cities)
			if sum(game.cubes[c, :]) != 0
				println(Pandemic.Formatting.city(game, c))
			end
		end
	end
end

# ╔═╡ 8825f3cc-0cbd-4050-b984-7777040f898d
function plotmap(game::Game; extrainfo = false)
	colours = [String(Symbol(c.colour)) for c in game.world.cities]
	labels = if extrainfo
		[citylabel(game, ci) for (ci, _) in enumerate(game.world.cities)]
	else
		[c.id for c in game.world.cities]
	end
	graphplot(
		game.world.graph,
		layout = NetworkLayout.Stress(),
		node_color = colours, 
		nlabels = labels,
		nlabels_distance = 5,
		nlabels_fontsize = 12,
	)
end

# ╔═╡ 2bedf5c9-7717-49dd-a730-3d512ace7f4c
md"""
### Starting Position
"""

# ╔═╡ 3db533f5-7429-4804-a20a-6168055b631e
plotmap(game)

# ╔═╡ 77196933-ea0b-4cfe-9aa8-64c800b3a3b4
printextracityinfo(game)

# ╔═╡ d30ba5a4-d2ae-4421-bde1-1b933f1e4936
begin
	buf = IOBuffer()
	serialize(buf, game)
	stateraw = take!(buf)
	md"""
	Save start state: $(DownloadButton(stateraw, "game.obj"))
	"""
end

# ╔═╡ Cell order:
# ╠═c09c853d-2da1-41cd-b9dc-3c00d6a6c787
# ╟─4e99c094-397a-42a8-b2b0-658a1ac52a99
# ╟─2a1691ca-f4b5-412b-bdf8-96e94280934a
# ╟─b30b68f9-82f3-4e83-9b79-863e872a19a1
# ╟─503d0c6f-646c-4488-bd97-242805336f9f
# ╟─59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╠═60beac5c-3b6e-49dc-ba02-639eed085c47
# ╟─8825f3cc-0cbd-4050-b984-7777040f898d
# ╟─2bedf5c9-7717-49dd-a730-3d512ace7f4c
# ╠═3db533f5-7429-4804-a20a-6168055b631e
# ╠═77196933-ea0b-4cfe-9aa8-64c800b3a3b4
# ╟─d30ba5a4-d2ae-4421-bde1-1b933f1e4936
