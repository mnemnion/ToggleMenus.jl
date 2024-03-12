module ToggleMenus

export ToggleMenu, ToggleMenuMaker
import REPL.TerminalMenus: AbstractMenu, Config, _ConfiguredMenu, cancel, header, keypress,
    move_down!, move_up!, page_up!, page_down!, numoptions, pick, printmenu, request, scroll_wrap, selected,
    writeline
import REPL.Terminals: TTYTerminal
import StringManipulation: fit_string_in_field, printable_textwidth

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

function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, pagesize::Int=15; kwargs...)
    icons = Vector{String}()
    for char in settings
        if char ≠ '\0'
            push!(icons, string(char))
        else  # this can be wrong, but... if you have wide-char settings,
            push!(icons, " ")  # rethink your life choices.  Or provide icons. FFS.
        end
    end
    ToggleMenuMaker(header, settings, icons, pagesize; kwargs...)
end


"""
    ToggleMenuMaker(header, settings, icons, pagesize=15; kwargs...)

Create a template with the defining values of a `ToggleMenu`, which may be called
with further arguments to create one.

# Arguments

- `header`: An `AbstractString`, which should inform the user what the options do, or
            a function `header(m::ToggleMenu)::String`.
- `settings`: A `Vector{Char}`, every element must be unique, and should be easy to
              type.  Pressing a key corresponding to one of the settings will toggle
              that option directly to that setting.
- `icons`:  Optional `Vector{Char}` or `Vector{String}`.  If provided, these must
            also be unique, and must have the same number of elements as `settings`.
            These are used as the selection icons, which will default to `settings`
            if none are provided.
- `pagesize`:  Number of options to display before scrolling.

# Keyword Arguments

 - `braces`:  This may be a tuple of Strings or Chars, defaults to `("[", "]")`.
 - `keypress`:  A second function to run on keypress, only called if the standard
                inputs aren't handled.  Signature is `(menu::ToggleMenu, i::UInt32)`,
                where `i` is a somewhat funky representation of the character typed,
                as provided by [REPL.TerminalMenus](@extref `Menus`).  This
                should return `false` unless the menu is completed, in which case,
                return `true`.

Other keyword arguments are passed through to [`TerminalMenus.Config`](@extref
`REPL.TerminalMenus.config`), and may be used to configure aspects of menu presentation
and behavior.

The `ToggleMenuMaker` is callable to produce a [`ToggleMenu`](@ref).
"""
function ToggleMenuMaker(header::Union{AbstractString,Function}, settings::Vector{Char}, icons::Union{Vector{String},Vector{Char}}, pagesize=15; kwargs...)
    if length(settings) ≠ length(icons)
        throw(DimensionMismatch("settings and icons must have the same number of elements"))
    end
    !allunique(settings) && throw(ArgumentError("all settings must be unique: $settings"))
    !allunique(icons) && throw(ArgumentError("all icons must be unique $icons"))
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

function ToggleMenuMaker(m::ToggleMenuMaker)
    ToggleMenuMaker(m.settings, m.icons, m.header, m.braces,
                    m.maxicon, m.keypress, m.pagesize, m.config)
end


"""
    makemenu(maker::ToggleMenuMaker, options [, selections])::ToggleMenu

Makes a `ToggleMenu`.

This is not exported, and is subject to change without notice, you should invoke it by
calling [`ToggleMenuMaker`](@ref).
"""
makemenu(maker::ToggleMenuMaker, options::StringVector) = ToggleMenu(options, maker)

function makemenu(maker::ToggleMenuMaker, options::StringVector, selections::Vector{Char})
    all(==('\0'), selections) && error("At least one selection must not be '\\0'")
    for select in selections
        if !haskey(maker.icons, select)
            throw(ArgumentError("Invalid selection $select at [$(find(select, selections))]"))
        end
    end
    if '\0' ∈ selections && !haskey(maker.icons, '\0')
        maker.icons['\0'] = " "^maker.maxicon
    end
    cursor = findfirst(c -> c != '\0', selections)
    return ToggleMenu(maker, options, selections, cursor)
end



