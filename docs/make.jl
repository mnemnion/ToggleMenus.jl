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
    pages = [
        "ToggleMenus" => "index.md",
        "Docstrings" => "docstrings.md",
    ],
)

deploydocs(
    repo = "github.com/mnemnion/ToggleMenus.jl.git",
    branch="gh-pages",
    devurl="dev",
    versions=["stable" => "v^", "v#.#"],
)
