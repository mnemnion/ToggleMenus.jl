module ToggleMenus

using StringManipulation

export ToggleMenu, ToggleMenuMaker, makemenu

import REPL.TerminalMenus: AbstractMenu, _ConfiguredMenu, Config, cancel, keypress, move_down!, move_up!,
    numoptions, pick, selected, writeline, header

using REPL.TerminalMenus

mutable struct ToggleMenuMaker
    settings::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    braces::Tuple{String,String}
    maxicon::Int
    pagesize::Int
    config::Config
end

const StringVector = Vector{S} where S <: AbstractString

function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, pagesize=10; kwargs...)
    icons = Vector{String}()
    iconwidth = reduce(max, map((x) -> printable_textwidth(string(x)), settings))
    for char in settings
        if char == '\0'
            push!(icons, " "^iconwidth)
        else
            push!(icons, string(char))
        end
    end
    ToggleMenuMaker(header, settings, icons, pagesize; kwargs...)
end


"""
    ToggleMenuMaker(header, settings, icons, pagesize=10, kwargs...)

Create a template for a ToggleMaker, which may be passed to `makemenu` along with a
set of options.

- `header`: A string, which should inform the user what the options do, or a function
            `header(m::ToggleMenu)::String`.
- `settings`: A `Vector{Char}`, every element must be unique, and should be easy to
              type.  Pressing a key corresponding to one of the settings will toggle
              that option directly to that setting.
- `icons`:  Optional `Vector{Char}` or `Vector{String}`.  If provided, these must also
            be unique, and must have the same number of elements as `settings`.
            These are used as the selection icons, which will default to `settings`
            if none are provided.
- `pagesize`:  Number of options to display before scrolling.

The keyword argument used by ToggleMenuMaker is `braces`, which may be a tuple of
Strings or Chars, this defaults to `("[", "]")`.

Other keyword arguments are passed through to TerminalMenus.Config, and may be used
to configure aspects of menu presentation and behavior.  For more details consult the
relevant docstring.
"""
function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, icons::Union{Vector{String},Vector{Char}}, pagesize=10; kwargs...)
    if length(settings) ≠ length(icons)
        throw(DimensionMismatch("settings and icons must have the same number of elements"))
    end
    !allunique(settings) && error("all settings must be unique: $settings")
    !allunique(icons) && error("all icons must be unique $icons")
    icodict = Dict{Char,Union{String,Char}}()
    for (idx, char) ∈ settings |> enumerate
        icodict[char] = icons[idx]
    end
    maxicon = reduce(max, map((x) -> printable_textwidth(string(x)), icons))
    settings = [x for x in settings if x != '\0']
    kwargdict = Dict()
    braces = ("[", "]")
    for (key, val) in kwargs
        if key == :braces
            braces = (string(val[1]), string(val[2]))
        else
            kwargdict[key] = val
        end
    end
    ToggleMenuMaker(settings, icodict, header, braces, maxicon, pagesize, Config(; kwargdict...))
end


"""
    makemenu(maker::ToggleMenuMaker, options, selections)::ToggleMenu

Makes a `ToggleMenu`.  The `options` are a Vector of some string type, which have
states which may be toggled through. `selections` is an optional Vector of initial
selected states for the options.  If a selection is `\0`, the menu will skip that
line and it will not be togglable.  If not provided, the menu options will begin in
the first setting.

The menu will return `selections` when the user quits.  If canceled, all values will
be `\0`, otherwise they will be in the selected state.
"""
makemenu(maker::ToggleMenuMaker, options::StringVector) = ToggleMenu(options, maker)

function makemenu(maker::ToggleMenuMaker, options::StringVector, selections::Vector{Char})
    all(==('\0'), selections) && error("At least one selection must not be '\\0'")
    for select in selections
        if !haskey(maker.icons, select)
            error("Invalid selection $select")
        end
    end
    if '\0' ∈ selections && !haskey(maker.icons, '\0')
        maker.icons['\0'] = " "^maker.maxicon
    end
    return ToggleMenu(maker, options, selections)
end

mutable struct ToggleMenu <: _ConfiguredMenu{Config}
    options::StringVector
    settings::Vector{Char}
    selections::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    braces::Tuple{String,String}
    maxicon::Int
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
                    braces::Tuple{String,String},
                    maxicon::Int,
                    config::Config,
                    pagesize=10)
    ToggleMenu(options, settings, selections, icons, header, braces, maxicon, pagesize, 0, 1, config)
end

function ToggleMenu(maker::ToggleMenuMaker, options::StringVector)
    selections = fill(maker.settings[1], length(options))
    ToggleMenu(options, maker.settings, selections, maker.icons, maker.header, maker.braces, maker.maxicon, maker.config, maker.pagesize)
end

function ToggleMenu(maker::ToggleMenuMaker, options::StringVector, selections::Vector{Char})
    ToggleMenu(options, maker.settings, selections, maker.icons, maker.header, maker.braces, maker.maxicon, maker.config, maker.pagesize)
end

function header(menu::ToggleMenu)
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
    if menu.selections[idx] != '\0'
        left, right = menu.braces[1], menu.braces[2]
    else
        left = " "^printable_textwidth(menu.braces[1])
        right = " "^printable_textwidth(menu.braces[2])
    end
    pad = menu.maxicon - printable_textwidth(string(icon)) + 1
    width -= printable_textwidth(string(icon) * left * right) + pad + 3
    print(buf, left, icon, right, " "^pad)
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

function keypress(menu::ToggleMenu, i::UInt32)
    char = Char(i)
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

end # module ToggleMenus
