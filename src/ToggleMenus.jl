module ToggleMenus

export ToggleMenu, ToggleMenuMaker, makemenu

import REPL.TerminalMenus: AbstractMenu, Config, cancel, keypress, move_down!, move_up!,
    numoptions, pick, selected, writeline

using REPL.TerminalMenus

mutable struct ToggleMenuMaker
    settings::Vector{Char}
    icons::Dict{Char,Char}
    header::Union{AbstractString,Function}
    pagesize::Int
    config::Config
    # probably a header template? we'll get there
end

const StringVector = Vector{S} where S <: AbstractString

function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, pagesize=10, kwargs...)
    !allunique(settings) && error("all settings must be unique: $settings")
    icons = Dict{Char,Char}()
    for char in settings
        icons[char] = char
    end
    ToggleMenuMaker(settings, icons, header, pagesize, Config(kwargs...))
end


"""
    ToggleMenuMaker(header, settings, icons, pagesize=10, kwargs...)

Create a template for a ToggleMaker, which may be passed to `makemenu` along with a
set of options.

- `header`: A string, which should inform the user what the options do, or a
            function `header(m::ToggleMenu)::String`.
- `settings`: A `Vector{Char}`, every element must be unique, and should be easy to
              type.  Pressing a key corresponding to one of the settings will toggle
              that option directly to that setting.
- `icons`:  Optional `Vector{Char}`, if provided these must also be unique, and must
            have the same number of elements as `settings`.  These are used as the
            selection icons, which will default to `settings` if none are provided.
- `pagesize`:  Number of options to display before scrolling.
- `kwargs`:  Are passed through to TerminalMenus.Config, and may be used to configure
             aspects of menu presentation and behavior.  For more details consult the
             relevant docstring.
"""
function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, icons::Vector{Char}; pagesize=10, kwargs...)
    if length(settings) ≠ length(icons)
        throw(DimensionMismatch("settings and icons must have the same number of elements"))
    end
    !allunique(settings) && error("all settings must be unique: $settings")
    !allunique(icons) && error("all icons must be unique $icons")
    icodict = Dict{Char,Char}()
    for (idx,char) ∈ settings |> enumerate
        icodict[char] = icons[idx]
    end
    ToggleMenuMaker(settings, icodict, header, pagesize, Config(;kwargs...))
end


"""
    makemenu(maker::ToggleMenuMaker, options::StringVector)::ToggleMenu

Makes a `ToggleMenu`.  The `options` are a vector of strings which have states which
may be toggled through.
"""
makemenu(maker::ToggleMenuMaker, options::StringVector) = ToggleMenu(options, maker)

mutable struct ToggleMenu <: TerminalMenus._ConfiguredMenu{Config}
    options::StringVector
    settings::Vector{Char}
    selections::Vector{Char}
    icons::Dict{Char,Char}
    header::Union{AbstractString,Function}
    pagesize::Int
    pageoffset::Int
    cursor::Int
    config::Config
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    selections::Vector{Char},
                    icons::Dict{Char,Char},
                    header::Union{AbstractString,Function},
                    config::Config,
                    pagesize=10)
    ToggleMenu(options, settings, selections, icons, header, pagesize, 0, 1, config)
end

#=
function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    selections::Vector{Char},
                    pagesize=10,
                    kwargs...)
    icons = Dict{Char,Char}()
    for char in settings
        icons[char] = char
    end
    ToggleMenu(options, settings, selections, icons, pagesize, 0, 1, TerminalMenus.Config(kwargs...))
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    pagesize=10,
                    kwargs...)

    selections = fill(settings[1], length(options))
    ToggleMenu(options, settings, selections, pagesize, kwargs...)
end
=#

function ToggleMenu(options::StringVector, maker::ToggleMenuMaker)
    selections = fill(maker.settings[1], length(options))
    ToggleMenu(options, maker.settings, selections, maker.icons, maker.header, maker.config, maker.pagesize)
end

function TerminalMenus.header(menu::ToggleMenu)
    if menu.header isa Function
        menu.header(menu)
    else
        menu.header
    end
end

function move_up!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    m.cursor = invoke(move_up!, Tuple{AbstractMenu,Int,Int}, m, cursor, lastoption)
end

function move_down!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    m.cursor = invoke(move_down!, Tuple{AbstractMenu,Int,Int}, m, cursor, lastoption)
end

pick(::ToggleMenu, ::Int)::Bool = true

cancel(menu::ToggleMenu) = menu.selections = fill('\0', length(menu.options))

numoptions(menu::ToggleMenu) = length(menu.options)

function writeline(buf::IOBuffer, menu::ToggleMenu, idx::Int, cursor::Bool)
    print(buf, '[', menu.icons[menu.selections[idx]], ']', ' ')
    body = replace(menu.options[idx], "\n" => "\\n")
    print(buf, body)
end

function _nextselection(menu::ToggleMenu)
    current = menu.selections[menu.cursor]
    idx = findfirst(==(current), menu.settings)
    if idx == length(menu.settings)
        return menu.settings[1]
    else
        return menu.settings[idx + 1]
    end
end

function keypress(menu::ToggleMenu, i::UInt32)
    char = Char(i)
    if char == '\t'
        set = _nextselection(menu)
        menu.selections[menu.cursor] = set
    elseif char ∈ menu.settings
        menu.selections[menu.cursor] = char
    end
    return false
end

function selected(menu::ToggleMenu)
    return menu.selections
end

end