"""
    (maker::ToggleMenuMaker)(options[, selections])::ToggleMenu
    (maker::ToggleMenuMaker)(opts::Tuple{StringVector,Vector{Char}})::ToggleMenu
    (maker::ToggleMenuMaker)(header::AbstractString, options...)::ToggleMenu

Make a `ToggleMenu`.

The `options` are a Vector of some String type, which have states which may be
toggled through. `selections` is an optional `Vector{Char}` of initial selected
states for the options.  If a selection is `\\0`, the menu will skip that line during
navigation, and it will not be togglable.  If not provided, the menu options will
begin in the first setting.

If you want a header specific to one menu, provide it as the first argument, this
will override the header in the `maker` (which can be "" if desired).

When the menu is finished, it will return a `Vector` of `Tuples`, the first of which
is a selection, the last an option.  This precomposes the options with their
selections, which is probably what you want, as well as allowing menu functions to
modify both options and selections.  If canceled, all selections will be `\\0`.

# Use

[`ToggleMenu`](@ref)s are inherently designed for use at the [`REPL`](@extref
`stdlib/REPL`), and the type signatures are designed for easy composition.  For
example, this works:

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

`ToggleMenus` also adds methods to `request` to make `do` notation possible for
`ToggleMenus`, making this sort of workflow possible:

```julia
request(menu(options, selections)) do selected
    # handle the returned settings here
end
```
"""
(maker::ToggleMenuMaker)(options::StringVector) = ToggleMenu(maker, options)

(maker::ToggleMenuMaker)(options::StringVector, selections::Vector{Char}) = makemenu(maker, options, selections)

(maker::ToggleMenuMaker)(opts::Tuple) = maker(opts...)

function (maker::ToggleMenuMaker)(header::AbstractString, options...)
    _make = ToggleMenuMaker(maker)
    _make.header = header
    makemenu(_make, options...)
end

"""
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
        cursor::Ref{Int}
        config::Config
        aux::Any
    end
"""
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
    cursor::Ref{Int}
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
                    cursor::Int=1,
                    pagesize=15)
    ToggleMenu(options, settings, selections, icons,
               header, braces, maxicon, keypress, pagesize,
               0, Ref(cursor), config, nothing)
end

function ToggleMenu(maker::ToggleMenuMaker, options::StringVector)
    selections = fill(maker.settings[1], length(options))
    cursor = findfirst(c -> c != '\0', selections)
    ToggleMenu(maker, options, selections, cursor)
end

function ToggleMenu(maker::ToggleMenuMaker,
                    options::StringVector,
                    selections::Vector{Char},
                    cursor=Int)
    ToggleMenu(options, maker.settings, selections, maker.icons,
               maker.header, maker.braces, maker.maxicon, maker.keypress,
               maker.config, cursor, maker.pagesize)
end

function header(menu::ToggleMenu)
    if menu.header isa Function
        menu.header(menu)
    else
        menu.header
    end
end

function move_up!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    if cursor > 1
        cursor -= 1 # move selection up
        while m.selections[cursor] == '\0' && cursor > 1
            cursor -= 1
        end
        while cursor < (2+m.pageoffset) && m.pageoffset > 0
            m.pageoffset -= 1 # scroll page up
        end
    elseif scroll_wrap(m)
        # wrap to bottom
        cursor = lastoption
        m.pageoffset = max(0, lastoption - m.pagesize)
        while m.selections[cursor] == '\0' && cursor > 1
            cursor -= 1
        end
    end
    # Final attempt to get away from '\0'
    if m.selections[cursor] == '\0'
        a_valid_cursor = findfirst(c -> c != '\0', m.selections)
        if a_valid_cursor !== nothing
            cursor = a_valid_cursor
        end  # otherwise we may as well stay put
    end
    return cursor
end

function move_down!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    lastselectable = findlast(c -> c != '\0', m.selections)
    lastselectable = lastselectable === nothing ? lastoption : lastselectable
    if cursor < lastselectable
        cursor += 1 # move selection down
        while m.selections[cursor] == '\0' && cursor < lastselectable
            cursor += 1
        end
        while m.pagesize + m.pageoffset <= cursor &&
              m.pagesize + m.pageoffset < lastoption
            m.pageoffset += 1 # scroll page down
        end
    elseif scroll_wrap(m)
        # wrap to top
        cursor = 1
        m.pageoffset = 0
        while m.selections[cursor] == '\0' && cursor < lastselectable
            cursor += 1
        end
        pagepos = m.pagesize + m.pageoffset
        if pagepos <= cursor && pagepos < lastoption
            m.pageoffset += 1 # scroll page down
        end
    end
    # Final attempt to get away from '\0'
    if m.selections[cursor] == '\0'
        a_valid_cursor = findlast(c -> c != '\0', m.selections)
        if a_valid_cursor !== nothing
            cursor = a_valid_cursor
        end  # otherwise we may as well stay put
    end
    return cursor
end

function page_up!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    # If we're at the bottom, move the page 1 less to move the cursor up from
    # the bottom entry, since we try to avoid putting the cursor at bounds.
    m.header = "page up!"
    m.pageoffset -= m.pagesize - (cursor == lastoption ? 1 : 0)
    m.pageoffset = max(m.pageoffset, 0)
    newcursor = max(cursor - m.pagesize, 1)
    if m.selections[newcursor] == '\0'
        return move_up!(m, newcursor, lastoption)
    else
        return newcursor
    end
