using ToggleMenus
using Test
using Aqua

@testset "ToggleMenus.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(ToggleMenus)
    end
    # Write your tests here.
end
