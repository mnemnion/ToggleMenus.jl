using Documenter
using DocumenterInterLinks
using ToggleMenus

links = InterLinks(
    "Julia" => (
        "https://docs.julialang.org/en/v1/",
        joinpath(@__DIR__, "src/inventories", "Julia.toml")
    ),
)

makedocs(
    sitename = "ToggleMenus",
    format = Documenter.HTML(),
    modules = [ToggleMenus],
    checkdocs =  :exports,
    plugins = [links,],
)

deploydocs(
    repo = "github.com/mnemnion/ToggleMenus.jl.git",
    branch="gh-pages",
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
