module ToggleMenus

using StringManipulation

export ToggleMenu, ToggleMenuMaker

import REPL.TerminalMenus: AbstractMenu, Config, _ConfiguredMenu, cancel, header, keypress,
    move_down!, move_up!, numoptions, pick, selected, writeline, request

using REPL.TerminalMenus

import REPL.Terminals: TTYTerminal

mutable struct ToggleMenuMaker
    settings::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    braces::Tuple{String,String}
    maxicon::Int
    keypress::Function
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
    ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, icons::Union{Vector{String},Vector{Char}}, pagesize=10; kwargs...)

Create a template for a ToggleMaker, which may be passed to `makemenu` along with a
set of options.

- `header`: A string, which should inform the user what the options do, or a function
            `header(m::ToggleMenu)::String`.
- `settings`: A `Vector{Char}`, every element must be unique, and should be easy to
              type.  Pressing a key corresponding to one of the settings will toggle
              that option directly to that setting.
- `icons`:  Optional `Vector{Char}` or `Vector{String}`.  If provided, these must
            also be unique, and must have the same number of elements as `settings`.
            These are used as the selection icons, which will default to `settings`
            if none are provided.
- `pagesize`:  Number of options to display before scrolling.

Keyword arguments

 - `braces`:  This may be a tuple of Strings or Chars, defaults to `("[", "]")`.
 - `keypress`:  A second function to run on keypress, only called if the standard
                inputs aren't handled.  Signature is `(menu::ToggleMenu, i::UInt32)`,
                where `i` is a somewhat funky representation of the character
                typed, as provided by [REPL.TerminalMenus](@extref Julia `Menus`).
                This should return `false` unless the menu is completed, in which
                case, return `true`.

Other keyword arguments are passed through to [`TerminalMenus.Config`](@extref), and
may be used to configure aspects of menu presentation and behavior.

The `ToggleMenuMaker` is callable to produce a ToggleMenu.
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
    if !haskey(icodict, '\0')
        icodict['\0'] = " "^maxicon
    end
    settings = [x for x in settings if x != '\0']
    kwargdict = Dict()
    braces = ("[", "]")
    onkey(m,i) = false
    for (key, val) in kwargs
        if key == :braces
            braces = (string(val[1]), string(val[2]))
        elseif key == :keypress
            onkey = val
        else
            kwargdict[key] = val
        end
    end
    ToggleMenuMaker(settings, icodict, header, braces, maxicon, onkey, pagesize, Config(; kwargdict...))
end


"""
    makemenu(maker::ToggleMenuMaker, options [, selections])::ToggleMenu

Makes a ToggleMenu.  Usually invoked by calling a [`ToggleMenuMaker`](@ref) with the arguments.
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



"""
    (maker::ToggleMenuMaker)(options::StringVector)::ToggleMenu
    (maker::ToggleMenuMaker)(options::StringVector, selections::Vector{Char})::ToggleMenu
    (maker::ToggleMenuMaker)(opts::Tuple{StringVector,Vector{Char}})::ToggleMenu

Makes a `ToggleMenu`.  The `options` are a Vector of some string type, which have
states which may be toggled through. `selections` is an optional `Vector{Char}` of
initial selected states for the options.  If a selection is `\\0`, the menu will skip
that line during navigation, and it will not be togglable.  If not provided, the menu
options will begin in the first setting.

When the menu is finished, it will return a `Vector` of `Tuples`, the first of which
is a selection, the last an option.  This precomposes the options with their
selections, which is probably what you want, as well as allowing menu functions to
modify both options and selections.  If canceled, all selections will be `\\0`.

# Use

[`ToggleMenus`](@ref) are inherently designed for use at the [`REPL`](@extref), and
the type signatures are designed for easy composition.  For example, this works:

```julia
julia> (["option 1", "option 2"], ['a', 'b']) |> maker |> request
```

Which is more useful with a function which prepares options and selections. Once that
function is stable one may use composition:

```julia
action = request ∘ maker ∘ prepare
```

Such that `action(data)` will prepare data to be presented in ToggleMenu format, pass
it to the `maker`, and call `request`.

We also add methods to `request` to make `do` notation possible for all
`AbstractMenu` types, making this sort of workflow possible:

```julia
request(menu(options, selections)) do
    # handle the returned settings here
end
```
"""
(maker::ToggleMenuMaker)(options::StringVector) = ToggleMenu(maker, options)

(maker::ToggleMenuMaker)(options::StringVector, selections::Vector{Char}) = makemenu(maker, options, selections)

(maker::ToggleMenuMaker)(opts::Tuple{StringVector,Vector{Char}}) = maker(opts[1], opts[2])


mutable struct ToggleMenu <: _ConfiguredMenu{Config}
    options::StringVector
    settings::Vector{Char}
    selections::Vector{Char}
    icons::Dict{Char,Union{String,Char}}
    header::Union{AbstractString,Function}
    braces::Tuple{String,String}
    maxicon::Int
    keypress::Function
    pagesize::Int
    pageoffset::Int
    cursor::Int
    config::Config
    aux::Any
end

function ToggleMenu(options::StringVector,
                    settings::Vector{Char},
                    selections::Vector{Char},
                    icons::Dict{Char,Union{String,Char}},
                    header::Union{AbstractString,Function},
                    braces::Tuple{String,String},
                    maxicon::Int,
                    keypress::Function,
                    config::Config,
                    pagesize=10)
    ToggleMenu(options, settings, selections, icons, header, braces, maxicon, keypress, pagesize, 0, 1, config, nothing)
end

function ToggleMenu(maker::ToggleMenuMaker, options::StringVector)
    selections = fill(maker.settings[1], length(options))
    ToggleMenu(maker, options, selections)
end

function ToggleMenu(maker::ToggleMenuMaker, options::StringVector, selections::Vector{Char})
    ToggleMenu(options, maker.settings, selections, maker.icons, maker.header, maker.braces, maker.maxicon, maker.keypress, maker.config, maker.pagesize)
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

cancel(menu::ToggleMenu) = menu.selections = fill('\0', length(menu.selections))

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
    return menu.keypress(menu, i)
end

function selected(menu::ToggleMenu)
    return collect(zip(menu.selections, menu.options))
end

"""
    request(λ::Function, args...)

A do-notation-compatible form of [`request`](@extref `REPL.TerminalMenus.request`)
"""
request(λ::Function, m::AbstractMenu; kwargs...) = λ(request(m, kwargs...))
function request(λ::Function, term::TTYTerminal, m::AbstractMenu; kwargs...)
    λ(request(term, m, kwargs...))
end
function request(λ::Function, msg::AbstractString, m::AbstractMenu; kwargs...)
    λ(request(term, msg, m, kwargs...))
end
function request(λ::Function, term::TTYTerminal, msg::AbstractString, m::AbstractMenu; kwargs...)
    λ(request(term, term, msg, m, kwargs...))
end

end # module ToggleMenus
