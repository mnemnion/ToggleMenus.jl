module ToggleMenus

using StringManipulation

export ToggleMenu, ToggleMenuMaker, makemenu

import REPL.TerminalMenus: AbstractMenu, Config, cancel, keypress, move_down!, move_up!,
    numoptions, pick, selected, writeline

using REPL.TerminalMenus

mutable struct ToggleMenuMaker
    settings::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    pagesize::Int
    config::Config
    # probably a header template? we'll get there
end

const StringVector = Vector{S} where S <: AbstractString

function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, pagesize=10; kwargs...)
   !allunique(settings) && error("all settings must be unique: $settings")
    icons = Dict{Char,Union{String,Char}}()
    iconwidth = reduce(max, map((x) -> printable_textwidth(string(x)), settings))
    for char in settings
        if char == '\0'
            icons[char] = " "^iconwidth
        else
            icons[char] = char
        end
    end
    settings = [x for x in settings if x != '\0']
    ToggleMenuMaker(settings, icons, header, pagesize, Config(;kwargs...))
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
function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, icons::Vector{Char}, pagesize=10; kwargs...)
    if length(settings) ≠ length(icons)
        throw(DimensionMismatch("settings and icons must have the same number of elements"))
    end
    !allunique(settings) && error("all settings must be unique: $settings")
    !allunique(icons) && error("all icons must be unique $icons")
    icodict = Dict{Char,Union{String,Char}}()
    for (idx,char) ∈ settings |> enumerate
        icodict[char] = icons[idx]
    end
    settings = [x for x in settings if x != '\0']
    ToggleMenuMaker(settings, icodict, header, pagesize, Config(; kwargs...))
end


"""
    makemenu(maker::ToggleMenuMaker, options, selections)::ToggleMenu

Makes a `ToggleMenu`.  The `options` are a vector of strings which have states which
may be toggled through. `selections` is an optional Vector of initial selected states
for the options, if a selection is `\0` the menu will skip that line and it will not
be togglable
"""
makemenu(maker::ToggleMenuMaker, options::StringVector) = ToggleMenu(options, maker)

function makemenu(maker::ToggleMenuMaker, options::StringVector, selections::Vector{Char})
    all(==('\0'), selections) && error("At least one selection must not be '\\0'")
    if '\0' ∈ selections && !haskey(maker.icons, '\0')
        iconwidth = reduce(max, map((x) -> printable_textwidth(string(x)), values(maker.icons)))
        maker.icons['\0'] = " "^iconwidth
    end
    return ToggleMenu(options, selections, maker)
end

mutable struct ToggleMenu <: TerminalMenus._ConfiguredMenu{Config}
    options::StringVector
    settings::Vector{Char}
    selections::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    pagesize::Int
    pageoffset::Int
    cursor::Int
    config::Config
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    selections::Vector{Char},
                    icons::Dict{Char,Union{String,Char}},
                    header::Union{AbstractString,Function},
                    config::Config,
                    pagesize=10)
    ToggleMenu(options, settings, selections, icons, header, pagesize, 0, 1, config)
end

function ToggleMenu(options::StringVector, maker::ToggleMenuMaker)
    selections = fill(maker.settings[1], length(options))
    ToggleMenu(options, maker.settings, selections, maker.icons, maker.header, maker.config, maker.pagesize)
end

function ToggleMenu(options::StringVector, selections::Vector{Char}, maker::ToggleMenuMaker)
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
    selected = m.selections[m.cursor]
    if selected == '\0'
        if length(m.options) == 1
            return cursor
        end
        if cursor != 1
            return move_up!(m, cursor - 1, lastoption)
        else
            return move_down!(m, cursor, lastoption)
        end
    else
        return m.cursor
    end
end

function move_down!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    m.cursor = invoke(move_down!, Tuple{AbstractMenu,Int,Int}, m, cursor, lastoption)
    selected = m.selections[m.cursor]
    if selected == '\0'
        if length(m.options) == 1
            return cursor
        end
        if cursor != lastoption
            return move_down!(m, cursor + 1, lastoption)
        else
            return move_up!(m, cursor, lastoption)
        end
    else
        return m.cursor
    end
end

pick(::ToggleMenu, ::Int)::Bool = true

cancel(menu::ToggleMenu) = menu.selections = fill('\0', length(menu.options))

numoptions(menu::ToggleMenu) = length(menu.options)

function writeline(buf::IOBuffer, menu::ToggleMenu, idx::Int, cursor::Bool)
    width = displaysize(stdout)[2]
    icon = menu.icons[menu.selections[idx]]
    width -= printable_textwidth(string(icon)) + 6
    print(buf, '[', icon, ']', ' ')
    body = fit_string_in_field(replace(menu.options[idx], "\n" => "\\n"), width)
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

function _prevselection(menu::ToggleMenu)
    current = menu.selections[menu.cursor]
    idx = findfirst(==(current), menu.settings)
    if idx == 1
        return menu.settings[end]
    else
        return menu.settings[idx - 1]
    end
end

keyvec = []  # TODO remove
function keypress(menu::ToggleMenu, i::UInt32)
    char = Char(i)
    push!(keyvec, (i, char))
    if char == '\e'
        cancel(menu)
        return true
    end
    if char == '\t' || char == 'ϩ'  # right arrow key
        menu.selections[menu.cursor] =  _nextselection(menu)
    elseif char == 'Ϩ' # left arrow key
        menu.selections[menu.cursor] = _prevselection(menu)
    elseif char ∈ menu.settings
        menu.selections[menu.cursor] = char
    end
    return false
end

function selected(menu::ToggleMenu)
    return menu.selections
end

end
