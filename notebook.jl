### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ c09c853d-2da1-41cd-b9dc-3c00d6a6c787
# ╠═╡ show_logs = false
begin
	# Note:
	# We're setting up a new environment every time this is run, which is not great :/
	# However, the alternatives (as far as I can tell) seem to be:
	# - pollute the environment of my Pandemic package or
	# - set up a totally new persistent env
	# neither of which I want to do
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add("WGLMakie")
	Pkg.add("GraphMakie")
	Pkg.add("Random")
	Pkg.add(path=".")
	using Pandemic
	using Random
	using WGLMakie, GraphMakie
end

# ╔═╡ 59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╠═╡ show_logs = false
worldmap = include("./maps/worldmapfull.jl")

# ╔═╡ 4029224d-2bb7-45dd-86da-4706505a4de0
rng = MersenneTwister()

# ╔═╡ d2bd0f36-bb82-4674-acea-cd409e7fea01
game = newgame(worldmap, Introductory, 1, rng)

# ╔═╡ 3db533f5-7429-4804-a20a-6168055b631e
begin
	g = graphplot(
		game.world.graph,
	)
end

# ╔═╡ Cell order:
# ╠═c09c853d-2da1-41cd-b9dc-3c00d6a6c787
# ╟─59c55dde-1338-47ee-8d7e-a686e7eb56bd
# ╟─4029224d-2bb7-45dd-86da-4706505a4de0
# ╟─d2bd0f36-bb82-4674-acea-cd409e7fea01
# ╠═3db533f5-7429-4804-a20a-6168055b631e
