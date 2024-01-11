module ToggleMenus

export ToggleMenu

using REPL.TerminalMenus

mutable struct ToggleMenu <: TerminalMenus._ConfiguredMenu{TerminalMenus.Config}
    options::Vector{S} where S <: AbstractString
    pagesize::Int
    pageoffset::Int
    settings::Vector{Char}
    selections::Vector{Char}
    initial::Vector{Char}
    icons::Vector{Char}
    config::TerminalMenus.Config
end

function ToggleMenu(options::Vector{S} where S <: AbstractString,
                    settings::Vector{Char},
                    initial::Vector{Char},
                    pagesize=10,
                    kwargs...)
    selections = copy(initial)
    icons = copy(settings)
    ToggleMenu(options, pagesize, 0, settings, selections, initial, icons, TerminalMenus.Config(kwargs...))
end

function ToggleMenu(options::Vector{S} where S <: AbstractString,
                    settings::Vector{Char},
                    pagesize=10,
                    kwargs...)
    initial = fill(settings[1], length(options))
    ToggleMenu(options, settings, initial, pagesize, kwargs...)
end

function TerminalMenus.header(menu::ToggleMenu)
    "A ToggleMenu"
end

TerminalMenus.pick(::ToggleMenu, ::Int)::Bool = true

TerminalMenus.cancel(menu::ToggleMenu) = menu.selections = Vector{Char}('\0', length(menu.options))

TerminalMenus.numoptions(menu::ToggleMenu) = length(menu.options)

function TerminalMenus.writeline(buf::IOBuffer, menu::ToggleMenu, idx::Int, cursor::Bool)
    print(buf, '[', menu.selections[idx], ']', ' ')
    print(buf, replace(menu.options[idx], "\n" => "\\n"))
end

function TerminalMenus.keypress(menu::ToggleMenu, i::UInt32)
    false
end

function TerminalMenus.selected(menu::ToggleMenu)
    return menu.selections
end

end
