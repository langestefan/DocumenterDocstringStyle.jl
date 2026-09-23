# Getting started

DocumenterDocstringStyle.jl is a [Documenter.jl](https://documenter.juliadocs.org/) plugin. It does two things:

- It **checks** every function docstring against a fixed Markdown [schema](@ref schema) and reports problems with file and line.
- It **renders** docstrings through a theme, so the same plain Markdown source can look like the PyTorch, NumPy, mkdocstrings or docs.rs docs. See the [Styles](styles/labeled.md) pages.

Docstrings stay ordinary Julia Markdown, so they read well in the REPL with or without the plugin.

## Installation

The package is not registered yet. Add the markers package first, then the plugin:

```julia
using Pkg
url = "https://github.com/langestefan/DocumenterDocstringStyle.jl"
Pkg.add(; url, subdir = "DocumenterDocstringStyleMarkers")
Pkg.add(; url)
```

Add both to your `docs/Project.toml` environment. If your package uses the `MINIMAL` or `NOSCHEMA` markers in its own source, it needs `DocumenterDocstringStyleMarkers` as a dependency too. That package has no dependencies of its own.

## Check and style your docs

Pass a [`SchemaConfig`](@ref) to `makedocs`:

```julia
using Documenter, DocumenterDocstringStyle, MyPkg

makedocs(;
    modules = [MyPkg],
    sitename = "MyPkg.jl",
    plugins = [SchemaConfig(strict = true, theme = :pydata)],
)
```

- With `strict = true` the build fails when a docstring breaks the schema. With `strict = false` it only warns.
- `theme` picks one of the [built-in styles](styles/labeled.md), a [custom style](@ref custom-styles), or `:plain` to check without restyling.
- Without a `SchemaConfig`, the plugin does nothing, and the output is byte-identical to a build without it.

DocumenterDocstringStyle works alongside [DocumenterCodeBlocks.jl](https://github.com/fredrikekre/DocumenterCodeBlocks.jl). Add `CodeBlocks()` to the same `plugins` vector; the order does not matter. These docs are built with both.

A failing build prints one line per problem, grouped by docstring:

```text
ERROR: DocumenterDocstringStyle: 3 problem(s)
  MyPkg.conv2d Tuple{Any, Any} (src/conv.jl:14)
    DS020 missing `# Returns` (write `N/A` in it to opt out)
    DS030 `# Arguments` misses: w
    DS031 `# Arguments` lists unknown names: weight
```

## Write a docstring

A full docstring starts with an indented signature and a one-sentence summary, followed by level-1 sections in a fixed order:

````julia
"""
    scale(x, factor; clamp = false) -> Vector{Float64}

Multiply every element of `x` by `factor`.

# Arguments
- `x::AbstractVector`: the values to scale.
- `factor::Real`: the multiplier.

# Keywords
- `clamp::Bool = false`: clamp the result to `[0, 1]`.

# Returns
The scaled values.

# Examples
```jldoctest
julia> scale([1, 2], 2)
2-element Vector{Float64}:
 2.0
 4.0
```
"""
function scale(x, factor; clamp = false) end
````

The checker compares the names under `# Arguments` and `# Keywords` with the real method signature, so renamed arguments are caught. The [Schema](@ref schema) page lists every section, rule and opt-out.

## Check docstrings in your tests

The checker also runs without Documenter:

```julia
using Test, DocumenterDocstringStyle, MyPkg

@test isempty(filter(p -> p.severity === :error, check_module(MyPkg)))
```

[`check_module`](@ref) returns a vector of [`Problem`](@ref)s. Displaying it prints the same report as the docs build.

## Preview a style

`DocumenterDocstringStyle.preview` builds a throwaway site from demo docstrings and opens it in the browser:

```julia
DocumenterDocstringStyle.preview(:numpydoc)
DocumenterDocstringStyle.preview("docs/docstyle.toml")   # iterate on a style file
DocumenterDocstringStyle.preview(:all)                   # one page per registered theme
```
