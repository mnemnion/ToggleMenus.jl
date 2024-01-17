using Documenter
using ToggleMenus

makedocs(
    sitename = "ToggleMenus",
    format = Documenter.HTML(),
    modules = [ToggleMenus],
    checkdocs =  :exports,
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
