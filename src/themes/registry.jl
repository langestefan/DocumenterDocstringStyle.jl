const ASSET_DIR = normpath(joinpath(@__DIR__, "..", "..", "assets", "themes"))
const BASE_CSS = joinpath(ASSET_DIR, "base.css")

# Unresolved specs by name. Built-ins are added in builtins.jl.
const THEMES = Dict{Symbol, ThemeSpec}()
const BUILTIN_THEMES = Symbol[]

"""
    register_theme!(name::Symbol, spec::ThemeSpec) -> ThemeSpec

Register `spec` so that `SchemaConfig(theme = name)` and `extends = name` find it.

Call it from a style package's `__init__`. Names of built-in themes cannot be
reused.

# Arguments
- `name::Symbol`: the name to register under.
- `spec::ThemeSpec`: the theme.

# Returns
The registered `spec`.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> register_theme!(:acme, ThemeSpec(name = :acme, extends = :labeled)).name
:acme
```
"""
function register_theme!(name::Symbol, spec::ThemeSpec)
    name in BUILTIN_THEMES && error("cannot register theme `:$name`: a built-in theme has that name")
    THEMES[name] = validate(spec)
    return spec
end

function lookup_theme(name::Symbol)
    haskey(THEMES, name) ||
        error("unknown theme `:$name`, registered themes: $(join(map(repr, sort!(collect(keys(THEMES)))), ", "))")
    return THEMES[name]
end

builtin_theme(name::Symbol) = resolve(THEMES[name])

"""
    resolve_theme(theme) -> DocstringTheme

Turn the `theme` setting of a [`SchemaConfig`](@ref) into a ready theme: a
registered name, a [`ThemeSpec`](@ref) or any other `DocstringTheme`.

$(MINIMAL)
"""
resolve_theme(theme::Symbol) = resolve(lookup_theme(theme))
resolve_theme(theme::ThemeSpec) = resolve(theme)
resolve_theme(theme::DocstringTheme) = theme
resolve_theme(theme) = error("unsupported theme `$(repr(theme))`: use a Symbol, a ThemeSpec or a DocstringTheme")
