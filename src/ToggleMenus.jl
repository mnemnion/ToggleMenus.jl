module ToggleMenus

export ToggleMenu, ToggleMenuMaker, makemenu

using REPL.TerminalMenus

mutable struct ToggleMenuMaker
    settings::Vector{Char}
    icons::Dict{Char,Char}
    pagesize::Int
    config::TerminalMenus.Config
    # probably a header template? we'll get there
end

const StringVector = Vector{S} where S <: AbstractString

function ToggleMenuMaker(settings::Vector{Char}, pagesize=10, kwargs...)
    icons = Dict{Char,Char}()
    for char in settings
        icons[char] = char
    end
    ToggleMenuMaker(settings, icons, pagesize, TerminalMenus.Config(kwargs...))
end

function ToggleMenuMaker(settings::Vector{Char}, icons::Vector{Char}, pagesize=10, kwargs...)
    if length(settings) ≠ length(icons)
        throw(DimensionMismatch("settings and icons must have the same number of elements"))
    end
    icodict = Dict{Char,Char}()
    for (idx,char) ∈ settings |> enumerate
        icodict[char] = icons[idx]
    end
    ToggleMenuMaker(settings, icodict, pagesize, TerminalMenus.Config(kwargs...))
end

makemenu(maker::ToggleMenuMaker, options::StringVector) = ToggleMenu(options, maker)

mutable struct ToggleMenu <: TerminalMenus._ConfiguredMenu{TerminalMenus.Config}
    options::StringVector
    pagesize::Int
    pageoffset::Int
    settings::Vector{Char}
    selections::Vector{Char}
    icons::Dict{Char,Char}
    config::TerminalMenus.Config
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    selections::Vector{Char},
                    pagesize=10,
                    kwargs...)
    icons = Dict{Char,Char}
    for char in settings
        icons[char] = char
    end
    ToggleMenu(options, pagesize, 0, settings, selections, icons, TerminalMenus.Config(kwargs...))
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    pagesize=10,
                    kwargs...)

    selections = fill(settings[1], length(options))
    ToggleMenu(options, settings, selections, pagesize, kwargs...)
end

function ToggleMenu(options::StringVector, maker::ToggleMenuMaker)
    selections = fill(maker.settings[1], length(options))
    ToggleMenu(options, maker.pagesize, 0, maker.settings, selections, maker.icons, maker.config)
end

function TerminalMenus.header(menu::ToggleMenu)
    "A ToggleMenu"
end

TerminalMenus.pick(::ToggleMenu, ::Int)::Bool = true

TerminalMenus.cancel(menu::ToggleMenu) = menu.selections = fill('\0', length(menu.options))

TerminalMenus.numoptions(menu::ToggleMenu) = length(menu.options)

function TerminalMenus.writeline(buf::IOBuffer, menu::ToggleMenu, idx::Int, ::Bool)
    print(buf, '[', menu.icons[menu.selections[idx]], ']', ' ')
    print(buf, replace(menu.options[idx], "\n" => "\\n"))
end

function TerminalMenus.keypress(menu::ToggleMenu, i::UInt32)
    false
end

function TerminalMenus.selected(menu::ToggleMenu)
    return menu.selections
end

end
