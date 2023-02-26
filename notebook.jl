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
	using Random
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

# ╔═╡ 3f377642-c059-47ac-9684-e8b029ab7b4b
md"""
## Setup
"""

# ╔═╡ 2a1691ca-f4b5-412b-bdf8-96e94280934a
begin
	maps_options = glob("maps/*.jl")
	md"""
	Select a map script to load:
	$(@bind mapfile Select(maps_options))
	"""
end

# ╔═╡ c1426063-4a70-42c1-acbf-9889d22c9b69
function citylabelstring(game::Game, c)::String
	cube_chars = Dict(
		Pandemic.Blue => "🟦",
		Pandemic.Black => "◼️",
		Pandemic.Red => "🟥",
		Pandemic.Yellow => "🟨",
	)
	city = game.world.cities[c]
	label = city.id * " "
	for (disease, emoji) in cube_chars
		if (numcubes = game.cubes[c, Int(disease)]) != 0
			label = label * repeat(emoji, numcubes)
		end
	end
	label
end

# ╔═╡ 8825f3cc-0cbd-4050-b984-7777040f898d
function plotmap(game::Game, cubes = true)
	colours = [String(Symbol(c.colour)) for c in game.world.cities]
	labels = if cubes
		[
			c.id * " " * repeat("▪️", game.cubes[ci, Int(c.colour)])
			for (ci, c) in enumerate(game.world.cities)
		]
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

# ╔═╡ 60beac5c-3b6e-49dc-ba02-639eed085c47
function printcubes(game::Game)
	for c in range(1, length(game.world.cities))
		if sum(game.cubes[c, :]) != 0
			println(citylabelstring(game, c))
		end
	end
end

# ╔═╡ 2bedf5c9-7717-49dd-a730-3d512ace7f4c
md"""
### Starting Position
"""

# ╔═╡ fbcf2a42-b36f-4a2e-99b4-cfd880a607d5
md"""
Rerun game setup, including map loading: $(@bind restartgame PlutoUI.Button("Regenerate"))
"""

# ╔═╡ 59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╠═╡ show_logs = false
begin
	restartgame
	worldmap = include(mapfile)
	rng = MersenneTwister()
	game = newgame(worldmap, Introductory, 1, rng)
end

# ╔═╡ 3db533f5-7429-4804-a20a-6168055b631e
plotmap(game, false)

# ╔═╡ 77196933-ea0b-4cfe-9aa8-64c800b3a3b4
printcubes(game)

# ╔═╡ Cell order:
# ╠═c09c853d-2da1-41cd-b9dc-3c00d6a6c787
# ╟─4e99c094-397a-42a8-b2b0-658a1ac52a99
# ╟─3f377642-c059-47ac-9684-e8b029ab7b4b
# ╟─2a1691ca-f4b5-412b-bdf8-96e94280934a
# ╟─59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╟─c1426063-4a70-42c1-acbf-9889d22c9b69
# ╟─8825f3cc-0cbd-4050-b984-7777040f898d
# ╠═60beac5c-3b6e-49dc-ba02-639eed085c47
# ╟─2bedf5c9-7717-49dd-a730-3d512ace7f4c
# ╠═3db533f5-7429-4804-a20a-6168055b631e
# ╠═77196933-ea0b-4cfe-9aa8-64c800b3a3b4
# ╟─fbcf2a42-b36f-4a2e-99b4-cfd880a607d5
