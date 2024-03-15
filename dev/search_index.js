var documenterSearchIndex = {"docs":
[{"location":"#ToggleMenus.jl","page":"ToggleMenus","title":"ToggleMenus.jl","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"This package provides a ToggleMenu: a TerminalMenu where each option has one of several states, which may be toggled through with the [Tab] key, cycled back and forth with the left and right arrow keys, or selected directly by entering the letter representing that state.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"It exports two types: ToggleMenu itself, and ToggleMenuMaker, which is used to prepare a template from which any number of ToggleMenus may be created.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"using ToggleMenus\nheader = \"Press [t]odo, [d]one, [b]locked, [s]omeday, or [tab] to cycle.\"\nsettings = ['t', 'd', 'b', 's']\nicons = [\"🔵\", \"🟢\", \"🔴\",\"🤔\"]\ntemplate = ToggleMenuMaker(header, settings, icons; charset=:unicode)\noptions = [\"invent antigravity\",\n           \"pay robot butler bill\",\n           \"escape the gravity well\",\n           \"prepare Tuvan eggplant with kumis sauce\",\n           \"buy stock in TurboEncabulator LLC.\",\n           \"trade Bitcoin for ammunition\"]\nselections = ['t', 't', 'b', 't', 't', 'b']\nmenu = template(options, selections)\nrequest(menu) = menu  # it's how the sausage is made","category":"page"},{"location":"#Using-ToggleMenu","page":"ToggleMenus","title":"Using ToggleMenu","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Like any other TerminalMenu, a ToggleMenu is launched with request.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"request(menu)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Pressing s, or [Tab] three times:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"menu.selections[1] = 's' # hide\nmenu # hide","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Down arrow some, hit tab","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"menu.cursor[] = 4 # hide\nmenu.selections[4] = 'd' # hide\nmenu #hide","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"When you're all set, hit [Enter], or quit with q.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"So that's how a ToggleMenu works, and how users will use them. Now let's cover how to create them, and how to work with the results.","category":"page"},{"location":"#ToggleMenuMaker","page":"ToggleMenus","title":"ToggleMenuMaker","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"While it's possible to create a ToggleMenu directly, by calling the constructor, this is not the intended workflow.  Toggle menus have more setup associated with them then the usual sort of TerminalMenu, and it's often the case that one will want to use one sort of menu to present many menus with different data.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"ToggleMenus provides a ToggleMenuMaker for setting up these sorts of templates.  This is a callable struct, which will return a menu when supplied with the remaining fields.  Even if you just want a once-off menu, you'll want to make a ToggleMenuMaker and then call it, because calling the constructor directly bypasses several sanity checks, and requires correctly providing all default values, which gets tricky.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Such a workflow looks like this.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"using ToggleMenus\n\nheader = \"a sample togglemenu, select [a], [b], [c]\"\nsettings = ['a', 'b', 'c']\nicons = [\"A\", \"B\", \"C\"]\n\ntemplate = ToggleMenuMaker(header, settings, icons; charset=:unicode)\noptions = [\"first option\", \"second option\", \"third option\"]\nmenu = template(options)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"At the REPL, a menu will show as it will be displayed when passed to request, this is useful for interactively writing code to put the menu into the desired initial state.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Note that charset=:unicode is one of the configurations for TerminalMenus. Any such keyword arguments are passed through to TerminalMenus, except for ToggleMenu-specific ones, and cursor, which we override. Custom configurations are always passed to the ToggleMenuMaker, not to the menu itself.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"You may notice that all of the options are in the initial setting, this is the default when custom selections aren't provided.  To provide a different initial selection state, pass that in next:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"selections = ['a', 'b', 'c']\nmenu2 = template(options, selections)\nmenu2.cursor[] = 2\nmenu2","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"This also shows that the ToggleMenu has a Ref on the .cursor field, which is provided to the TerminalMenus code as a keyword in the overloaded methods of request defined for toggle menus. This allows user functions to change the cursor line directly, in a way which the menu code understands.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"In the case where the header of the menu should be custom to each menu, pass that first:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"otherheader = \"A different header, select [a], [b], [c]\"\ntemplate(otherheader, options, selections)","category":"page"},{"location":"#Settings-and-Icons","page":"ToggleMenus","title":"Settings and Icons","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Settings provide the possible states for any menu option. They have to be a Vector{Char}, and really should be characters which are easy to type on a keyboard.  Settings may be toggled through with tab, or cycled with the left and right arrow keys, but also set directly by pressing the key which sends that character.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Icons are optional, the ToggleMenu will use the settings directly if they aren't provided.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"template2 = ToggleMenuMaker(header, settings)\nmenu3 = template2(options, selections)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"When provided, they can be a Vector of Strings or Chars, but not a mix. Converting a mixed Vector of Char and String to a Vector{String} is easy: [string(c) for c in vec] will do the trick.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"ToggleMenus will handle spacing if icons are of different lengths:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"using ToggleMenus  # hide\nsettings = ['l', 'm', 'c']\nicons = [\"Larry\", \"Moe\", \"Curly\"]\nheader = \"Please assign a Stooge to each line:\"\n\nstoogetemplate = ToggleMenuMaker(header, settings, icons; scroll_wrap=true)\noptions = [\n    \"Nyuk nyuk nyuk!\",\n    \"A burden the hand is worth two in the bush.\",\n    \"He's got five dollars!!!!\",\n    \"Don't worry, I got what it takes to cure him.\",\n    \"This is gettin' on my noives!\",\n]\n\nselections = ['m', 'l', 'c', 'm', 'c']\n\nmenu = stoogetemplate(options, selections)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Doing so in a way which correctly handles terminal color:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"coloricons = [\"\\e[32mLarry\\e[m\", \"\\e[33mMoe\\e[m\", \"\\e[36mCurly\\e[m\"]\ncolorfulstooges = ToggleMenuMaker(header, settings, coloricons)\n\ncolorfulstooges(options, selections)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Although note that textwidth, which the measurement uses, via the excellent StringManipulation.jl, is, shall we say, not infallible:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"julia> textwidth(\"🫶🏼\")\n4","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"For icons, this can be compensated for, if necessary, by setting menumaker.maxicon to the correct value.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"When a menu is provided with initial selections, the ToggleMenuMaker will check that those selections are valid, and throw an error if they aren't.","category":"page"},{"location":"#The-'\\0'-Special-Case","page":"ToggleMenus","title":"The '\\0' Special Case","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Sometimes it's useful to have lines in the menu which aren't associated with states. This is necessary to have multiple lines, because the option printer will replace all newlines with the string \"\\n\" (aka \"\\n\"), and truncate text to fit the width of the display.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"note: Note\nThe code which handles option truncation uses the same escape-code-aware version of textwidth as icon printing, meaning that for Unicode where textwidth gives the wrong answer, truncation may be incorrect.  Code which needs to handle this situation will have to perform truncation itself, using displaysize(stdout) and such manual adjustments as prove to be necessary.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"To make an option un-togglable, set the desired lines to '\\0' in the selections passed in to the menu.  You only need to include it in the settings if you want an icon which isn't just enough spaces to pad alignment correctly.  Note that if you do provide such an icon, it will not be wrapped in braces ([ and ] by default, but this is configurable, see below).","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"In the following example, the 7 passed to ToggleMenuMaker is the pagesize, controlling how many menu items are displayed.  This defaults to 15.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"using ToggleMenus  # hide\n\noptions = [string(c)^15 for c in 'a':'z']\nsettings = ['y', 'n']\nicons = [\"👍\", \"👎\"]\nselections = [c ∉ ['a', 'e', 'i', 'o', 'u'] ? '\\0' : rand(['y', 'n']) for c in 'a':'z']\ntemplate = ToggleMenuMaker(\"which vowels do you like?\", settings, icons, 7, charset=:unicode)\nmenu = template(options, selections)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Press [Down] then [Tab]:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"menu.cursor[] = 5  # hide\nmenu.selections[5] = menu.selections[5] == 'y' ? 'n' : 'y'  # hide\nmenu  # hide","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"Practical menus will generally have the first line togglable, but in the event that it isn't, the default cursor position will be on the first togglable line.  It's possible to override this by setting the cursor to point to an inert line.  This has no practical purpose, but the construction and request logic won't correct it.  It is harmless to have the cursor pointing at an inert line, or for all selections to be set to '\\0', in that ToggleMenus will not throw an error, or go into an infinite loop trying to find a valid line to rest the cursor on.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"ToggleMenus will pick a valid line when paging up or down, but the effect of [Home] and [End] are hard-coded in the REPL, and if your first or last lines aren't togglable, the cursor will still point at them. Any further navigation will return the cursor to a usable line, however.","category":"page"},{"location":"#Return-Values","page":"ToggleMenus","title":"Return Values","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"The TerminalMenus interface has two distinct types of return: these are called cancel and pick.  Cancel is what you get from pressing [q], and pick is what you get from pressing [Enter].  Either form of exit then calls selected, which prepares the return values.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"In either circumstance, ToogleMenus will return a Vector of Tuples, where [1] is the selection, and [2] is the option it corresponds to.  We do this, rather than merely returning the selections, so that user functions can rearrange and delete lines.  If canceled, all the the selections will be '\\0', note that this will happen whether or not '\\0' was used to indicate blank lines.  A menu with everything selected to '\\0' isn't navigable, though ToggleMenus can handle this condition without throwing errors, but the ToggleMenuMaker will refuse to make a menu in this state.  So barring deliberate action from user functions, a cancel result will always be distinguishable from a pick result, by all selections being the Char '\\0'.","category":"page"},{"location":"#User-Functions","page":"ToggleMenus","title":"User Functions","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"To customize the behavior of the menus, a ToggleMenuMaker may be configured with either or both user functions.  The header, passed first to the menu maker, is normally a String, but may also be a function.  This function will receive the menu as its only argument, and must return a string, which is then printed as a header.  This will be called any time a keystroke is entered. A header function executes before the menu is printed, so any change made by a keystroke will be visible when a header function is called.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"The other optional user function is keypress.  The TerminalMenus code handles [Up] and [Down], [PgUp] and [PgDown], [Home] and [End], [q], and [Enter], while ToggleMenus also defines [Tab], [Left], [Right], and any keystroke corresponding to a setting.  If the keystroke doesn't correspond to this, menu.keypress(menu, i::UInt32) is called.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"This is provided to a ToggleMenuMaker as a keyword:","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"ToggleMenuMaker(settings, icons; keypress=λ)","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"A keypress function must return a Bool.  A true value will exit the menu, while false will not.  The UInt32 value comes from a bespoke keypress parser found only in TerminalMenus, with somewhat disappointing behavior.  Notably, it will turn anything starting with '\\x1b', escape, into a bare escape, if it doesn't happen to read one of the predefined keystrokes.  I had wanted to add [Esc] for quitting, but too many unrelated keystrokes trigger it.  Unlike the rest of the REPL, reading a combined keystroke is quite out of the question, although control-$letter, which in a terminal sends the associated control code, are passed through to the keystroke function successfully.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"That complaint out of the way, turning the UInt32 into a Char will, for ASCII at least, provide an accurate accounting of the keystroke, with which, you may do as you please.  To empirically determine the result of various keystrokes, you can use the following function as a keypress function for a test ToggleMenu.","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"function reportkey(menu, i)\n    menu.header = repr(string(Char(i))) * \", \" * string(i)\n    return false\nend","category":"page"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"To facilitate the use of user functions, a ToggleMenu has a bonus field, .aux, of type Any, which defaults to nothing.  If you want this to have a value, you must set it on the menu before calling request.  A future release might make this a keyword option when calling the ToggleMenuMaker to construct a menu, I would cheerfully accept a PR which adds this.","category":"page"},{"location":"#Other-Configuration","page":"ToggleMenus","title":"Other Configuration","text":"","category":"section"},{"location":"","page":"ToggleMenus","title":"ToggleMenus","text":"The ToggleMenuMaker will accept all keywords defined in TerminaMenus, as well as braces=(\"【\",\"】\"), to provide an example argument.  This is a Tuple of Strings, which will enclose the togglable icons on selectable lines.  The printer also accounts for the width of these when deciding where to truncate lines.","category":"page"},{"location":"docstrings/#Docstrings","page":"Docstrings","title":"Docstrings","text":"","category":"section"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"ToggleMenus is not yet stable.  By its nature, effective use involves the internals of the package, so the public interface is not easy to separate from the specifics of the structs documented below. Aspects of the package demonstrated in the documentation proper won't change without some good reason.","category":"page"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Any changes to those specifics will involve a minor release (or a major bump to 1.0), and will be clearly documented in a NEWS.md file added to the base of the repository.","category":"page"},{"location":"docstrings/","page":"Docstrings","title":"Docstrings","text":"Modules = [ToggleMenus]","category":"page"},{"location":"docstrings/#ToggleMenus.ToggleMenus","page":"Docstrings","title":"ToggleMenus.ToggleMenus","text":"ToggleMenus\n\nThe ToggleMenus module provides a TerminalMenu where options may be toggled through several states.  A template is constructed with a ToggleMenuMaker, which is used to construct a ToggleMenu.  The result is passed to TerminalMenus.request for display in the REPL.\n\n\n\n\n\n","category":"module"},{"location":"docstrings/#ToggleMenus.ToggleMenu","page":"Docstrings","title":"ToggleMenus.ToggleMenu","text":"mutable struct ToggleMenu <: _ConfiguredMenu{Config}\n    options::StringVector\n    settings::Vector{Char}\n    selections::Vector{Char}\n    icons::Dict{Char,Union{String,Char}}\n    header::Union{AbstractString,Function}\n    braces::Tuple{String,String}\n    maxicon::Int\n    keypress::Function\n    pagesize::Int\n    pageoffset::Int\n    cursor::Ref{Int}\n    config::Config\n    aux::Any\nend\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ToggleMenus.ToggleMenuMaker","page":"Docstrings","title":"ToggleMenus.ToggleMenuMaker","text":"ToggleMenuMaker(header, settings, icons, pagesize=15; kwargs...)\n\nCreate a template with the defining values of a ToggleMenu, which may be called with further arguments to create one.\n\nArguments\n\nheader: An AbstractString, which should inform the user what the options do, or           a function header(m::ToggleMenu)::String.\nsettings: A Vector{Char}, every element must be unique, and should be easy to             type.  Pressing a key corresponding to one of the settings will toggle             that option directly to that setting.\nicons:  Optional Vector{Char} or Vector{String}.  If provided, these must           also be unique, and must have the same number of elements as settings.           These are used as the selection icons, which will default to settings           if none are provided.\npagesize:  Number of options to display before scrolling.\n\nKeyword Arguments\n\nbraces:  This may be a tuple of Strings or Chars, defaults to (\"[\", \"]\").\nkeypress:  A second function to run on keypress, only called if the standard              inputs aren't handled.  Signature is (menu::ToggleMenu, i::UInt32),              where i is a somewhat funky representation of the character typed,              as provided by REPL.TerminalMenus.  This              should return false unless the menu is completed, in which case,              return true.\n\nOther keyword arguments are passed through to TerminalMenus.Config, and may be used to configure aspects of menu presentation and behavior.\n\nThe ToggleMenuMaker is callable to produce a ToggleMenu.\n\n\n\n\n\n","category":"type"},{"location":"docstrings/#ToggleMenus.ToggleMenuMaker-Tuple{Vector{S} where S<:AbstractString}","page":"Docstrings","title":"ToggleMenus.ToggleMenuMaker","text":"(maker::ToggleMenuMaker)(options[, selections])::ToggleMenu\n(maker::ToggleMenuMaker)(opts::Tuple{StringVector,Vector{Char}})::ToggleMenu\n(maker::ToggleMenuMaker)(header::AbstractString, options...)::ToggleMenu\n\nMake a ToggleMenu.\n\nThe options are a Vector of some String type, which have states which may be toggled through. selections is an optional Vector{Char} of initial selected states for the options.  If a selection is \\0, the menu will skip that line during navigation, and it will not be togglable.  If not provided, the menu options will begin in the first setting.\n\nIf you want a header specific to one menu, provide it as the first argument, this will override the header in the maker (which can be \"\" if desired).\n\nWhen the menu is finished, it will return a Vector of Tuples, the first of which is a selection, the last an option.  This precomposes the options with their selections, which is probably what you want, as well as allowing menu functions to modify both options and selections.  If canceled, all selections will be \\0.\n\nUse\n\nToggleMenus are inherently designed for use at the REPL, and the type signatures are designed for easy composition.  For example, this works:\n\njulia> ([\"option 1\", \"option 2\"], ['a', 'b']) |> maker |> request\n\nWhich is more useful with a function which prepares options and selections. Once that function is stable one may use composition:\n\naction = request ∘ maker ∘ prepare\n\nSuch that action(data) will prepare data to be presented in ToggleMenu format, pass it to the maker, and call request.\n\nToggleMenus also adds methods to request to make do notation possible for ToggleMenus, making this sort of workflow possible:\n\nrequest(menu(options, selections)) do selected\n    # handle the returned settings here\nend\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#REPL.TerminalMenus.request-Tuple{Function, ToggleMenu}","page":"Docstrings","title":"REPL.TerminalMenus.request","text":"request(λ::Function, args...)\n\nA do-notation-compatible form of request.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#REPL.TerminalMenus.request-Tuple{ToggleMenu}","page":"Docstrings","title":"REPL.TerminalMenus.request","text":"request(m::ToggleMenu; kwargs..., cursor=m.cursor)\n\nAll REPL.AbstractMenu methods for request are overloaded for ToggleMenu, to provide m.cursor as a keyword argument.  This value is used internally in a way which presumes that the Ref will be the same one seen by the runtime, as such, it is passed after kwargs..., meaning that overloading it will have no effect.\n\n\n\n\n\n","category":"method"},{"location":"docstrings/#ToggleMenus.makemenu-Tuple{ToggleMenuMaker, Vector{S} where S<:AbstractString}","page":"Docstrings","title":"ToggleMenus.makemenu","text":"makemenu(maker::ToggleMenuMaker, options [, selections])::ToggleMenu\n\nMakes a ToggleMenu.\n\nThis is not exported, and is subject to change without notice, you should invoke it by calling ToggleMenuMaker.\n\n\n\n\n\n","category":"method"}]
}