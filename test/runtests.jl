using ToggleMenus
using REPL
using Test
using Aqua
import ToggleMenus: cancel, header, keypress, move_down!, move_up!, numoptions, page_down!,
page_up!, pick, printmenu, scroll_wrap, selected, writeline, didcancelmenu

@testset "ToggleMenus.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        # Aqua.test_all(ToggleMenus)
    end
    @testset "ToggleMenuMaker errors" begin
        settings = ['a', 'b', 'c']
        icons = ['A', 'B', 'C', 'D']
        settings2 = ['a', 'b', 'c', 'c']
        icons2 = ["A", "A", "A"]
        @test_throws DimensionMismatch  ToggleMenuMaker("", settings, icons)
        @test_throws ArgumentError ToggleMenuMaker("", settings2, icons)
        @test_throws ArgumentError ToggleMenuMaker("", settings, icons2)
    end
    @testset "Simple menu tests" begin
        a_header = "test menu 1"
        settings = ['a', 'b', 'c']
        simpletemplate = ToggleMenuMaker(a_header, settings)
        @test simpletemplate isa ToggleMenuMaker
        @test simpletemplate.settings == ['a', 'b', 'c']
        @test simpletemplate.config isa REPL.TerminalMenus.Config
        menu1 = simpletemplate(["one", "two", "three"])
        @test menu1 isa ToggleMenu
        @test menu1.selections == ['a', 'a', 'a']
        @test menu1.cursor[] == 1
        @test simpletemplate.header ==  "test menu 1"
        template = ToggleMenuMaker("header", ['a', 'b', 'c'], ['🔴', '🔵', '🟢'], charset=:unicode)
        menu = template("different header", [string(c) for c in 'a':'g'])
        @test template.header == "header"
        @test menu.header == "different header"
        @test menu.cursor[] == 1
        @test menu.cursor isa Base.RefValue{Int64}
        @test (menu.cursor[] = move_down!(menu, menu.cursor[])) == 2
        @test (menu.cursor[] = move_up!(menu, menu.cursor[])) == 1
        @test (menu.cursor[] = page_down!(menu, menu.cursor[])) == 7
        @test (menu.cursor[] = page_up!(menu, menu.cursor[])) == 1
        keypress(menu, UInt32('\t'))
        @test menu.selections[1] == 'b'
        keypress(menu, UInt32('\t'))
        @test menu.selections[1] == 'c'
        keypress(menu, UInt32('\t'))
        @test menu.selections[1] == 'a'
        keypress(menu, UInt32('c'))
        @test menu.selections[1] == 'c'
        @test scroll_wrap(menu) == false
        @test header(menu) == "different header"
        @test numoptions(menu) == length(menu.options) == length(menu.selections)
        normal_return = selected(menu)
        for (idx, (selected, option)) in normal_return |> enumerate
            @test selected == menu.selections[idx]
            @test option == menu.options[idx]
        end
        @test didcancelmenu(normal_return) == false
        cancel(menu)
        cancel_return = selected(menu)
        @test length(cancel_return) == 1
        @test cancel_return[1][1] == '\0'
        @test cancel_return[1][2] == ""
        @test didcancelmenu(cancel_return) == true
    end
end
