using ToggleMenus
using REPL
using Test
using Aqua

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
    end
end
