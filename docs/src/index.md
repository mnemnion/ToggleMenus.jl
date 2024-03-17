# ToggleMenus.jl

This package provides a `ToggleMenu`: a `TerminalMenu` where each option has one of
several states, which may be toggled through with the `[Tab]` key, cycled back and
forth with the left and right arrow keys, or selected directly by entering the letter
representing that state.

It exports two types: `ToggleMenu` itself, and `ToggleMenuMaker`, which is used to prepare
a template from which any number of `ToggleMenu`s may be created.

```@setup tgm1
using ToggleMenus
header = "Press [t]odo, [d]one, [b]locked, [s]omeday, or [tab] to cycle."
settings = ['t', 'd', 'b', 's']
icons = ["🔵", "🟢", "🔴","🤔"]
template = ToggleMenuMaker(header, settings, icons; charset=:unicode)
options = ["invent antigravity",
           "pay robot butler bill",
           "escape the gravity well",
           "prepare Tuvan eggplant with kumis sauce",
           "buy stock in TurboEncabulator LLC.",
           "trade Bitcoin for ammunition"]
selections = ['t', 't', 'b', 't', 't', 'b']
menu = template(options, selections)
request(menu) = menu  # it's how the sausage is made
```

## Using ToggleMenu

Like any other TerminalMenu, a ToggleMenu is launched with [`request`](@extref
`REPL.TerminalMenus.request`).

```@repl tgm1
request(menu)
```

Pressing `s`, or `[Tab]` three times:

```@example tgm1
menu.selections[1] = 's' # hide
menu # hide
```

Down arrow some, hit tab

```@example tgm1
menu.cursor[] = 4 # hide
menu.selections[4] = 'd' # hide
menu #hide
```

When you're all set, hit `[Enter]`, or quit with `q`.

So that's how a [`ToggleMenu`](@ref) works, and how users will use them. Now let's
cover how to create them, and how to work with the results.

## ToggleMenuMaker

While it's possible to create a [`ToggleMenu`](@ref) directly, by calling the
constructor, this is not the intended workflow.  Toggle menus have more setup
associated with them than the usual sort of [`TerminalMenu`](@extref `Menus`),
and it's often the case that one will want to use one sort of menu to present
many menus with different data.

`ToggleMenus` provides a [`ToggleMenuMaker`](@ref) for setting up these sorts of
templates.  This is a callable struct, which will return a menu when supplied
with the remaining fields.  Even if you just want a once-off menu, you'll want
to make a `ToggleMenuMaker` and then call it, because calling the constructor
directly bypasses several sanity checks, and requires correctly providing all
default values, which gets tricky.

Such a workflow looks like this.

```@example tgm2
using ToggleMenus

header = "a sample togglemenu, select [a], [b], [c]"
settings = ['a', 'b', 'c']
icons = ["A", "B", "C"]

template = ToggleMenuMaker(header, settings, icons; charset=:unicode)
options = ["first option", "second option", "third option"]
menu = template(options)
```

At the REPL, a menu will [`show`](@extref `man-custom-pretty-printing`) as it will
be displayed when passed to [`request`](@extref `REPL.TerminalMenus.request`), this
is useful for interactively writing code to put the menu into the desired initial
state.

Note that `charset=:unicode` is one of the [configurations](@extref
`REPL.TerminalMenus.Config`) for `TerminalMenus`. Any such keyword arguments are passed
through to `TerminalMenus`, except for `ToggleMenu`-specific ones. Custom
configurations are always passed to the `ToggleMenuMaker`, not to
the menu itself.

You may notice that all of the options are in the initial setting, this is the default
when custom selections aren't provided.  To provide a different initial selection state,
pass that in next:

```@example tgm2
selections = ['a', 'b', 'c']
menu2 = template(options, selections)
menu2.cursor[] = 2
menu2
```

This also shows that the [`ToggleMenu`](@ref) has a [`Ref`](@extref `Core.Ref`) on
the `.cursor` field, which is provided to the `TerminalMenus` code as a keyword in the
overloaded methods of [`request`](@extref `REPL.TerminalMenus.request`) defined for
toggle menus. This allows user functions to change the cursor line directly, in a way
which the menu code understands.

In the case where the header of the menu should be custom to each menu, pass that first:

```@example tgm2
otherheader = "A different header, select [a], [b], [c]"
template(otherheader, options, selections)
```