end

function page_down!(m::ToggleMenu, cursor::Int, lastoption::Int=numoptions(m))
    m.header = "page down!"
    m.pageoffset += m.pagesize - (cursor == 1 ? 1 : 0)
    m.pageoffset = max(0, min(m.pageoffset, lastoption - m.pagesize))
    newcursor =  min(cursor + m.pagesize, lastoption)
    if m.selections[newcursor] == '\0'
        return move_down!(m, newcursor, lastoption)
    else
        return newcursor
    end
end

pick(::ToggleMenu, ::Int)::Bool = true

cancel(menu::ToggleMenu) = menu.selections = fill('\0', length(menu.selections))

numoptions(menu::ToggleMenu) = length(menu.options)

function writeline(buf::IOBuffer, menu::ToggleMenu, idx::Int, ::Bool)
    width = displaysize(stdout)[2]
    icon = get(menu.icons, menu.selections[idx], missing)
    icon = icon !== missing ? icon : menu.icons['\0']
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
    current = menu.selections[menu.cursor[]]
    idx = findfirst(==(current), menu.settings)
    idx === missing && return current
    if idx == length(menu.settings)
        return menu.settings[1]
    else
        return menu.settings[idx + 1]
    end
end

function _prevselection(menu::ToggleMenu)
    current = menu.selections[menu.cursor[]]
    idx = findfirst(==(current), menu.settings)
    idx === missing && return current
    if idx == 1
        return menu.settings[end]
    else
        return menu.settings[idx - 1]
    end
end

function keypress(menu::ToggleMenu, i::UInt32)
    char = Char(i)
    if char == '\t' || char == 'ϩ'  # right arrow key
        menu.selections[menu.cursor[]] =  _nextselection(menu)
    elseif char == 'Ϩ' # left arrow key
        menu.selections[menu.cursor[]] = _prevselection(menu)
    elseif char ∈ menu.settings
        menu.selections[menu.cursor[]] = char
    end
    return menu.keypress(menu, i)
end


function selected(menu::ToggleMenu)
    return collect(zip(menu.selections, menu.options))
end

"""
    request(m::ToggleMenu; kwargs..., cursor=m.cursor)

All [`REPL.AbstractMenu`](@extref Menus) methods for [`request`](@extref
`REPL.TerminalMenus.request`) are overloaded for `ToggleMenu`, to provide `m.cursor`
as a keyword argument.  This value is used internally in a way which presumes that
the Ref will be the same one seen by the runtime, as such, it is passed after
`kwargs...`, meaning that overloading it will have no effect.
"""
function request(m::ToggleMenu; kwargs...)
    invoke(request, Tuple{AbstractMenu}, m; kwargs..., cursor=m.cursor)
end

function request(tty::TTYTerminal, m::ToggleMenu; kwargs...)
    invoke(request, Tuple{TTYTerminal,AbstractMenu}, tty, m; kwargs..., cursor=m.cursor)
end

function request(msg::AbstractString, m::ToggleMenu; kwargs...)
    invoke(request, Tupe{AbstractString,AbstractMenu}, msg, m; kwargs..., cursor=m.cursor)
end

function request(tty::TTYTerminal, msg::AbstractString, m::ToggleMenu; kwargs...)
    invoke(request, Tuple{TTYTerminal,AbstractString,AbstractMenu}, tty, msg, m; kwargs..., cursor=m.cursor)
end

"""
    request(λ::Function, args...)

A do-notation-compatible form of [`request`](@extref `REPL.TerminalMenus.request`).
"""
request(λ::Function, m::ToggleMenu; kwargs...) = λ(request(m, kwargs...))
function request(λ::Function, term::TTYTerminal, m::ToggleMenu; kwargs...)
    λ(request(term, m, kwargs...))
end
function request(λ::Function, msg::AbstractString, m::ToggleMenu; kwargs...)
    λ(request(term, msg, m, kwargs...))
end
function request(λ::Function, term::TTYTerminal, msg::AbstractString, m::ToggleMenu; kwargs...)
    λ(request(term, term, msg, m, kwargs...))
end

function Base.show(io::IO, ::MIME"text/plain", m::ToggleMenu)
    buf = IOBuffer()
    printmenu(buf, m, m.cursor[])
    str = String(take!(buf))
    str = replace(str, r"\r\e\[\d+A\e\[2K" => "")
    print(io, str)
end

end # module ToggleMenus
