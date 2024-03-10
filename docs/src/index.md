# ToggleMenus.jl

This package provides a `ToggleMenu`: a `TerminalMenu` where each option has one of
several states, which may be toggled through with the Tab key, or selected directly by
entering the letter representing that state.

It exports two types: `ToggleMenu` itself, and `ToggleMenuMaker`, which is used to prepare
a template from which any number of `ToggleMenu`s may be created.


```@autodocs
Modules = [ToggleMenus]
```