The header can also be a [user function](#User-Functions), see below.

## Settings and Icons

Settings provide the possible states for any menu option. They have to be a
`Vector{Char}`, and really should be characters which are easy to type on a
keyboard.  Settings may be toggled through with tab, or cycled with the left and
right arrow keys, but also set directly by pressing the key which sends that
character.

Icons are optional, the `ToggleMenu` will use the settings directly if they aren't
provided.

```@example tgm2
template2 = ToggleMenuMaker(header, settings)
menu3 = template2(options, selections)
```

When provided, they can be a `Vector` of `String`s or `Char`s, but not a mix. Converting a
mixed `Vector` of `Char` and `String` to a `Vector{String}` is easy: `[string(c) for
c in vec]` will do the trick.

`ToggleMenus` will handle spacing if icons are of different lengths:

```@example tgm3
using ToggleMenus  # hide
settings = ['l', 'm', 'c']
icons = ["Larry", "Moe", "Curly"]
header = "Please assign a Stooge to each line:"

stoogetemplate = ToggleMenuMaker(header, settings, icons; scroll_wrap=true)
options = [
    "Nyuk nyuk nyuk!",
    "A burden the hand is worth two in the bush.",
    "He's got five dollars!!!!",
    "Don't worry, I got what it takes to cure him.",
    "This is gettin' on my noives!",
]

selections = ['m', 'l', 'c', 'm', 'c']

menu = stoogetemplate(options, selections)
```

Doing so in a way which correctly handles terminal color:

```@example tgm3
coloricons = ["\e[32mLarry\e[m", "\e[33mMoe\e[m", "\e[36mCurly\e[m"]
colorfulstooges = ToggleMenuMaker(header, settings, coloricons)

colorfulstooges(options, selections)
```

Although note that [`textwidth`](@extref `Base.Unicode.textwidth`), which the
measurement uses, via the excellent
[StringManipulation.jl](https://docs.juliahub.com/General/StringManipulation/stable/),
is, shall we say, not infallible:

```jldoctest
julia> textwidth("🫶🏼")
4
```

For icons, this can be compensated for, if necessary, by setting `menumaker.maxicon` to
the correct value.

When a menu is provided with initial selections, the `ToggleMenuMaker` will check that
those selections are valid, and throw an error if they aren't.

### The '\0' Special Case

Sometimes it's useful to have lines in the menu which aren't associated with states.
This is necessary to have multiple lines, because the option printer will replace all
newlines with the string "\n" (aka "\\n"), and truncate text to fit the width of the
display.

!!! note
    The code which handles option truncation uses the same escape-code-aware
    version of [`textwidth`](@extref `Base.Unicode.textwidth`) as icon printing,
    meaning that for Unicode where `textwidth` gives the wrong answer, truncation may
    be incorrect.  Code which needs to handle this situation will have to perform
    truncation itself, using [`displaysize(stdout)`](@extref `Base.displaysize`) and
    such manual adjustments as prove to be necessary.

To make an option un-togglable, set the desired lines to `'\0'` in the selections
passed in to the menu.  You only need to include it in the `settings` if you want an
icon which isn't just enough spaces to pad alignment correctly.  Note that if you do
provide such an icon, it will not be wrapped in braces (`[` and `]` by default, but
this is configurable, see below), so such lines will be visually distinguishable from
selectable ones.

In the following example, the `7` passed to `ToggleMenuMaker` is the pagesize,
controlling how many menu items are displayed.  This defaults to `15`.

```@example tgm4
using ToggleMenus  # hide

options = [string(c)^15 for c in 'a':'z']
settings = ['y', 'n']
icons = ["👍", "👎"]
selections = [c ∉ ['a', 'e', 'i', 'o', 'u'] ? '\0' : rand(['y', 'n']) for c in 'a':'z']
template = ToggleMenuMaker("which vowels do you like?", settings, icons, 7, charset=:unicode)
menu = template(options, selections)
```

Press `[Down]` then `[Tab]`:

```@example tgm4
menu.cursor[] = 5  # hide
menu.selections[5] = menu.selections[5] == 'y' ? 'n' : 'y'  # hide
menu  # hide
```

Practical menus will generally have the first line togglable, but in the event that
it isn't, the default cursor position will be on the first togglable line.  It's
possible to override this by setting the cursor to point to an inert line.  This has
no practical purpose, but the construction and request logic won't correct it.  It is
harmless to have the cursor pointing at an inert line, or for all selections to be set
to `'\0'`, in that `ToggleMenus` will not throw an error, or go into an infinite loop
trying to find a valid line to rest the cursor on.

`ToggleMenus` will pick a valid line when paging up or down, but the effect of
`[Home]` and `[End]` are hard-coded in the [`REPL`](@extref `stdlib/REPL`), and if
your first or last lines aren't togglable, the cursor will still point at them. Any
further navigation will return the cursor to a usable line, however.

## Return Values

The TerminalMenus interface has two distinct types of return: these are called
[`cancel`](@extref `REPL.TerminalMenus.cancel`) and [`pick`] (@extref
`REPL.TerminalMenus.pick`).  Cancel is what you get from pressing `[q]`, and pick is
what you get from pressing `[Enter]`.  Either form of exit then calls
[`selected`](@extref `REPL.TerminalMenus.selected`), which prepares the return values.

In either circumstance, `ToogleMenus` will return a `Vector` of `Tuples`, where `[1]` is
the selection, and `[2]` is the option it corresponds to.  We do this, rather than
merely returning the selections, so that user functions can rearrange and delete
lines.  If canceled, this `Vector` will be exactly `[('\0', "")]`.  This makes it
convenient to write code which iterates over the results and does things with states
which aren't `'\0'`, since in the event of a cancel, such code will do nothing.  If
you wish to specifically detect the return condition, import [didcancelmenu](@ref
ToggleMenus.didcancelmenu) from `ToggleMenus` and call it on the result.

## User Functions

To customize the behavior of the menus, a `ToggleMenuMaker` may be configured with
either or both user functions.  The header, passed first to the menu maker, is
normally a [`String`](@extref `manual/strings`), but may also be a function.  This
function will receive the menu as its only argument, and must return a string, which
is then printed as a header.  This will be called any time a keystroke is entered,
after the keystroke, and before the menu is printed.

The other optional user function is `keypress`.  The `TerminalMenus` code handles
`[Up]` and `[Down]`, `[PgUp]` and `[PgDown]`, `[Home]` and `[End]`, `[q]`, and
`[Enter]`, while `ToggleMenus` also defines `[Tab]`, `[Left]`, `[Right]`, and any
keystroke corresponding to a setting.  If the keystroke doesn't correspond to this,
`menu.keypress(menu, i::UInt32)` is called.

This is provided to a `ToggleMenuMaker` as a keyword:

```julia
ToggleMenuMaker(settings, icons; keypress=λ)
```

A keypress function must return a [`Bool`](@extref `Core.Bool`).  A `true` value will
exit the menu, while `false` will not.  The [`UInt32`](@extref `Core.UInt32`) value
comes from a bespoke keypress parser found only in `TerminalMenus`, with somewhat
disappointing behavior.  Notably, it will turn anything starting with `'\x1b'`,
escape, into a bare escape, if it doesn't happen to read one of the predefined
keystrokes.  I had wanted to add `[Esc]` for quitting, but too many unrelated
keystrokes trigger it.  Unlike the rest of the REPL, reading a combined keystroke is
quite out of the question, although `control-$letter`, which in a terminal sends the
associated [control code](https://en.wikipedia.org/wiki/C0_and_C1_control_codes), are
passed through to the keystroke function successfully.

That complaint out of the way, turning the `UInt32` into a [`Char`](@extref
`Core.Char`) will, for ASCII at least, provide an accurate accounting of the
keystroke, with which, you may do as you please.  To empirically determine the result
of various keystrokes, you can use the following function as a keypress function for
a test `ToggleMenu`.

```julia
function reportkey(menu, i)
    menu.header = repr(string(Char(i))) * ", " * string(i)
    return false
end
```

To facilitate the use of user functions, a `ToggleMenu` has a bonus field, `.aux`, of
type [`Any`](@extref `Core.Any`), which defaults to [`nothing`](@extref
`Core.Nothing`).  If you want this to have a value, you must set it on the menu
before calling `request`.  A future release might make this a keyword option when
calling the `ToggleMenuMaker` to construct a menu, I would cheerfully accept a PR
which adds this.

### Other Configuration

The `ToggleMenuMaker` will accept all keywords defined in [`TerminaMenus`](@extref
`REPL.TerminalMenus.config`), as well as `braces=("【","】")`, to provide an example
argument.  This is a `Tuple` of `String`s, which will enclose the togglable icons on
selectable lines.  The printer also accounts for the width of these when deciding
where to truncate lines.
