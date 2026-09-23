"""
    SchemaConfig(; kwargs...) -> SchemaConfig

Configure the docstring schema check and rendering.

Pass it to `makedocs(plugins = [SchemaConfig(...)])`, or to [`check_module`](@ref)
to run the check without Documenter.

# Keywords
- `order::Vector{String}`: canonical section names in the order they must appear.
- `required::Vector{String}`: sections every full docstring must have. `Arguments`
  and `Keywords` are added when the documented methods have them.
- `na_markers::Vector{String}`: a section whose whole body is one of these counts
  as an explicit opt-out.
- `exclude::Vector{Any}`: bindings or functions to skip.
- `ignore::Vector{Symbol}`: rule codes to suppress, e.g. `:DS003`.
- `strict::Bool`: fail the build on errors (`true`) or only warn (`false`).
- `theme`: rendering theme, a `Symbol`, TOML path, `ThemeSpec` or `DocstringTheme`.
- `hide_na::Bool`: drop N/A sections from the HTML output.

# Returns
A `SchemaConfig`.

# Examples
```jldoctest
julia> using DocumenterDocstringStyle

julia> SchemaConfig(strict = false).strict
false
```
"""
Base.@kwdef struct SchemaConfig <: Documenter.Plugin
    order::Vector{String} = [
        "Arguments", "Keywords", "Returns", "Throws",
        "Notes", "Examples", "See also", "References", "Extended help",
    ]
    required::Vector{String} = ["Returns", "Examples"]
    na_markers::Vector{String} = ["N/A"]
    exclude::Vector{Any} = Any[]
    ignore::Vector{Symbol} = Symbol[]
    strict::Bool = true
    theme::Any = :labeled
    hide_na::Bool = false
end
